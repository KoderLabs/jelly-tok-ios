//
//  CustomTabBar.swift
//  JellyTok
//
//  Created by Faique Ali on 29/05/2025.
//

import SwiftUI

struct CustomTabBar: View {
    @Binding var selectedTab: Tab

    let icons: [(image: String, tab: Tab)] = [
        ("home_icon", .feed),
        ("plus_icon", .camera),
        ("user_icon", .roll)
    ]

    var body: some View {
        VStack {
            Spacer()

            HStack(alignment: .center) {
                ForEach(icons, id: \.tab) { item in
                    Spacer()

                    Button(action: {
                        selectedTab = item.tab
                    }) {
                        VStack(spacing: 8) {
                            if item.image == "plus_icon" {
                                Image(item.image)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 72, height: 42)
                            } else {
                                Image(item.image)
                                    .renderingMode(.template)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(height: 20)
                                    .foregroundColor(
                                        selectedTab == item.tab
                                            ? Color(hex: "#B92D4A")
                                            : Color.white.opacity(0.8)
                                    )
                                
                                // Show the circle indicator only for non-plus icons
                                Circle()
                                    .fill(Color(hex: "#B92D4A"))
                                    .frame(width: 6, height: 6)
                                    .opacity(selectedTab == item.tab ? 1 : 0)
                            }
                        }
                    }
                    Spacer()
                }
            }
            .padding(.top, 16)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color.black)
                    .edgesIgnoringSafeArea(.bottom)
            )
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        .padding(.bottom, 20)
        .edgesIgnoringSafeArea(.bottom)
    }
}


#Preview {
    CustomTabBar(selectedTab: .constant(.feed))
}
