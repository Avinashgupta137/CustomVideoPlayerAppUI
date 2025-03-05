//
//  ContentView.swift
//  CustomVideoPlayer
//
//  Created by AVINASH IOS Dev on 05/03/25.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        GeometryReader {
            let size = $0.size
            let safeArea = $0.safeAreaInsets
            
            Home(size: size, safeArea: safeArea)
                .ignoresSafeArea()
        }
        .preferredColorScheme(.dark)
    }
}
#Preview {
    ContentView()
}
