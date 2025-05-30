//
//  FeedViewModel.swift
//  JellyTok
//
//  Created by Faique Ali on 29/05/2025.
//

import AVKit

class FeedViewModel: ObservableObject {
    @Published var posts: [VideoPost] = []
    private var players: [String: AVPlayer] = [:] // Cache players by post.id

    init() {
        loadLocalFeed()
    }

    private func loadLocalFeed() {
        let url = URL(string: "https://api-dev-nomadnest.kodefuse.com/test-json")!
        let task = URLSession.shared.dataTask(with: url, completionHandler: { (data, response, error) in
            if let _ = error {
                if let loadedPosts: [VideoPost] = Bundle.main.decode("MockData.json") {
                    DispatchQueue.main.async {
                        self.posts = loadedPosts
                    }
                }
                return
            }

            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                return
            }

            if let data = data,
               let loadedPosts = try? JSONDecoder().decode([VideoPost].self, from: data) {
                DispatchQueue.main.async {
                    self.posts = loadedPosts
                }
            }
        })
        task.resume()
    }


    func player(for post: VideoPost) -> AVPlayer? {
        if let existing = players[post.id] {
            return existing
        }

        guard let url = Bundle.main.url(forResource: post.videoFileName, withExtension: "mp4") else {
            return nil
        }

        let player = AVPlayer(url: url)
        players[post.id] = player
        return player
    }
}
