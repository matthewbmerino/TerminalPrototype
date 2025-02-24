//
//  FeaturesPage.swift
//  TerminalPrototype
//
//  Created by Matthew Merino on 2/23/25.
//

import SwiftUI

struct FeaturesPage: View {
    @State private var visibleIndex = -1
    let timer = Timer.publish(every: 1.5, on: .main, in: .common).autoconnect()
    
    var body: some View {
        VStack(spacing: 24) { // Increased spacing between elements
            Text("Elevate Your Portfolio")
                .font(.title)
                .fontWeight(.semibold)
                .padding(.bottom, 32) // More breathing room below title
                .foregroundColor(.white)
            
            FeatureCard(iconName: "chart.xyaxis.line",
                       description: "Explore & Visualize Data")
                .opacity(visibleIndex >= 0 ? 1 : 0)
                .offset(x: visibleIndex >= 0 ? 0 : -20) // Subtle slide-in
                .scaleEffect(visibleIndex == 0 ? 1.05 : 1.0) // Minimal scale for highlight
                .animation(.easeOut(duration: 0.5), value: visibleIndex)
            
            FeatureCard(iconName: "text.bubble.fill",
                       description: "Chat & Research with AI")
                .opacity(visibleIndex >= 1 ? 1 : 0)
                .offset(x: visibleIndex >= 1 ? 0 : -20)
                .scaleEffect(visibleIndex == 1 ? 1.05 : 1.0)
                .animation(.easeOut(duration: 0.5), value: visibleIndex)
            
            FeatureCard(iconName: "person.2.circle",
                       description: "Privately Share Insights")
                .opacity(visibleIndex >= 2 ? 1 : 0)
                .offset(x: visibleIndex >= 2 ? 0 : -20)
                .scaleEffect(visibleIndex == 2 ? 1.05 : 1.0)
                .animation(.easeOut(duration: 0.5), value: visibleIndex)
        }
        .padding(.horizontal, 24) // Wider side padding
        .padding(.vertical, 32)   // More vertical padding
        .onReceive(timer) { _ in
            if visibleIndex < 2 {
                visibleIndex += 1
            }
        }
    }
}

#Preview {
    FeaturesPage()
}
