//
//  FeedVideoView.swift
//  JellyTok
//
//  Created by Faique Ali on 03/06/2025.
//

import AVKit
import SwiftUI

struct FeedVideoView: View {
    let post: VideoPost
    let player: AVPlayer
    @Binding var isPlaying: Bool
    let isCurrentVideo: Bool
    let geo: GeometryProxy

    let onSelectTab: () -> Void
    let onOpenDevSheet: () -> Void
    let onTogglePlayback: () -> Void

    @State private var showPlayPauseIndicator = false

    var body: some View {
        ZStack(alignment: .top) {
            // Video Player Layer
            VideoPlayer(player: player)
                .aspectRatio(contentMode: .fill)
                .frame(width: geo.size.width, height: geo.size.height)
                .clipped()
                .disabled(true)
                .id(post.id)

            // Transparent Tap Gesture Overlay
            Color.clear
                .frame(width: geo.size.width, height: geo.size.height)
                .contentShape(Rectangle())
                .onTapGesture {
                    onTogglePlayback()
                    showPlayPauseIndicator = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        withAnimation {
                            showPlayPauseIndicator = false
                        }
                    }
                }

            // Gradient Overlay
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.black.opacity(0.6), .clear,
                ]),
                startPoint: .bottom,
                endPoint: .top
            )
            .frame(width: geo.size.width, height: geo.size.height)
            .allowsHitTesting(false)

            // Post Info Overlay
            PostOverlayView(
                post: post,
                action: onSelectTab,
                onTap: onOpenDevSheet
            )
            .padding(.bottom, 80)

            // Play/Pause Indicator
            if showPlayPauseIndicator {
                VStack {
                    Spacer()
                    Image(
                        systemName: self.isPlaying ? "pause.fill" : "play.fill"
                    )
                    .resizable()
                    .scaledToFit()
                    .frame(width: 50, height: 50)
                    .foregroundColor(.white.opacity(0.7))
                    .transition(.opacity.combined(with: .scale(scale: 0.8)))
                    .zIndex(1)
                    Spacer()
                }

            }
        }
        .frame(width: geo.size.width, height: geo.size.height)
        .ignoresSafeArea()
    }
}
