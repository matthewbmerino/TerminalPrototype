//
//  WelcomePage.swift
//  TerminalPrototype
//
//  Created by Matthew Merino on 2/23/25.
//

import SwiftUI

struct WelcomePage: View {
    var body: some View {
        VStack {
            ZStack {
                RoundedRectangle(cornerRadius: 30)
                    .frame(width: 150, height: 150)
                    .foregroundColor(.black)  // Changed to black
                
                Image(systemName: "chart.xyaxis.line")
                    .font(.system(size: 70))
                    .foregroundColor(.white)  // Remains white
            }
            Text("Terminal")
                .padding()
                .foregroundColor(.white)
                .font(.title)
                .font(.largeTitle)
                .fontWeight(.semibold)
            Text("by Matthew Merino")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.white)
        }
        .padding()
    }
}

#Preview {
    WelcomePage()
}
