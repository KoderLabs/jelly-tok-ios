//
//  PostOverlayView.swift
//  JellyTok
//
//  Created by Faique Ali on 29/05/2025.
//

import SwiftUI

struct PostOverlayView: View {
    let post: VideoPost
    let action: () -> Void
    let onTap: () -> Void
    

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Spacer()
            
            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 0) {
                    Text(post.user.username)
                        .foregroundColor(.white)
                        .bold()
                    
                    Text(post.description)
                        .font(.footnote)
                        .foregroundColor(.white)
                        .fixedSize(horizontal: false, vertical: true) // allow multiline
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 20) {
                    Button(action: action) {
                    VStack(alignment: .center, spacing: 0) {
                        
                            Image("avatar")
                                .resizable()
                                .frame(width: 38, height: 38)
                                .clipShape(Circle())
                                .overlay(
                                    Circle()
                                        .stroke(Color.white, lineWidth: 2)
                                )
                        }
                    }
                    Button(action: onTap) {
                    VStack(alignment: .center, spacing: 0) {
                        
                            Image("heart_icon")
                                .renderingMode(.template)
                                .resizable()
                                .frame(width: 30, height: 30)
                                .foregroundColor(Color(hex: "#B92D4A"))
                            
                            Text("\(post.likes)")
                                .font(.caption)
                            .foregroundColor(Color.white)}
                    }
                    Button(action: onTap) {
                    VStack(alignment: .center, spacing: 0) {
                       
                            Image("bubble_icon")
                                .renderingMode(.template)
                                .resizable()
                                .frame(width: 30, height: 30)
                                .foregroundColor(.white)
                            Text("\(post.comments)")
                                .font(.caption)
                            .foregroundColor(Color.white)}
                    }
                    Button(action: onTap) {
                    VStack(alignment: .center, spacing: 0) {
                       
                            Image("right_arrow_icon")
                                .renderingMode(.template)
                                .resizable()
                                .frame(width: 30, height: 30)
                                .foregroundColor(.white)
                            Text("\(post.shares)")
                                .font(.caption)
                            .foregroundColor(Color.white)}
                    }
                    Button(action: onTap) {
                    VStack(alignment: .center, spacing: 0) {
                       
                            Image("dots_icon")
                                .renderingMode(.template)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 30, height: 30)
                            .foregroundColor(.white)}
                    }
                }

            }
            .padding(.horizontal)
        }
        .padding(.bottom, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}



#Preview {
    PostOverlayView(post: VideoPost(id: "post1", videoFileName: "sampleVideo1", thumbnailFileName: "thumbnail1", description: "Exploring the city vibes! 🏙️ So much to see and do. #citylife #adventure", user: VideoPost.User(id: "user123", username: "UrbanExplorer", avatarName: "avatar1") , sound: VideoPost.Sound(id: "soundABC", title: "Upbeat Funk Groove", artist: "StudioMusician"), likes: 15200, comments: 345, shares: 120), action: {}
    ,onTap: {}).background(Color.black)
}
