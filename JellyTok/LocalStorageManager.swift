//
//  LocalStorageManager.swift
//  JellyTok
//
//  Created by Faique Ali on 30/05/2025.
//

import AVFoundation
import Foundation
import UIKit


class LocalStorageManager {
    static let shared = LocalStorageManager()
    private init() {}

    private let fileManager = FileManager.default

    /// Directory where saved videos will go
    private var videosDirectory: URL {
        let documents = fileManager.urls(
            for: .documentDirectory,
            in: .userDomainMask
        ).first!
        let dir = documents.appendingPathComponent("SavedVideos")
        // Ensure the directory exists
        if !fileManager.fileExists(atPath: dir.path) {
            do {
                try fileManager.createDirectory(
                    at: dir,
                    withIntermediateDirectories: true,
                    attributes: nil
                )
            } catch {
                // Log error or handle more gracefully if directory creation fails
                debugPrint("Error creating SavedVideos directory: \(error)")
            }
        }
        return dir
    }

    enum StitchingError: Error {
        case tracksNotFound(String)
        case assetPropertyLoadFailed(String)
        case compositionTrackError(String)
        case exportSessionCreationFailed
        case exportFailed(String)
        case genericError(String)
    }

    func fetchAllSavedVideos() -> [URL] {
        do {
            let contents = try fileManager.contentsOfDirectory(
                at: videosDirectory,
                includingPropertiesForKeys: nil,
                options: .skipsHiddenFiles
            )
            return contents.filter {
                $0.pathExtension.lowercased() == "mov"
                    || $0.pathExtension.lowercased() == "mp4"
            }
        } catch {
            debugPrint("Error fetching saved videos: \(error)")
            return []
        }
    }

    func stitchAndSaveVideos(
        frontURL: URL,
        backURL: URL,
        outputSize: CGSize,
        frontSegmentTargetSize: CGSize,
        backSegmentTargetSize: CGSize
    ) async throws -> URL {

        let frontAsset = AVAsset(url: frontURL)
        let backAsset = AVAsset(url: backURL)

        // Load necessary properties asynchronously
        async let frontVideoTracks = frontAsset.loadTracks(
            withMediaType: .video
        )
        async let backVideoTracks = backAsset.loadTracks(withMediaType: .video)
        async let frontAudioTracks = frontAsset.loadTracks(
            withMediaType: .audio
        )
        async let frontAssetDuration = frontAsset.load(.duration)
        async let backAssetDuration = backAsset.load(.duration)

        guard let frontVideoTrack = try await frontVideoTracks.first else {
            throw StitchingError.tracksNotFound("Front video track not found.")
        }
        guard let backVideoTrack = try await backVideoTracks.first else {
            throw StitchingError.tracksNotFound("Back video track not found.")
        }

        let minDuration = min(
            try await frontAssetDuration,
            try await backAssetDuration
        )

        let composition = AVMutableComposition()
        let videoComposition = AVMutableVideoComposition()

        videoComposition.renderSize = outputSize
        videoComposition.frameDuration = CMTime(value: 1, timescale: 30)  // Standard frame rate

        // --- Front Video Processing ---
        guard
            let frontCompositionTrack = composition.addMutableTrack(
                withMediaType: .video,
                preferredTrackID: kCMPersistentTrackID_Invalid
            )
        else {
            throw StitchingError.compositionTrackError(
                "Could not add front video composition track."
            )
        }
        do {
            try frontCompositionTrack.insertTimeRange(
                CMTimeRange(start: .zero, duration: minDuration),
                of: frontVideoTrack,
                at: .zero
            )
        } catch {
            throw StitchingError.compositionTrackError(
                "Failed to insert front video track: \(error.localizedDescription)"
            )
        }

        let frontNaturalSize = try await frontVideoTrack.load(.naturalSize)
        let frontPreferredTransform = try await frontVideoTrack.load(
            .preferredTransform
        )

        let frontLayerInstruction = AVMutableVideoCompositionLayerInstruction(
            assetTrack: frontCompositionTrack
        )
        let frontCropRect = calculateCropRect(
            videoNaturalSize: frontNaturalSize,
            previewBoundsSize: frontSegmentTargetSize,
            videoGravity: .resizeAspectFill
        )
        frontLayerInstruction.setCropRectangle(frontCropRect, at: .zero)

        let frontTransform = calculateTransform(
            naturalSize: frontNaturalSize,
            preferredTransform: frontPreferredTransform,
            cropRect: frontCropRect,
            targetSegmentSize: frontSegmentTargetSize,
            outputCompositionSize: outputSize,
            isTopSegment: false
        )
        frontLayerInstruction.setTransform(frontTransform, at: .zero)

        // --- Back Video Processing ---
        guard
            let backCompositionTrack = composition.addMutableTrack(
                withMediaType: .video,
                preferredTrackID: kCMPersistentTrackID_Invalid
            )
        else {
            throw StitchingError.compositionTrackError(
                "Could not add back video composition track."
            )
        }
        do {
            try backCompositionTrack.insertTimeRange(
                CMTimeRange(start: .zero, duration: minDuration),
                of: backVideoTrack,
                at: .zero
            )
        } catch {
            throw StitchingError.compositionTrackError(
                "Failed to insert back video track: \(error.localizedDescription)"
            )
        }

        let backNaturalSize = try await backVideoTrack.load(.naturalSize)
        let backPreferredTransform = try await backVideoTrack.load(
            .preferredTransform
        )

        let backLayerInstruction = AVMutableVideoCompositionLayerInstruction(
            assetTrack: backCompositionTrack
        )
        let backCropRect = calculateCropRect(
            videoNaturalSize: backNaturalSize,
            previewBoundsSize: backSegmentTargetSize,  // Cropping for back camera
            videoGravity: .resizeAspectFill
        )
        backLayerInstruction.setCropRectangle(backCropRect, at: .zero)

        let backTransform = calculateTransform(
            naturalSize: backNaturalSize,
            preferredTransform: backPreferredTransform,
            cropRect: backCropRect,
            targetSegmentSize: backSegmentTargetSize,  // Slot size for back camera
            outputCompositionSize: outputSize,
            isTopSegment: true
        )
        backLayerInstruction.setTransform(backTransform, at: .zero)

        // --- Audio Processing ---
        // Using front camera's audio. Modify if you want back's or mix.
        if let audioSourceTrack = try await frontAudioTracks.first {
            if let audioCompositionTrack = composition.addMutableTrack(
                withMediaType: .audio,
                preferredTrackID: kCMPersistentTrackID_Invalid
            ) {
                do {
                    try audioCompositionTrack.insertTimeRange(
                        CMTimeRange(start: .zero, duration: minDuration),
                        of: audioSourceTrack,
                        at: .zero
                    )
                } catch {
                    debugPrint(
                        "Could not add audio track: \(error.localizedDescription)"
                    )
                    // Decide if this is a critical error or if video can proceed without audio
                }
            }
        } else {
            debugPrint("No audio track found in the front video asset.")
        }

        // --- Combine Instructions ---
        let mainInstruction = AVMutableVideoCompositionInstruction()
        mainInstruction.timeRange = CMTimeRange(
            start: .zero,
            duration: minDuration
        )
        mainInstruction.layerInstructions = [
            backLayerInstruction, frontLayerInstruction,
        ]  // Front video drawn "after" back

        videoComposition.instructions = [mainInstruction]

        // --- Export ---
        let outputFileName = "stitched_\(UUID().uuidString).mov"
        let outputURL = videosDirectory.appendingPathComponent(outputFileName)

        removeIfExists(outputURL)  // Clean up if file already exists

        guard
            let exporter = AVAssetExportSession(
                asset: composition,
                presetName: AVAssetExportPresetHighestQuality
            )
        else {
            throw StitchingError.exportSessionCreationFailed
        }

        exporter.outputURL = outputURL
        exporter.outputFileType = .mov
        exporter.videoComposition = videoComposition
        exporter.shouldOptimizeForNetworkUse = true

        await exporter.export()  // Perform export asynchronously

        switch exporter.status {
        case .completed:
            debugPrint("Export completed successfully. Output: \(outputURL)")
            return outputURL
        case .failed:
            let errorDescription =
                exporter.error?.localizedDescription ?? "Unknown export error"
            debugPrint("Export failed: \(errorDescription)")
            if let exportError = exporter.error {
                debugPrint("Export error details: \(exportError)")
            }
            throw StitchingError.exportFailed(
                "Export failed: \(errorDescription). Error: \(String(describing: exporter.error))"
            )
        case .cancelled:
            throw StitchingError.exportFailed("Export cancelled.")
        default:
            throw StitchingError.exportFailed(
                "Export finished with an unknown status: \(exporter.status)."
            )
        }
    }

    private func calculateCropRect(
        videoNaturalSize: CGSize,
        previewBoundsSize: CGSize,
        videoGravity: AVLayerVideoGravity
    ) -> CGRect {
        // Ensure we don't divide by zero
        if videoNaturalSize.height == 0 || videoNaturalSize.width == 0
            || previewBoundsSize.height == 0 || previewBoundsSize.width == 0
        {
            return CGRect(origin: .zero, size: videoNaturalSize)  // Return full frame if sizes are invalid
        }

        if videoGravity != .resizeAspectFill {  // Only implement .resizeAspectFill for now
            return CGRect(origin: .zero, size: videoNaturalSize)
        }

        let videoAspectRatio = videoNaturalSize.width / videoNaturalSize.height
        let previewAspectRatio =
            previewBoundsSize.width / previewBoundsSize.height
        var cropRect = CGRect(origin: .zero, size: videoNaturalSize)

        if videoAspectRatio > previewAspectRatio {  // Video is wider than preview bounds; crop sides
            let newWidth = videoNaturalSize.height * previewAspectRatio
            cropRect.origin.x = (videoNaturalSize.width - newWidth) / 2
            cropRect.size.width = newWidth
        } else if videoAspectRatio < previewAspectRatio {  // Video is taller than preview bounds; crop top/bottom
            let newHeight = videoNaturalSize.width / previewAspectRatio
            cropRect.origin.y = (videoNaturalSize.height - newHeight) / 2
            cropRect.size.height = newHeight
        }
        // else: aspect ratios are the same, no crop needed beyond natural size.

        return cropRect.integral  // Use integral to avoid sub-pixel rendering issues.
    }

    private func calculateTransform(
        naturalSize: CGSize,
        preferredTransform: CGAffineTransform,
        cropRect: CGRect,
        targetSegmentSize: CGSize,
        outputCompositionSize: CGSize,
        isTopSegment: Bool
    ) -> CGAffineTransform {

        // 1. Create a transform that effectively makes the top-left of the cropRect the origin,
        //    then applies the preferredTransform (which handles rotation/mirroring).
        var transform = CGAffineTransform(
            translationX: -cropRect.origin.x,
            y: -cropRect.origin.y
        )
        transform = transform.concatenating(preferredTransform)

        // 2. Determine the size of the *cropped and oriented* video.
        //    Applying preferredTransform to cropRect.size will give us this.
        let croppedAndOrientedRect = CGRect(origin: .zero, size: cropRect.size)
            .applying(preferredTransform)
        let effectiveCroppedWidth = abs(croppedAndOrientedRect.width)
        let effectiveCroppedHeight = abs(croppedAndOrientedRect.height)

        if effectiveCroppedWidth == 0 || effectiveCroppedHeight == 0 {
            return transform  // Avoid division by zero, return current transform
        }

        // 3. Scale this cropped & oriented video to fit the targetSegmentSize.
        let scaleX = targetSegmentSize.width / effectiveCroppedWidth
        let scaleY = targetSegmentSize.height / effectiveCroppedHeight
        transform = transform.concatenating(
            CGAffineTransform(scaleX: scaleX, y: scaleY)
        )

        // 4. Translate this scaled video to its final position in the output composition.
        var finalX: CGFloat = 0
        var finalY: CGFloat = 0

        if isTopSegment {
            // Top segment's bottom-left corner will be at (0, outputCompositionSize.height / 2)
            finalY = outputCompositionSize.height / 2
        } else {
            // Bottom segment's bottom-left corner will be at (0, 0)
            finalY = 0
        }

        if transform.a * scaleX < 0 {
            finalX += targetSegmentSize.width
        }
        // If preferredTransform.d < 0 (vertical flip, less common for camera)
        // After scaling, its bottom edge (which was originally top) needs to be at finalY.
        if transform.d * scaleY < 0 {  // If overall vertical scale is negative (flipped)
            finalY += targetSegmentSize.height
        }
        transform = transform.concatenating(
            CGAffineTransform(translationX: finalX, y: finalY)
        )

        return transform
    }

    private func removeIfExists(_ url: URL) {
        if fileManager.fileExists(atPath: url.path) {
            try? fileManager.removeItem(at: url)
        }
    }
}
