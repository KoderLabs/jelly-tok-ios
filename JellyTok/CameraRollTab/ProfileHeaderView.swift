//
//  ProfileHeaderView.swift
//  JellyTok
//
//  Created by Moiz Siddiqui on 29/05/2025.
//

import SwiftUI

struct ProfileHeaderView: View {
    var body: some View {
        ZStack {
            VStack{
                Image("profile_background")
                    .resizable()
                    .scaledToFill()
                    .frame(height: 210)
                    .clipped()
                
                Spacer()
            }
            
            VStack {
                Spacer().frame(height: 166)
                Rectangle()
                    .fill(Color.white).opacity(0.4)
                    .frame(height: 50)
                    .clipShape(RoundedCorners(radius: 30, corners: [.topLeft, .topRight]))
                    .padding(.horizontal)
                
                Spacer()
            }
            
            VStack {
                Spacer().frame(height: 180)
                Rectangle()
                    .fill(Color.white)
                    .frame(height: 50)
                    .clipShape(RoundedCorners(radius: 30, corners: [.topLeft, .topRight]))
                
                Spacer()
            }
            
            VStack {
                Spacer().frame(height: 120)
                Image("avatar")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 100, height: 100)
                
                Text("Kevin Jordan")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .padding(.top, 16)
                
                Text("Photographer")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                Text("Lorem Ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry's")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.top, 8)
                    .padding(.horizontal, 40)
                
                Spacer()
            }
        }
        .edgesIgnoringSafeArea(.top)
        .frame(height: 380)
    }
}

struct RoundedCorners: Shape {
    var radius: CGFloat = 30
    var corners: UIRectCorner = [.topLeft, .topRight]

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

// Helper for specific corner radius
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorners(radius: radius, corners: corners))
    }
}

#Preview {
    ProfileHeaderView()
}
