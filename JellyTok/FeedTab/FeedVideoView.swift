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
    let index: Int
    let geo: GeometryProxy

    let onSelectTab: () -> Void
    let onOpenDevSheet: () -> Void
    let player: AVPlayer?

    @State private var showPlayPauseIcon = false
    @State private var isPlaying = true

    var body: some View {

        ZStack(alignment: .top) {
            if let player = player {
                VideoPlayer(player: player)
                    .aspectRatio(contentMode: .fill)
                    .frame(width: geo.size.width, height: geo.size.height)
                    .clipped()
                    .onAppear {
                        player.isMuted = false
                        player.seek(to: .zero)
                        player.play()
                    }
                    .onDisappear {
                        player.isMuted = true
                        player.pause()
                    }
            } else {
                Color.black
                    .frame(width: geo.size.width, height: geo.size.height)
            }

            Color.clear
                .contentShape(Rectangle())
                .onTapGesture {
                    if let player = player {
                        if player.timeControlStatus == .playing {
                            player.pause()
                            isPlaying = false
                        } else {
                            player.play()
                            isPlaying = true
                        }

                        withAnimation {
                            showPlayPauseIcon = true
                        }
                        DispatchQueue.main.asyncAfter(
                            deadline: .now() + 0.5
                        ) {
                            withAnimation {
                                showPlayPauseIcon = false
                            }
                        }
                    }
                }

            LinearGradient(
                gradient: Gradient(colors: [
                    Color.black.opacity(0.6), .clear,
                ]),
                startPoint: .bottom,
                endPoint: .top
            )
            .frame(width: geo.size.width, height: geo.size.height)
            .allowsHitTesting(false)

            PostOverlayView(
                post: post,
                action: onSelectTab,
                onTap: onOpenDevSheet
            )
            .frame(maxWidth: geo.size.width)
            .padding(.bottom, 80)

            if showPlayPauseIcon {
                VStack {
                    Spacer()
                    Image(
                        systemName: isPlaying ? "pause.fill" : "play.fill"
                    )
                    .resizable()
                    .scaledToFit()
                    .frame(width: 60, height: 60)
                    .foregroundColor(.white)
                    .transition(.opacity)
                    Spacer()
                }
            }
        }
        .frame(width: geo.size.width, height: geo.size.height)
        .tag(index)
        .ignoresSafeArea()
    }
}
