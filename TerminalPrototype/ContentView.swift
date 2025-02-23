//
//  ContentView.swift
//  TerminalPrototype
//
//  Created by Matthew Merino on 2/23/25.
//

import SwiftUI

let gradientColors: [Color] = [
    .gradientTop,
    .gradientBottom
]

struct ContentView: View {
    var body: some View {
        ZStack {
            // Full-screen gradient background
            LinearGradient(
                gradient: Gradient(colors: gradientColors),
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .edgesIgnoringSafeArea(.all)
            
            // Content layered on top
            VStack {
                TabView {
                    WelcomePage()
                    FeaturesPage()
                    LoginPage()
//                    DashboardPage()
                }
                .tabViewStyle(.page)
                // .foregroundStyle(.white) // Uncomment if you need white text/icons
            }
            .padding() // Padding inside the content, not affecting the background
        }
    }
}

#Preview {
    ContentView()
}
