//
//  StaggeredGridView.swift
//  JellyTok
//
//  Created by Moiz Siddiqui on 29/05/2025.
//

import SwiftUI

struct StaggeredGridView: View {
    let videoURLs: [URL]
    let heights: [CGFloat] = [180, 240, 200, 160, 250]

    var body: some View {
        if self.videoURLs.isEmpty {
            Text("No Video(s)")
                .foregroundStyle(Color.gray)
                .bold()
        } else {
            HStack(alignment: .top, spacing: 12) {
                videoColumn(startingAt: 0)
                videoColumn(startingAt: 1)
            }
            .padding(.horizontal)
            .padding(.bottom, 50)
        }
    }

    private func videoColumn(startingAt indexOffset: Int) -> some View {
        LazyVStack(spacing: 12) {
            ForEach(videoURLs.indices.filter { $0 % 2 == indexOffset }, id: \.self) { index in
                InlineVideoView(videoURL: videoURLs[index])
                    .frame(height: heights[index % heights.count])
                    .cornerRadius(12)
            }
        }
    }
}
