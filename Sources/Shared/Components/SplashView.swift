//
//  SplashView.swift
//  VexTrainer
//
//  Shown only during the brief AppRouter.checking phase at launch while we read
//  the keychain and validate the saved session. Crossfades to AuthFlow or
//  MainShellView when the route resolves.
//

import SwiftUI

struct SplashView: View {
    var body: some View {
        ZStack {
            Color.vexNavy.ignoresSafeArea()

            VStack(spacing: 20) {
                Image("LogoVexTrainer")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 120, height: 120)
                    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))

                ProgressView()
                    .progressViewStyle(.circular)
                    .tint(.white.opacity(0.5))
            }
        }
    }
}
