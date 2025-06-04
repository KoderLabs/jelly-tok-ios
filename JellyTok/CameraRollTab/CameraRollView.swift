//
//  CameraRoll.swift
//  JellyTok
//
//  Created by Faique Ali on 29/05/2025.
//

import SwiftUI

struct CameraRollView: View {

    @StateObject private var viewModel = CameraRollViewModel()
    @State private var currentIndex: Int = 1

    @State private var selectedTab = "Library"
    let tabs = ["Library", "Saved"]

    @State private var selectedVideo: URL? = nil
    @State private var videoURLs: [URL] = []

    var body: some View {
        TabView(selection: $currentIndex) {
            ScrollView {
                VStack(spacing: 0) {
                    ProfileHeaderView()

                    // Tabs
                    HStack(spacing: 0) {
                        ForEach(tabs, id: \.self) { tab in
                            Button(action: {
                                if tab == "Library" {
                                    withAnimation(.easeInOut) {
                                        selectedTab = tab
                                    }
                                }
                            }) {
                                VStack(spacing: 6) {
                                    Text(tab)
                                        .font(.subheadline)
                                        .fontWeight(
                                            selectedTab == tab
                                                ? .bold : .regular
                                        )
                                        .foregroundColor(
                                            selectedTab == tab
                                                ? Color(hex: "#B92D4A") : .gray
                                        )
                                        .frame(maxWidth: .infinity)

                                    Capsule()
                                        .fill(
                                            selectedTab == tab
                                                ? Color(hex: "#B92D4A")
                                                : Color.clear
                                        )
                                        .frame(height: 4)
                                        .frame(maxWidth: 30)
                                }
                                .padding(.vertical, 8)
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 10)

                    StaggeredGridView(videoURLs: videoURLs)
                }
                .padding(.bottom, 50)
            }
            .edgesIgnoringSafeArea(.top)
        }
        .edgesIgnoringSafeArea(.top)
        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
        .onAppear {
            loadSavedVideos()
        }
    }

    private func loadSavedVideos() {
        videoURLs.removeAll()
        videoURLs = LocalStorageManager.shared.fetchAllSavedVideos()
    }
}

#Preview {
    CameraRollView()
}
