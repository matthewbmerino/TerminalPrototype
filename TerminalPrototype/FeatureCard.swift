//
//  FeatureCard.swift
//  TerminalPrototype
//
//  Created by Matthew Merino on 2/23/25.
//

import SwiftUI

struct FeatureCard: View {
    let iconName: String
    let description: String
    
    var body: some View {
        HStack {
            Image(systemName: iconName)
                .font(.largeTitle)
            
            Text(description)
        }
        .padding()
        .background(.black, in: RoundedRectangle(cornerRadius: 12))
        .foregroundStyle(.white)
    }
}


#Preview {
    FeatureCard(iconName: "person.2.crop.square.stack.fill",
                description: "A multiline description about a feature paired with the image on the left.")
}
