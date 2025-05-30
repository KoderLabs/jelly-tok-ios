//
//  ContentView.swift
//  JellyTok
//
//  Created by Faique Ali on 28/05/2025.
//

import SwiftUI

enum Tab {
    case feed, camera, roll
}

struct ContentView: View {
    @State private var selectedTab: Tab = .feed

    var body: some View {
        ZStack(alignment: .bottom) {
            Group {
                switch selectedTab {
                case .feed:
                    FeedView(selectedTab: $selectedTab)
                case .camera:
                    DualCameraView(selectedTab: $selectedTab)
                case .roll:
                    CameraRollView()
                }
            }
            .edgesIgnoringSafeArea(.all)
            
            // Hide tab bar on .camera
            if selectedTab != .camera {
                CustomTabBar(selectedTab: $selectedTab)
            }
        }
    }
}

#Preview {
    ContentView()
}
