//
//  JellyTokApp.swift
//  JellyTok
//
//  Created by Faique Ali on 28/05/2025.
//

import SwiftUI

@main
struct JellyTokApp: App {
    init() {
        UIView.appearance().overrideUserInterfaceStyle = .light
    }
    
    var body: some Scene {
        WindowGroup {
            SplashView()
        }
    }
}
