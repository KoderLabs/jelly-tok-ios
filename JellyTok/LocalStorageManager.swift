//
//  LocalStorageManager.swift
//  JellyTok
//
//  Created by Faique Ali on 30/05/2025.
//

import Foundation
import AVFoundation
import UIKit

class LocalStorageManager {
    static let shared = LocalStorageManager()
    private init() {}
    
    private let fileManager = FileManager.default
    
    /// Directory where saved videos will go
    private var videosDirectory: URL {
        let documents = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let dir = documents.appendingPathComponent("SavedVideos")
        if !fileManager.fileExists(atPath: dir.path) {
            try? fileManager.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }
    
    func fetchAllSavedVideos() -> [URL] {
        do {
            let contents = try fileManager.contentsOfDirectory(at: videosDirectory, includingPropertiesForKeys: nil)
            return contents.filter { $0.pathExtension == "mov" || $0.pathExtension == "mp4" }
        } catch {
            debugPrint("Error fetching saved videos: \(error)")
            return []
        }
    }
    
    // Main method to stitch and save front/back videos vertically
    @MainActor
    func stitchAndSaveVideos(frontURL: URL, backURL: URL) async throws -> URL {
        return try await withCheckedThrowingContinuation { continuation in
            stitchVideos(frontURL: frontURL, backURL: backURL) { result in
                switch result {
                case .success(let stitchedURL):
                    continuation.resume(returning: stitchedURL)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    private func transformedSize(of transform: CGAffineTransform, originalSize: CGSize) -> CGSize {
        let rect = CGRect(origin: .zero, size: originalSize)
        let transformedRect = rect.applying(transform)
        return CGSize(width: abs(transformedRect.width), height: abs(transformedRect.height))
    }
    
    private func stitchVideos(frontURL: URL, backURL: URL, completion: @escaping (Result<URL, Error>) -> Void) {
        let videoSize = CGSize(width: 1080, height: 1920)
        let halfHeight = videoSize.height / 2
        
        let frontAsset = AVURLAsset(url: frontURL)
        let backAsset = AVURLAsset(url: backURL)

        let composition = AVMutableComposition()

        guard let track1 = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid),
              let track2 = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid),
              let frontTrack = frontAsset.tracks(withMediaType: .video).first,
              let backTrack = backAsset.tracks(withMediaType: .video).first else {
            return completion(.failure(NSError(domain: "TrackError", code: 2, userInfo: nil)))
        }

        let duration = min(frontAsset.duration, backAsset.duration)

        do {
            try track1.insertTimeRange(CMTimeRange(start: .zero, duration: duration), of: frontTrack, at: .zero)
            try track2.insertTimeRange(CMTimeRange(start: .zero, duration: duration), of: backTrack, at: .zero)
        } catch {
            return completion(.failure(error))
        }

        // Add audio track from front video
        if let audioTrack = frontAsset.tracks(withMediaType: .audio).first,
           let audioCompositionTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid) {
            try? audioCompositionTrack.insertTimeRange(CMTimeRange(start: .zero, duration: duration), of: audioTrack, at: .zero)
        }

        // Get preferred transforms
        let frontTransform = frontTrack.preferredTransform
        let backTransform = backTrack.preferredTransform

        // Get natural sizes
        let frontSize = transformedSize(of: frontTransform, originalSize: frontTrack.naturalSize)
        let backSize = transformedSize(of: backTransform, originalSize: backTrack.naturalSize)

        // Calculate scale ratios
        let frontScale = halfHeight / frontSize.height
        let backScale = halfHeight / backSize.height

        // Calculate translation for centering horizontally
        let frontXTranslation = (videoSize.width - frontSize.width * frontScale) / 2
        let backXTranslation = (videoSize.width - backSize.width * backScale) / 2

        // Compose transforms
        let frontFinalTransform = frontTransform
            .concatenating(CGAffineTransform(scaleX: frontScale, y: frontScale))
            .concatenating(CGAffineTransform(translationX: frontXTranslation, y: 0))

        let backFinalTransform = backTransform
            .concatenating(CGAffineTransform(scaleX: backScale, y: backScale))
            .concatenating(CGAffineTransform(translationX: backXTranslation, y: halfHeight))

        let layerInstruction1 = AVMutableVideoCompositionLayerInstruction(assetTrack: track1)
        layerInstruction1.setTransform(frontFinalTransform, at: .zero)

        let layerInstruction2 = AVMutableVideoCompositionLayerInstruction(assetTrack: track2)
        layerInstruction2.setTransform(backFinalTransform, at: .zero)

        let instruction = AVMutableVideoCompositionInstruction()
        instruction.timeRange = CMTimeRange(start: .zero, duration: duration)
        instruction.layerInstructions = [layerInstruction1, layerInstruction2]

        let videoComposition = AVMutableVideoComposition()
        videoComposition.instructions = [instruction]
        videoComposition.frameDuration = CMTime(value: 1, timescale: 30)
        videoComposition.renderSize = videoSize

        let outputURL = videosDirectory.appendingPathComponent("stitched_\(UUID().uuidString).mov")

        guard let exporter = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetHighestQuality) else {
            return completion(.failure(NSError(domain: "ExporterError", code: 3, userInfo: nil)))
        }

        exporter.videoComposition = videoComposition
        exporter.outputURL = outputURL
        exporter.outputFileType = .mov
        exporter.shouldOptimizeForNetworkUse = true

        exporter.exportAsynchronously {
            if exporter.status == .completed {
                completion(.success(outputURL))
            } else {
                completion(.failure(exporter.error ?? NSError(domain: "ExportFailed", code: 4, userInfo: nil)))
            }
        }
    }

    
}
