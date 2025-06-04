//
//  FeedViewModel.swift
//  JellyTok
//
//  Created by Faique Ali on 29/05/2025.
//

import AVFoundation
import Combine
import Foundation

class FeedViewModel: ObservableObject {
    @Published var posts: [VideoPost] = []
    @Published var currentPostIndex: Int = 0 {
        didSet {
            if oldValue != currentPostIndex,
                posts.indices.contains(currentPostIndex)
            {
                playVideo(at: currentPostIndex)
            } else if !posts.indices.contains(currentPostIndex)
                && !posts.isEmpty
            {
                activePlayer.replaceCurrentItem(with: nil)
            }
        }
    }

    @Published var activePlayer: AVPlayer
    @Published var isPlaying: Bool = false
    @Published var initialLoadAttempted: Bool = false

    private var playerItemsCache: [String: AVPlayerItem] = [:]
    private var playerStatusObservation: NSKeyValueObservation?
    private var playerItemStatusObservation: NSKeyValueObservation?
    private var didPlayToEndObserver: Any?
    private var cancellables = Set<AnyCancellable>()

    init() {
        self.activePlayer = AVPlayer()
        self.activePlayer.isMuted = false

        // Observe player's status
        playerStatusObservation = activePlayer.observe(
            \.timeControlStatus,
            options: [.initial, .new]
        ) { [weak self] player, _ in
            DispatchQueue.main.async {
                self?.isPlaying = (player.timeControlStatus == .playing)
            }
        }
        loadFeed()
    }

    deinit {
        playerStatusObservation?.invalidate()
        playerItemStatusObservation?.invalidate()
        if let observer = didPlayToEndObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        activePlayer.replaceCurrentItem(with: nil)
    }

    func loadFeed() {
        let url = URL(
            string: "https://api-dev-nomadnest.kodefuse.com/test-json"
        )!
        URLSession.shared.dataTask(with: url) {
            [weak self] data, response, error in
            guard let self = self else { return }

            defer {
                DispatchQueue.main.async {
                    self.initialLoadAttempted = true
                }
            }

            if let _ = error {
                self.loadLocalFeedFallback()
                return
            }

            guard let httpResponse = response as? HTTPURLResponse,
                (200...299).contains(httpResponse.statusCode)
            else {
                self.loadLocalFeedFallback()
                return
            }

            if let data = data {
                do {
                    let loadedPosts = try JSONDecoder().decode(
                        [VideoPost].self,
                        from: data
                    )
                    DispatchQueue.main.async {
                        self.posts = loadedPosts
                        if !self.posts.isEmpty {
                            self.playVideo(at: self.currentPostIndex)
                        }
                    }
                } catch {
                    self.loadLocalFeedFallback()
                }
            } else {
                self.loadLocalFeedFallback()
            }
        }.resume()
    }

    private func loadLocalFeedFallback() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            defer { self.initialLoadAttempted = true } 
            if let loadedPosts: [VideoPost] = Bundle.main.decode(
                "MockData.json"
            ) {  // Ensure MockData.json exists
                self.posts = loadedPosts
                if !self.posts.isEmpty {
                    self.playVideo(at: self.currentPostIndex)
                }
            } else {
                self.posts = []
            }
        }
    }

    private func getPlayerItem(for post: VideoPost) -> AVPlayerItem? {
        if let cachedItem = playerItemsCache[post.id] {
            return cachedItem
        }

        guard
            let url = Bundle.main.url(
                forResource: post.videoFileName,
                withExtension: "mp4"
            )
        else {
            return nil
        }
        let item = AVPlayerItem(url: url)
        playerItemsCache[post.id] = item
        return item
    }

    private func playVideo(at index: Int) {
        guard posts.indices.contains(index) else {
            activePlayer.replaceCurrentItem(with: nil)
            return
        }

        let post = posts[index]
        guard let newItem = getPlayerItem(for: post) else {
            activePlayer.replaceCurrentItem(with: nil)
            return
        }

        // Remove previous item's observers
        if let currentItem = activePlayer.currentItem {
            playerItemStatusObservation?.invalidate()
            if let observer = didPlayToEndObserver {
                NotificationCenter.default.removeObserver(
                    observer,
                    name: .AVPlayerItemDidPlayToEndTime,
                    object: currentItem
                )
            }
        }

        activePlayer.replaceCurrentItem(with: newItem)

        // Observe new item's status
        playerItemStatusObservation = newItem.observe(
            \.status,
            options: [.new, .initial]
        ) { [weak self] item, _ in
            guard let self = self else { return }
            if item.status == .readyToPlay {
                self.activePlayer.play()
            }
        }

        // Loop the video
        didPlayToEndObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: newItem,
            queue: .main
        ) { [weak self] _ in
            self?.activePlayer.seek(to: .zero)
            self?.activePlayer.play()
        }

        // Preload next item
        preloadNextItem(currentIndex: index)
    }

    private func preloadNextItem(currentIndex: Int) {
        let nextIndex = currentIndex + 1
        if posts.indices.contains(nextIndex) {
            let nextPost = posts[nextIndex]
            if playerItemsCache[nextPost.id] == nil {
                DispatchQueue.global(qos: .background).async { [weak self] in
                    _ = self?.getPlayerItem(for: nextPost)  // Create and cache
                }
            }
        }
    }

    func togglePlayback() {
        if activePlayer.timeControlStatus == .playing {
            activePlayer.pause()
        } else if activePlayer.timeControlStatus == .paused {
            if activePlayer.currentItem?.status == .readyToPlay {
                activePlayer.play()
            } else {
                playVideo(at: currentPostIndex)
            }
        }
    }

    func onFeedAppear() {
        if !posts.isEmpty && posts.indices.contains(currentPostIndex) {
            if activePlayer.currentItem == nil {
                playVideo(at: currentPostIndex)
            } else if activePlayer.currentItem?.status == .readyToPlay {
                activePlayer.play()
            }
        }
    }

    func onFeedDisappear() {
        activePlayer.pause()
    }
}

extension FeedViewModel {
    var loadFeedCalled: Bool {
        return true
    }
}
