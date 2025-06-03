//
//  FeedView.swift
//  JellyTok
//
//  Created by Faique Ali on 29/05/2025.
//

import SwiftUI

struct FeedView: View {
    @Binding var selectedTab: Tab
    
    @StateObject private var viewModel = FeedViewModel()
    @State private var currentIndex: Int = 0
    @State private var showDevelopmentSheet = false

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // TabView showing videos
                TabView(selection: $currentIndex) {
                    ForEach(
                        Array(viewModel.posts.enumerated()),
                        id: \.element.id
                    ) { index, post in
                        FeedVideoView(
                            post: post,
                            index: index,
                            geo: geo,
                            onSelectTab: { selectedTab = .roll },
                            onOpenDevSheet: { showDevelopmentSheet = true },
                            player: viewModel.player(for: post),
                        )
                        .tag(index)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))

                if showDevelopmentSheet {
                    DevelopmentModal()
                        .transition(.opacity)
                        .zIndex(1)
                        .onTapGesture {
                            showDevelopmentSheet = false
                        }
                }
            }
            .ignoresSafeArea()
            .background(Color.black)
            .frame(width: geo.size.width, height: geo.size.height)
        }
    }
}

#Preview {
    FeedView(selectedTab: .constant(.feed))
}
