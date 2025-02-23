//
//  LoginPage.swift
//  TerminalPrototype
//
//  Created by Matthew Merino on 2/23/25.
//

import SwiftUI

struct LoginPage: View {
    @State private var username: String = ""
    @State private var password: String = ""
    @State private var isLoggedIn: Bool = false
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Login")
                .font(.title)
                .foregroundStyle(.white)
                .padding(.bottom, 20)
            
            TextField("Username or Email", text: $username)
                .padding()
                .background(Color.black.opacity(0.0)) // Already transparent
                .foregroundStyle(.white)
                .border(Color.white, width: 1)
                .cornerRadius(8)
                .padding(.horizontal)
                .submitLabel(.next)
            
            SecureField("Password", text: $password)
                .padding()
                .background(Color.black.opacity(0.0)) // Already transparent
                .foregroundStyle(.white)
                .border(Color.white, width: 1)
                .cornerRadius(8)
                .padding(.horizontal)
                .submitLabel(.go)
            
            Button(action: {
                print("Login attempted with username: \(username), password: \(password)")
                isLoggedIn = true
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
        .background(Color.clear) // Explicitly make the entire view's background transparent
        .fullScreenCover(isPresented: $isLoggedIn) {
            DashboardPage()
        }
    }
}

#Preview {
    LoginPage()
}
