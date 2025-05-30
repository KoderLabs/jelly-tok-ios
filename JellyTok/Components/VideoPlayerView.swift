//
//  VideoPlayerView.swift
//  JellyTok
//
//  Created by Faique Ali on 29/05/2025.
//

import SwiftUI
import AVKit

struct VideoPlayerView: View {
    let videoName: String
    @State private var player: AVPlayer?
    
    var body: some View {
        ZStack {
            if let player = player {
                VideoPlayer(player: player)
                    .background(Color.black)
                    .aspectRatio(contentMode: .fill)
                    .onAppear {
                        player.seek(to: .zero)
                        player.play()
                    }
            } else {
                Color.black
            }
        }
        .onAppear {
            if let url = Bundle.main.url(forResource: videoName, withExtension: "mp4") {
                player = AVPlayer(url: url)
                player?.isMuted = true
            }
        }
    }
}


#Preview {
    VideoPlayerView(videoName: "sampleVideo1")
}
