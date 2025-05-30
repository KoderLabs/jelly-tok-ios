# 📱 JellyTok – iOS Engineering Challenge

JellyTok is a lightweight iOS app built using SwiftUI for iOS 16+, designed for the Jelly iOS Engineering Challenge. It captures creativity, technical capability, and product thinking across a three-tab interface.

## ✨ Features

### Tab 1 – Feed
- TikTok-style scrollable video feed.
- Fetches videos from a custom API.
- Smooth UX with autoplay and overlay.

### Tab 2 – Dual POV Camera
- Split-screen view using both front and back cameras.
- 15-second synchronized dual video recording.
- Saves videos locally using `FileManager`.
- Navigates to Camera Roll on completion.

### Tab 3 – Camera Roll
- Displays all recorded videos in a grid.
- Supports inline and full-screen playback.
- Neatly organized and accessible from local storage.

---

## 🧱 Tech Stack

- **Language**: Swift
- **Framework**: SwiftUI
- **Platform**: iOS 16+
- **Media**: AVFoundation
- **Storage**: FileManager (local storage)
- **Networking**: URLSession (custom API)
- **Architecture**: MVVM (feature-based folder structure)

> ❌ No third-party libraries or SDKs used.

---

## 🛠 Project Structure

The project is organized by feature folders to support scalability and clarity:

- **Assets.xcassets/**
  - AccentColor.colorset  
  - AppIcon.appiconset  
  - … (other assets)

- **CameraRollTab/**
  - `CameraRollView.swift` – UI for video grid/list  
  - `CameraRollViewModel.swift` – Handles video fetching logic  
  - `FullscreenPlayerView.swift` – Fullscreen playback  
  - `InlineVideoView.swift` – Inline player inside grid  
  - `ProfileHeaderView.swift` – Profile section (optional)  
  - `StaggeredGridView.swift` – Custom staggered grid layout  

- **CameraTab/**
  - `CameraView.swift` – Dual camera recording screen  
  - `DualCameraManager.swift` – Handles front & back camera sessions  
  - `DualCameraView.swift` – UI for split-screen camera layout  

- **Components/**
  - `CustomTabBar.swift` – Custom tab bar UI  
  - `VideoPlayerView.swift` – Reusable video player component  

- **ContentView.swift** – Handles tab navigation  

- **Extensions/**
  - `Bundle+.swift` – App metadata helpers  
  - `Color+.swift` – Custom app colors  
  - `Foundation+.swift` – General-purpose helpers  

- **FeedTab/**
  - `FeedView.swift` – UI for video feed (scrollable)  
  - `FeedViewModel.swift` – API handling for feed data  
  - `PostOverlayView.swift` – Overlays for each video post  
  - `VideoPostModel.swift` – Data model for posts  

- **JellyTokApp.swift** – App entry point  
- **Launch Screen.storyboard** – Launch screen layout  
- **LocalStorageManager.swift** – Manages saved video files  
- **SplashView.swift** – Initial loading screen  

---

## 🚀 Getting Started

1. Clone the repository:
   ```bash
   git clone https://github.com/yourusername/JellyTok.git
