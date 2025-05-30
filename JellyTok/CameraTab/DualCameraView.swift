//
//  DualCameraView.swift
//  JellyTok
//
//  Created by Moiz Siddiqui on 29/05/2025.
//

import SwiftUI
import AVFoundation
import AVKit

struct DualCameraView: View {
    @Binding var selectedTab: Tab
    @StateObject private var cameraManager = DualCameraManager()

    @State private var isRecording = false
    @State private var showPlayback = false
    @State private var recordingCountdown = 15
    @State private var recordingTimer: Timer?
    @State private var showDevelopmentSheet = false

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                CameraView(session: cameraManager.session)
                    .frame(height: UIScreen.main.bounds.height / 2)
                    .overlay(alignment: .topLeading) {
                        
                        HStack(alignment: .top) {
                            ControlIconButton(iconName: "cross_icon") {
                                selectedTab = .feed
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 12) {
                                ControlIconButton(iconName: "t_icon") {
                                    showDevelopmentSheet = true
                                }
                                
                                ControlIconButton(iconName: "camera_cut_icon") {
                                    showDevelopmentSheet = true
                                }
                                
                                ControlIconButton(iconName: "flash_cut_icon") {
                                    showDevelopmentSheet = true
                                }
                                
                                ControlIconButton(iconName: "gear_icon") {
                                    showDevelopmentSheet = true
                                }
                                
                                ControlIconButton(iconName: "vertical_dots_icon") {
                                    showDevelopmentSheet = true
                                }
                            
                            }
                        }
                        .padding(.top, 60)
                        .padding(.horizontal, 16)
                    }
                
                CameraView(session: cameraManager.session)
                    .frame(height: UIScreen.main.bounds.height / 2)
            }
            .ignoresSafeArea()
            
            // Recording Overlay
            VStack {
                Spacer()
                
                if isRecording {
                    HStack(spacing: 10) {
                        Text("Duration \(recordingCountdown)s")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white)
                            .bold()
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color(hex: "#B92D4A"))
                            .clipShape(Capsule())
                    }
                    .padding(.bottom, 20)
                }
                
                HStack(alignment: .center) {
                    Button(action: {
                        selectedTab = .roll
                    }) {
                        Image("gallery_icon")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 48, height: 48)
                    }
                    .disabled(isRecording)
                    .padding(.bottom, 40)
                    
                    Spacer()
                    Button(action: {
                        isRecording = true
                        recordingCountdown = 15
                        startCountdown()
                        cameraManager.startRecording()
                    }) {
                        Image("camera_button_icon")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 70, height: 70)
                    }
                    .disabled(isRecording)
                    .padding(.bottom, 40)
                    
                    
                    Spacer()
                    Button(action: {
                        showDevelopmentSheet = true
                }) {
                        Image("reset_icon")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 48, height: 48)
                    }
                    .disabled(isRecording)
                    .padding(.bottom, 40)
                }
                .padding(.horizontal)
            }
            
            // To Test: Playback
            if showPlayback, let stitchedURL = cameraManager.stitchedOutputURL {
                PlaybackOverlay(videoURL: stitchedURL)
            }
        }
        .onAppear {
            cameraManager.startSession()
        }
        .onDisappear {
            cameraManager.stopSession()
        }
        .onReceive(cameraManager.$recordingFinished) { finished in
            if finished {
                isRecording = false
                recordingTimer?.invalidate()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    selectedTab = .roll
                }
            }
        }
        if showDevelopmentSheet {
            DevelopmentModal().transition(.opacity)
                .zIndex(1)
                .onTapGesture {
                    showDevelopmentSheet = false
                }
        }
    }
    
    private func startCountdown() {
        recordingTimer?.invalidate()
        recordingTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            if recordingCountdown > 1 {
                recordingCountdown -= 1
            } else {
                timer.invalidate()
                isRecording = false
                cameraManager.stopRecording()
            }
        }
    }
}

struct ControlIconButton: View {
    let iconName: String
    let action: () -> Void
    let size: CGFloat

    init(iconName: String, size: CGFloat = 36, action: @escaping () -> Void) {
        self.iconName = iconName
        self.size = size
        self.action = action
    }
    init(iconName: String, action: @escaping () -> Void) {
        self.iconName = iconName
        self.size = 36
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Image(iconName)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: size, height: size)
                .background(
                    Circle()
                        .fill(Color.white)
                        .opacity(0.4)
                )
        }
    }
}

struct PlaybackOverlay: View {
    let videoURL: URL
    
    var body: some View {
        VideoPlayer(player: AVPlayer(url: videoURL))
            .edgesIgnoringSafeArea(.all)
            .onAppear {
                // Auto-play
                AVPlayer(url: videoURL).play()
            }
    }
}


#Preview {
    DualCameraView(selectedTab: .constant(.camera)).background(Color.black)
}
