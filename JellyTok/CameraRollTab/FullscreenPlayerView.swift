//
//  FullscreenPlayerView.swift
//  JellyTok
//
//  Created by Moiz Siddiqui on 29/05/2025.
//

import SwiftUI
import AVKit

struct FullscreenPlayerView: View {
    let videoURL: URL
    @Environment(\.dismiss) private var dismiss
    @State private var player: AVPlayer?

    var body: some View {
        ZStack {
            // Background video
            VideoPlayer(player: player)
                .edgesIgnoringSafeArea(.all)
                .background(Color.black)
                .onAppear {
                    player = AVPlayer(url: videoURL)
                    player?.play()
                }
                .onDisappear {
                    player?.pause()
                    player = nil
                }
            
            // Close button
            VStack {
                HStack {
                    Spacer()
                    Button(action: { dismiss() }) {
                        Image("cross_icon")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 40, height: 40)
                            .background(
                                Circle()
                                    .fill(Color.white)
                                    .opacity(0.4)
                            )
                            .padding()
                    }
                    Spacer()
                }
                Spacer()
            }
        }
    }
}

#Preview {
    // Use a local sample video bundled in the app, or a safe test URL.
    let sampleURL = URL(string: "https://www.w3schools.com/html/mov_bbb.mp4")!
    FullscreenPlayerView(videoURL: sampleURL)
}
