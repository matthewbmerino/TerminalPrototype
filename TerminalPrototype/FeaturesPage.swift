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
                        description: "Visualize Performance")
            FeatureCard(iconName: "text.bubble.fill",
                        description: "AI Research Tools")
            FeatureCard(iconName: "person.2.circle.fill",
                        description: "Privately Share")
        }
        .padding()
    }
}


#Preview {
    FeaturesPage()
}
