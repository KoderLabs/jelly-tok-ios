//
//  CameraRollViewModel.swift
//  JellyTok
//
//  Created by Moiz Siddiqui on 29/05/2025.
//

import Foundation

class CameraRollViewModel: ObservableObject {
    @Published var videos: [VideoPost] = []

    init() {
        loadMockVideos()
    }

    private func loadMockVideos() {
        if let loadedVideos: [VideoPost] = Bundle.main.decode("MockData.json") {
            self.videos = loadedVideos
        } else {
            debugPrint("Failed to load MockData.json")
        }
    }
}

