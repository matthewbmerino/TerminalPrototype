//
//  FeaturesPage.swift
//  TerminalPrototype
//
//  Created by Matthew Merino on 2/23/25.
//

import SwiftUI

struct FeaturesPage: View {
    var body: some View {
        VStack {
            Text("Elevate Your Portfolio")
//                .padding()
                .font(.title)
                .fontWeight(.semibold)
                .padding(.bottom)
                .foregroundColor(.white)
            
            FeatureCard(iconName: "chart.xyaxis.line",
                        description: "Visualize Holdings")
            FeatureCard(iconName: "text.bubble.fill",
                        description: "Research with AI")
//            FeatureCard(iconName: "cup.and.saucer.fill",
//                        description: "Fuel Your Decisions")
        }
        .padding()
    }
}


#Preview {
    FeaturesPage()
}
