//
//  LoginPage.swift
//  TerminalPrototype
//
//  Created by Matthew Merino on 2/23/25.
//

import SwiftUI

struct LoginPage: View {
    @State private var username: String = "" // Stores username or email input
    @State private var password: String = "" // Stores password input
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Login")
                .font(.title)
                .foregroundStyle(.white)
                .padding(.bottom, 20)
            
            // Username/Email field
            TextField("Username or Email", text: $username)
                .padding()
                .background(Color.black.opacity(0.0)) // Transparent background
                .foregroundStyle(.white) // White text color
                .border(Color.gray, width: 1) // Border with gray color
                .cornerRadius(8) // Optional: rounded corners
                .padding(.horizontal)
                .submitLabel(.next) // Keyboard "Next" button
            
            // Password field
            SecureField("Password", text: $password)
                .padding()
                .background(Color.black.opacity(0.0)) // Transparent background
                .foregroundStyle(.white) // White text color
                .border(Color.gray, width: 1) // Border with gray color
                .cornerRadius(8) // Optional: rounded corners
                .padding(.horizontal)
                .submitLabel(.go) // Keyboard "Go" button
            
            // Login button
            Button(action: {
                // Handle login logic here (e.g., authentication)
                print("Login attempted with username: \(username), password: \(password)")
            }) {
                Text("Sign In")
                    .font(.headline)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.black)
                    .foregroundStyle(.white)
                    .cornerRadius(10)
            }
            .padding(.horizontal)
        }
        .padding()
    }
}

//#Preview {
//    LoginPage()
//        .background(
//            LinearGradient(
//                gradient: Gradient(colors: [.blue, .purple]),
//                startPoint: .top,
//                endPoint: .bottom
//            )
//        ) // Gradient background for preview visibility
//}

#Preview {
    LoginPage()
}
