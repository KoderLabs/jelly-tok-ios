//
//  PlayerContainer.swift
//  JellyTok
//
//  Created by Faique Ali on 04/06/2025.
//

import AVFoundation
import Combine

class GlobalMuteState: ObservableObject {
    static let shared = GlobalMuteState()
    @Published var isMuted: Bool = false

    private init() {}
}

class PlayerContainer {
    let player: AVPlayer
    private(set) var isPlaying: Bool = false
    private(set) var postId: String?

    private var playerTimeControlStatusObservation: NSKeyValueObservation?
    private var playerItemStatusObservation: NSKeyValueObservation?
    private var didPlayToEndObserver: Any?

    private var onIsPlayingChanged: ((Bool) -> Void)?

    let containerId = UUID()

    init() {
        self.player = AVPlayer()
        self.player.isMuted = false
        self.playerTimeControlStatusObservation = self.player.observe(
            \.timeControlStatus,
            options: [.new]
        ) { [weak self] player, _ in
            guard let self = self, self.postId != nil else { return }
            let newIsPlaying = (player.timeControlStatus == .playing)
            if self.isPlaying != newIsPlaying {
                self.isPlaying = newIsPlaying
                self.onIsPlayingChanged?(newIsPlaying)
            }
        }
    }

    func configure(
        for postId: String,
        with item: AVPlayerItem,
        onIsPlayingChanged: @escaping (Bool) -> Void,
        onReadyToPlay: @escaping (_ isCurrentVideo: Bool) -> Void,
        onPlayToEnd: @escaping () -> Void
    ) {
        self.postId = postId
        self.onIsPlayingChanged = onIsPlayingChanged

        playerItemStatusObservation?.invalidate()
        playerItemStatusObservation = nil
        if let observer = didPlayToEndObserver {
            NotificationCenter.default.removeObserver(observer)
            didPlayToEndObserver = nil
        }

        player.replaceCurrentItem(with: item)
        self.isPlaying = player.timeControlStatus == .playing

        playerItemStatusObservation = item.observe(
            \.status,
            options: [.new, .initial]
        ) { [weak self] observedItem, _ in
            guard let self = self, self.postId == postId else { return }
            if observedItem.status == .readyToPlay {
                onReadyToPlay(self.player === self.player)
            }
        }

        didPlayToEndObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: item,
            queue: .main
        ) { [weak self] _ in
            guard let self = self, self.postId == postId else { return }
            onPlayToEnd()
        }
    }

    func play() {
        guard postId != nil else { return }
        if player.currentItem?.status == .readyToPlay {
            player.play()
        }
    }

    func pause() {
        guard postId != nil else { return }
        if player.timeControlStatus != .paused {
            player.pause()
        }
    }

    func seekToStartAndPlay() {
        guard postId != nil else { return }
        player.seek(to: .zero)
        play()
    }

    func resetForPooling() {
        if player.timeControlStatus != .paused {
            player.pause()
        }

        pause()

        playerItemStatusObservation?.invalidate()
        playerItemStatusObservation = nil

        if let observer = didPlayToEndObserver {
            NotificationCenter.default.removeObserver(observer)
            didPlayToEndObserver = nil
        }

        player.replaceCurrentItem(with: nil)

        self.postId = nil
        self.onIsPlayingChanged = nil
        if isPlaying {
            isPlaying = false
        }
    }

    deinit {
        playerTimeControlStatusObservation?.invalidate()
    }
}
