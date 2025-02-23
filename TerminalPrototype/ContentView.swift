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
        VStack {
            TabView {
                        WelcomePage()
                        FeaturesPage()
                        DashboardPage()
                    }
                    .background(Gradient(colors: gradientColors))
                    .tabViewStyle(.page)
//                    .foregroundStyle(.white)
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
