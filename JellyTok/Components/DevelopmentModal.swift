//
//  DevelopmentModal.swift
//  JellyTok
//
//  Created by Muhammad Ali on 30/05/2025.
//

import SwiftUI

struct DevelopmentModal: View {
   @Environment(\.dismiss) var dismiss

    var body: some View {
           VStack {
               Spacer()

               VStack {
                   Image("development_icon").resizable().frame(width: 225,height: 225)
                   Text("Development in Progress")
                       .font(.headline)
                       .foregroundColor(.black)
                       .padding()
               }
               .frame(width: 250, height: 300)
               .background(Color.white)
               .cornerRadius(20)
               .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)

               Spacer()
           }.padding(16)
           .frame(maxWidth: .infinity, maxHeight: .infinity)
           .background(Color.black.opacity(0.5)
           
            .ignoresSafeArea()).position(x:UIScreen.screenWidth/2,y:UIScreen.screenHeight/2) // Optional dimming background
       }
}

struct DevelopmentModal_Previews: PreviewProvider {
    static var previews: some View {
        DevelopmentModal()
    }
}
