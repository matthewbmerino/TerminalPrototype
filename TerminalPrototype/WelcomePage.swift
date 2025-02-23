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
                
                Image(systemName: "chart.xyaxis.line")
                    .font(.system(size: 70))
                    .foregroundColor(.white)
//                insert picture stuff here and use font sizer, color, etc to fill in black square
                
            }
            Text("Terminal")
                .padding()
                .foregroundColor(.white)
                .font(.title)
                .font(.largeTitle).fontWeight(.semibold)
            Text("by Matthew Merino")
//                .padding()
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
