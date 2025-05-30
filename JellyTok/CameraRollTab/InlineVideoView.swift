//
//  InlineVideoView.swift
//  JellyTok
//
//  Created by Moiz Siddiqui on 29/05/2025.
//


import AVKit
import SwiftUI

struct InlineVideoView: View {
    let videoURL: URL
    @State private var player: AVPlayer?
    @State private var timeObserver: Any?
    @State private var showFullScreen = false

    var body: some View {
        ZStack(alignment: .topTrailing) {
            GeometryReader { geometry in
                VideoPlayer(player: player)
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .clipped()
                    
                LinearGradient(
                    gradient: Gradient(colors: [Color.black.opacity(0.6), .clear]),
                    startPoint: .bottom,
                    endPoint: .top
                )
                .ignoresSafeArea(edges: .bottom)
                .onTapGesture {
                    showFullScreen = true
                }
            }

            // Duration label
            Text("00:15")
                .font(.caption)
                .foregroundColor(.white)
                .padding(6)
                .background(Color.black.opacity(0.6))
                .clipShape(Capsule())
                .padding(6)
        }
        .onAppear {
            startPlayer()
        }
        .onDisappear {
            stopPlayer()
            if let observer = timeObserver {
                player?.removeTimeObserver(observer)
                timeObserver = nil
            }
        }
        .fullScreenCover(isPresented: $showFullScreen) {
            FullscreenPlayerView(videoURL: videoURL)
        }
    }

    private func startPlayer() {
        let avPlayer = AVPlayer(url: videoURL)
        avPlayer.isMuted = true
        avPlayer.play()

        // Observe time to reset after 5 seconds
        let interval = CMTime(seconds: 0.5, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        timeObserver = avPlayer.addPeriodicTimeObserver(forInterval: interval, queue: .main) { time in
            if time.seconds >= 5 {
                avPlayer.seek(to: .zero)
                avPlayer.play()
            }
        }

        player = avPlayer
    }

    private func stopPlayer() {
        player?.pause()
    }
}

