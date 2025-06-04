//
//  DualCameraManager 2.swift
//  JellyTok
//
//  Created by Moiz Siddiqui on 29/05/2025.
//

import AVFoundation
import UIKit

class DualCameraManager: NSObject, ObservableObject {
    @Published var recordingFinished: Bool = false
    @Published var stitchedOutputURL: URL?
    @Published var processingBegins: Bool = false

    let session = AVCaptureMultiCamSession()
    var frontOutputURL: URL?
    var backOutputURL: URL?
    private var frontRecorder: AVCaptureMovieFileOutput?
    private var backRecorder: AVCaptureMovieFileOutput?
    private var frontFinished = false
    private var backFinished = false

    // A flag to prevent multiple simultaneous processing attempts
    private var isProcessingRecordings = false

    override init() {
        super.init()
        configureSession()
    }

    private func configureSession() {
        session.beginConfiguration()

        setupCamera(position: .back)
        setupCamera(position: .front)
        setupAudioInput()

        session.commitConfiguration()
    }

    private func setupCamera(position: AVCaptureDevice.Position) {
        guard
            let device = AVCaptureDevice.default(
                .builtInWideAngleCamera,
                for: .video,
                position: position
            ),
            let input = try? AVCaptureDeviceInput(device: device),
            session.canAddInput(input)
        else {
            debugPrint(
                "Unable to add input for \(position == .front ? "front" : "back") camera."
            )
            return
        }
        session.addInput(input)

        let output = AVCaptureMovieFileOutput()
        // output.maxRecordedDuration = CMTime(seconds: 15, preferredTimescale: 600) // Max duration for recording
        guard session.canAddOutput(output) else {
            debugPrint(
                "Unable to add output for \(position == .front ? "front" : "back") camera."
            )
            return
        }
        session.addOutput(output)

        if position == .front {
            frontRecorder = output
        } else {
            backRecorder = output
        }
    }

    private func setupAudioInput() {
        guard let audioDevice = AVCaptureDevice.default(for: .audio),
            let audioInput = try? AVCaptureDeviceInput(device: audioDevice),
            session.canAddInput(audioInput)
        else {
            debugPrint("Unable to add audio input")
            return
        }
        session.addInput(audioInput)
    }

    func startSession() {
        guard !session.isRunning else { return }
        DispatchQueue.global(qos: .userInitiated).async {
            self.session.startRunning()
        }
    }

    func stopSession() {
        if session.isRunning {
            session.stopRunning()
        }
        // Deactivate audio session when done
        try? AVAudioSession.sharedInstance().setActive(
            false,
            options: .notifyOthersOnDeactivation
        )
    }

    func startRecording() {
        AVAudioSession.sharedInstance().requestRecordPermission { granted in
            if granted {
                Task {
                    do {
                        try AVAudioSession.sharedInstance().setCategory(
                            .playAndRecord,
                            mode: .videoRecording,
                            options: [
                                .mixWithOthers, .allowBluetoothA2DP,
                                .defaultToSpeaker,
                            ]
                        )
                        try AVAudioSession.sharedInstance().setActive(true)
                    } catch {
                        debugPrint("Failed to set up audio session: \(error)")
                        return
                    }

                    await self.waitUntilSessionIsRunning()

                    // Reset flags for a new recording session
                    self.frontFinished = false
                    self.backFinished = false
                    self.isProcessingRecordings = false

                    // Use app's temporary directory for recordings
                    let tempDir = FileManager.default.temporaryDirectory
                    self.frontOutputURL = tempDir.appendingPathComponent(
                        UUID().uuidString + "_front.mov"
                    )
                    self.backOutputURL = tempDir.appendingPathComponent(
                        UUID().uuidString + "_back.mov"
                    )

                    if let frontURL = self.frontOutputURL {
                        self.removeIfExists(frontURL)
                        self.frontRecorder?.startRecording(
                            to: frontURL,
                            recordingDelegate: self
                        )
                    } else {
                        debugPrint(
                            "Front output URL is nil, cannot start front recording."
                        )
                    }

                    if let backURL = self.backOutputURL {
                        self.removeIfExists(backURL)
                        self.backRecorder?.startRecording(
                            to: backURL,
                            recordingDelegate: self
                        )
                    } else {
                        debugPrint(
                            "Back output URL is nil, cannot start back recording."
                        )
                    }
                }
            } else {
                debugPrint("Microphone access denied.")
            }
        }
    }

    private func waitUntilSessionIsRunning() async {
        while !session.isRunning {
            try? await Task.sleep(nanoseconds: 100_000_000)  // 0.1s
        }
    }

    func stopRecording() {
        var didStopARecorder = false
        if frontRecorder?.isRecording == true {
            frontRecorder?.stopRecording()
            didStopARecorder = true
        }

        if backRecorder?.isRecording == true {
            backRecorder?.stopRecording()
            didStopARecorder = true
        }

        if !didStopARecorder && frontFinished && backFinished
            && !isProcessingRecordings {
            debugPrint(
                "stopRecording called, recorders already stopped and finished. Ensuring processing."
            )
            checkAndProcessRecordings()
        }
    }

    private func checkAndProcessRecordings() {
        // Ensure both finished and not already processing
        guard frontFinished && backFinished && !isProcessingRecordings else {
            return
        }

        isProcessingRecordings = true  // Set flag to prevent re-entry
        processingBegins = true

        Task {
            defer {
                // Reset flag on main thread after processing task finishes or fails
                DispatchQueue.main.async {
                    self.isProcessingRecordings = false
                }
            }

            if let frontURL = frontOutputURL, let backURL = backOutputURL {
                do {
                    // Fetch screen size on MainActor correctly
                    let screenSize = await MainActor.run {
                        UIScreen.main.bounds.size
                    }

                    let segmentHeight = screenSize.height / 2
                    let segmentWidth = screenSize.width

                    let outputVideoSize = screenSize
                    let eachSegmentTargetSize = CGSize(
                        width: segmentWidth,
                        height: segmentHeight
                    )

                    debugPrint(
                        "Stitching videos: Front (\(frontURL.lastPathComponent)), Back (\(backURL.lastPathComponent))"
                    )
                    debugPrint(
                        "Output Size: \(outputVideoSize), Segment Target Size: \(eachSegmentTargetSize)"
                    )

                    let stitchedURL = try await LocalStorageManager.shared
                        .stitchAndSaveVideos(
                            frontURL: frontURL,
                            backURL: backURL,
                            outputSize: outputVideoSize,
                            frontSegmentTargetSize: eachSegmentTargetSize,
                            backSegmentTargetSize: eachSegmentTargetSize
                        )
                    debugPrint("Stitching successful. Output: \(stitchedURL)")

                    await MainActor.run {
                        self.stitchedOutputURL = stitchedURL
                        self.recordingFinished = true
                    }
                } catch {
                    debugPrint("Error stitching videos: \(error)")
                    await MainActor.run {
                        self.stitchedOutputURL = nil
                        self.recordingFinished = true
                    }
                }
            } else {
                debugPrint(
                    "One or both recording URLs are nil during processing."
                )
                await MainActor.run {
                    self.stitchedOutputURL = nil
                    self.recordingFinished = true
                }
            }
        }
    }

    private func removeIfExists(_ url: URL) {
        if FileManager.default.fileExists(atPath: url.path) {
            try? FileManager.default.removeItem(at: url)
        }
    }
}

extension DualCameraManager: AVCaptureFileOutputRecordingDelegate {
    func fileOutput(
        _ output: AVCaptureFileOutput,
        didFinishRecordingTo outputFileURL: URL,
        from connections: [AVCaptureConnection],
        error: Error?
    ) {
        // Determine which recorder finished
        let isFrontRecorder = (output == frontRecorder)
        let recorderName = isFrontRecorder ? "Front" : "Back"

        if let error = error {
            debugPrint(
                "\(recorderName) recorder error for \(outputFileURL.lastPathComponent): \(error.localizedDescription)"
            )
        } else {
            debugPrint(
                "\(recorderName) recorder finished recording to: \(outputFileURL.lastPathComponent)"
            )
        }

        DispatchQueue.main.async {
            if isFrontRecorder {
                self.frontOutputURL = outputFileURL
                self.frontFinished = true
            } else {
                self.backOutputURL = outputFileURL
                self.backFinished = true
            }

            // After updating status, check if both are done
            self.checkAndProcessRecordings()
        }
    }
}
