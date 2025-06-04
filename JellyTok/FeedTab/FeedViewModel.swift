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
            if oldValue != currentPostIndex {
                indexUpdateWorkItem?.cancel()
                let workItem = DispatchWorkItem { [weak self] in
                    self?.managePlayerLifecycleAndPlayback()
                }
                self.indexUpdateWorkItem = workItem
                DispatchQueue.main.asyncAfter(
                    deadline: .now() + 0.1,
                    execute: workItem
                )  // Debounce retained
            } else if !posts.indices.contains(currentPostIndex)
                && !posts.isEmpty
            {
                DispatchQueue.main.async { self.isCurrentVideoPlaying = false }
            }
        }
    }

    @Published var isCurrentVideoPlaying: Bool = false
    @Published var initialLoadAttempted: Bool = false

    private var playerContainerPool: [PlayerContainer] = []
    private var activePlayerContainers: [String: PlayerContainer] = [:]
    private let maxPoolSize = 3
    private let preloadBuffer = 1
    private let emptyPlayer = AVPlayer()
    private var indexUpdateWorkItem: DispatchWorkItem?
    private var globalMuteObservation: AnyCancellable?

    init() {
        for _ in 0..<maxPoolSize {
            playerContainerPool.append(PlayerContainer())
        }
        loadFeed()
    }

    deinit {
        indexUpdateWorkItem?.cancel()
        activePlayerContainers.values.forEach { $0.resetForPooling() }
        activePlayerContainers.removeAll()
        playerContainerPool.removeAll()
    }

    func loadFeed() {
        initialLoadAttempted = false

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

            if error != nil {
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
                            self.managePlayerLifecycleAndPlayback()
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
            if let loadedPosts: [VideoPost] = Bundle.main.decode(
                "MockData.json"
            ) {
                self.posts = loadedPosts
                if !self.posts.isEmpty {
                    self.managePlayerLifecycleAndPlayback()
                }
            } else {
                self.posts = []
            }
        }
    }

    private func createPlayerItem(for post: VideoPost) -> AVPlayerItem? {
        guard
            let url = Bundle.main.url(
                forResource: post.videoFileName,
                withExtension: "mp4"
            )
        else {
            return nil
        }
        return AVPlayerItem(url: url)
    }

    private func getContainerForPost(_ post: VideoPost) -> PlayerContainer {
        if let existingActive = activePlayerContainers[post.id] {
            return existingActive
        }

        if !playerContainerPool.isEmpty {
            let container = playerContainerPool.removeFirst()
            return container
        } else {
            return PlayerContainer()
        }
    }

    private func returnContainerToPool(_ container: PlayerContainer) {
        container.resetForPooling()
        if playerContainerPool.count < maxPoolSize {
            playerContainerPool.append(container)
        }
    }

    private func managePlayerLifecycleAndPlayback() {
        guard !posts.isEmpty else {
            DispatchQueue.main.async { self.isCurrentVideoPlaying = false }
            return
        }
        guard posts.indices.contains(currentPostIndex) else {
            DispatchQueue.main.async { self.isCurrentVideoPlaying = false }
            activePlayerContainers.values.forEach { returnContainerToPool($0) }
            activePlayerContainers.removeAll()
            return
        }

        let activeWindowStartIndex = max(0, currentPostIndex - preloadBuffer)
        let activeWindowEndIndex = min(
            posts.count - 1,
            currentPostIndex + preloadBuffer
        )

        var newActiveContainersTemp: [String: PlayerContainer] = [:]
        var postIDsInWindow = Set<String>()

        for i in activeWindowStartIndex...activeWindowEndIndex {
            let post = posts[i]
            postIDsInWindow.insert(post.id)

            var container: PlayerContainer
            if let existingActive = activePlayerContainers[post.id] {
                container = existingActive
            } else {
                container = getContainerForPost(post)
                if let newPlayerItem = createPlayerItem(for: post) {
                    let postIndexBeingConfigured = i

                    container.configure(
                        for: post.id,
                        with: newPlayerItem,
                        onIsPlayingChanged: {
                            [weak self, postId = post.id] isPlaying in
                            guard let self = self,
                                self.posts.indices.contains(
                                    self.currentPostIndex
                                ),
                                self.posts[self.currentPostIndex].id == postId
                            else { return }
                            DispatchQueue.main.async {
                                if self.isCurrentVideoPlaying != isPlaying {
                                    self.isCurrentVideoPlaying = isPlaying
                                }
                            }
                        },
                        onReadyToPlay: { [weak self, weak container] _ in
                            guard let self = self,
                                let readyContainer = container
                            else { return }

                            if postIndexBeingConfigured == self.currentPostIndex
                            {
                                readyContainer.play()
                            } else {
                                readyContainer.pause()
                            }
                        },
                        onPlayToEnd: { [weak container] in
                            container?.seekToStartAndPlay()
                        }
                    )
                }
            }
            newActiveContainersTemp[post.id] = container
        }

        let oldActiveKeys = Set(activePlayerContainers.keys)
        let keysToReturnToPool = oldActiveKeys.subtracting(postIDsInWindow)

        for key in keysToReturnToPool {
            if let containerToReturn = activePlayerContainers.removeValue(
                forKey: key
            ) {
                returnContainerToPool(containerToReturn)
            }
        }
        activePlayerContainers = newActiveContainersTemp

        for (postId, container) in activePlayerContainers {
            guard
                let postForContainer = posts.first(where: { $0.id == postId }),
                let indexOfPostForContainer = posts.firstIndex(where: {
                    $0.id == postForContainer.id
                })
            else {
                continue
            }

            if indexOfPostForContainer == self.currentPostIndex {
                if container.player.currentItem?.status == .readyToPlay
                    && !container.isPlaying
                {
                    container.play()
                }
            } else {
                if container.isPlaying
                    || container.player.timeControlStatus == .playing
                {
                    container.pause()
                }
            }
        }

        if let currentPost = posts.get(at: currentPostIndex),
            let currentContainer = activePlayerContainers[currentPost.id]
        {
            let actualPlayingStatus = currentContainer.isPlaying
            DispatchQueue.main.async {
                if self.isCurrentVideoPlaying != actualPlayingStatus {
                    self.isCurrentVideoPlaying = actualPlayingStatus
                }
            }
        } else {
            DispatchQueue.main.async {
                if self.isCurrentVideoPlaying {  // Only update if it was true
                    self.isCurrentVideoPlaying = false
                }
            }
        }
    }

    func playerFor(post: VideoPost) -> AVPlayer {
        if let container = activePlayerContainers[post.id] {
            return container.player
        }
        return emptyPlayer
    }

    func togglePlayback() {
        guard posts.indices.contains(currentPostIndex) else { return }
        let currentPost = posts[currentPostIndex]
        guard let container = activePlayerContainers[currentPost.id] else {
            managePlayerLifecycleAndPlayback()
            if let newContainer = activePlayerContainers[currentPost.id] {
                newContainer.play()
            }
            return
        }

        if container.isPlaying {
            container.pause()
        } else {
            if container.player.currentItem == nil {
                if let newPlayerItem = createPlayerItem(for: currentPost) {
                    container.configure(
                        for: currentPost.id,
                        with: newPlayerItem,
                        onIsPlayingChanged: {
                            [weak self, postId = currentPost.id] isPlaying in
                            guard let self = self,
                                self.posts.indices.contains(
                                    self.currentPostIndex
                                ),
                                self.posts[self.currentPostIndex].id == postId
                            else { return }
                            DispatchQueue.main.async {
                                if self.isCurrentVideoPlaying != isPlaying {
                                    self.isCurrentVideoPlaying = isPlaying
                                }
                            }
                        },
                        onReadyToPlay: { [weak container] _ in
                            container?.play()
                        },
                        onPlayToEnd: { [weak container] in
                            container?.seekToStartAndPlay()
                        }
                    )
                }
            } else {
                container.play()
            }
        }
    }

    func onFeedAppear() {
        managePlayerLifecycleAndPlayback()
        if let currentPost = posts.get(at: currentPostIndex),
            let currentContainer = activePlayerContainers[currentPost.id],
            currentContainer.player.currentItem?.status == .readyToPlay,
            !currentContainer.isPlaying
        {
            currentContainer.play()
        }
    }

    func onFeedDisappear() {
        activePlayerContainers.values.forEach { container in
            returnContainerToPool(container)
        }
        activePlayerContainers.removeAll()
        DispatchQueue.main.async {
            self.isCurrentVideoPlaying = false
        }
    }
}
