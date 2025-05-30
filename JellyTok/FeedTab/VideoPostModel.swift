//
//  VideoPost.swift
//  JellyTok
//
//  Created by Faique Ali on 29/05/2025.
//

import Foundation

struct VideoPost: Codable, Identifiable {
    let id: String
    let videoFileName: String
    let thumbnailFileName: String
    let description: String
    let user: User
    let sound: Sound
    let likes: Int
    let comments: Int
    let shares: Int
    
    struct User: Codable {
        let id: String
        let username: String
        let avatarName: String
    }
    
    struct Sound: Codable {
        let id: String
        let title: String
        let artist: String
    }
}

