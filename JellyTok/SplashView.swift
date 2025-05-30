//
//  Splash.swift
//  JellyTok
//
//  Created by Muhammad Ali on 30/05/2025.
//

import SwiftUI

struct SplashView: View {
    
    @State var isActive: Bool = false
    
    var body: some View {
        ZStack {
            if self.isActive {
                ContentView()
            } else {
                Rectangle()
                    .background(Color.black)
                Image("Splash")
                    .resizable()
                    .scaledToFit()
                    .frame(width: UIScreen.screenWidth,
                           height: UIScreen.screenHeight)
                    .ignoresSafeArea()
                  
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                withAnimation {
                    self.isActive = true
                }
            }
        }
    }
        
}

struct SplashView_Previews: PreviewProvider {
    static var previews: some View {
        SplashView()
    }
}

extension UIScreen{
   static let screenWidth = UIScreen.main.bounds.size.width
   static let screenHeight = UIScreen.main.bounds.size.height
   static let screenSize = UIScreen.main.bounds.size
}
