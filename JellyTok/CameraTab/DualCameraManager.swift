//
//  DualCameraManager 2.swift
//  JellyTok
//
//  Created by Moiz Siddiqui on 29/05/2025.
//

import AVFoundation

class DualCameraManager: NSObject, ObservableObject {
    @Published var recordingFinished = false
    @Published var stitchedOutputURL: URL?
    
    let session = AVCaptureMultiCamSession()
    var frontOutputURL: URL?
    var backOutputURL: URL?
    private var frontRecorder: AVCaptureMovieFileOutput?
    private var backRecorder: AVCaptureMovieFileOutput?
    private var frontFinished = false
    private var backFinished = false

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
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: position),
              let input = try? AVCaptureDeviceInput(device: device),
              session.canAddInput(input) else {
            debugPrint("Unable to add input for \(position == .front ? "front" : "back") camera.")
            return
        }

        session.addInput(input)

        let output = AVCaptureMovieFileOutput()
        guard session.canAddOutput(output) else {
            debugPrint("Unable to add output for \(position == .front ? "front" : "back") camera.")
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
              session.canAddInput(audioInput) else {
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
    }

    func startRecording() {
        AVAudioSession.sharedInstance().requestRecordPermission { granted in
            if granted {
                Task {
                    // Ensure audio session is configured
                    try? AVAudioSession.sharedInstance().setCategory(.playAndRecord, mode: .default)
                    try? AVAudioSession.sharedInstance().setActive(true)

                    await self.waitUntilSessionIsRunning()

                    let tempDir = FileManager.default.temporaryDirectory

                    self.frontOutputURL = tempDir.appendingPathComponent(UUID().uuidString + "_front.mov")
                    self.backOutputURL = tempDir.appendingPathComponent(UUID().uuidString + "_back.mov")

                    if let frontURL = self.frontOutputURL {
                        self.removeIfExists(frontURL)
                        self.frontRecorder?.startRecording(to: frontURL, recordingDelegate: self)
                    }

                    if let backURL = self.backOutputURL {
                        self.removeIfExists(backURL)
                        self.backRecorder?.startRecording(to: backURL, recordingDelegate: self)
                    }

                    DispatchQueue.main.asyncAfter(deadline: .now() + 12) {
                        self.stopRecording()
                    }
                }
            } else {
                debugPrint("Microphone access denied.")
            }
        }
    }

    private func waitUntilSessionIsRunning() async {
        while !session.isRunning {
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1s
        }
    }

    func stopRecording() {
        if frontRecorder?.isRecording == true {
            frontRecorder?.stopRecording()
        }

        if backRecorder?.isRecording == true {
            backRecorder?.stopRecording()
        }
    }

    func uploadAndNavigate() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.recordingFinished = true
        }
    }

    private func removeIfExists(_ url: URL) {
        if FileManager.default.fileExists(atPath: url.path) {
            try? FileManager.default.removeItem(at: url)
        }
    }
}

extension DualCameraManager: AVCaptureFileOutputRecordingDelegate {
    func fileOutput(_ output: AVCaptureFileOutput,
                    didFinishRecordingTo outputFileURL: URL,
                    from connections: [AVCaptureConnection],
                    error: Error?) {
        if let error = error {
            debugPrint("Recording error: \(error.localizedDescription)")
            return
        }

        debugPrint("Finished recording to: \(outputFileURL.lastPathComponent)")

        if output == frontRecorder {
            frontFinished = true
        } else if output == backRecorder {
            backFinished = true
        }

        if frontFinished && backFinished {
            Task {
                if let frontURL = frontOutputURL,
                   let backURL = backOutputURL {
                    do {
                        let stitchedURL = try await LocalStorageManager.shared.stitchAndSaveVideos(
                            frontURL: frontURL,
                            backURL: backURL
                        )
                        debugPrint("Stitched and saved at: \(stitchedURL)")
                        
                        await MainActor.run {
                            self.stitchedOutputURL = stitchedURL
                            self.recordingFinished = true
                        }
                    } catch {
                        debugPrint("Error stitching videos: \(error)")
                    }
                }
            }
        }
    }
}
