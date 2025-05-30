//
//  FeedView.swift
//  JellyTok
//
//  Created by Faique Ali on 29/05/2025.
//

import AVKit
import SwiftUI

struct FeedView: View {
    @Binding var selectedTab: Tab
    @StateObject private var viewModel = FeedViewModel()
    @State private var currentIndex: Int = 0
    @State private var showDevelopmentSheet = false
    
    var body: some View {
        GeometryReader { geo in
            TabView(selection: $currentIndex) {
                ForEach(Array(viewModel.posts.enumerated()), id: \.element.id) {
                    index,
                    post in
                    VStack {
                        ZStack(alignment: .top) {
                            if let player = viewModel.player(for: post) {
                                VideoPlayer(player: player)
                                    .aspectRatio(contentMode: .fill)
                                    .frame(
                                        width: geo.size.width,
                                        height: geo.size.height
                                    )
                                    .clipped()
                                    .onAppear {
                                        player.isMuted = false
                                        player.seek(to: .zero)
                                        player.play()
                                    }
                                    .onDisappear {
                                        player.isMuted = true
                                    }
                            } else {
                                Color.black
                                    .frame(
                                        width: geo.size.width,
                                        height: geo.size.height
                                    )
                            }

                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.black.opacity(0.6), .clear,
                                ]),
                                startPoint: .bottom,
                                endPoint: .top
                            )
                            .frame(
                                width: geo.size.width,
                                height: geo.size.height
                            )

                            // Overlay
                            PostOverlayView(
                                post: post,
                                action: {
                                    selectedTab = .roll  
                                },
                                onTap:{
                                    showDevelopmentSheet = true
                                }
                            )
                            .frame(maxWidth: geo.size.width)
                            .padding(.bottom, 80)
                        }
                        .frame(width: geo.size.width, height: geo.size.height)
                        .tag(index)

                        Spacer()
                    }
                    .ignoresSafeArea()
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
        }
        .background(Color.black)
        .ignoresSafeArea()
        if showDevelopmentSheet {
            DevelopmentModal().transition(.opacity)
                .zIndex(1)
                .onTapGesture {
                    showDevelopmentSheet = false
                }
        }
    }
}

#Preview {
    FeedView(selectedTab: .constant(.feed))
}
