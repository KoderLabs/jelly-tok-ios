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
    @State private var showDevelopmentSheet = false

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Main Video Content
                mainContent(geo: geo)

                // Development Modal on top
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
            .onAppear {
                viewModel.onFeedAppear()
            }
            .onDisappear {
                viewModel.onFeedDisappear()
            }
        }
    }

    @ViewBuilder
    private func mainContent(geo: GeometryProxy) -> some View {
        if viewModel.posts.isEmpty && !viewModel.initialLoadAttempted {
            // Loading State
            VStack {
                ProgressView()
                    .tint(.gray)
                    .scaleEffect(1.6)
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .background(Color.black)
        } else if !viewModel.posts.isEmpty {
            // Content State
            TabView(selection: $viewModel.currentPostIndex) {
                ForEach(
                    Array(viewModel.posts.enumerated()),
                    id: \.element.id
                ) { index, post in
                    FeedVideoView(
                        post: post,
                        player: viewModel.activePlayer,
                        isPlaying: $viewModel.isPlaying,
                        isCurrentVideo: index == viewModel.currentPostIndex,
                        geo: geo,
                        onSelectTab: { selectedTab = .roll },
                        onOpenDevSheet: { showDevelopmentSheet = true },
                        onTogglePlayback: { viewModel.togglePlayback() }
                    )
                    .tag(index)
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
        } else {
            // Error State
            Text("No videos to display. Please try again later.")
                .foregroundColor(.white)
                .frame(width: geo.size.width, height: geo.size.height)
                .background(Color.black)
        }
    }
}

#Preview {
    FeedView(selectedTab: .constant(.feed))
}
