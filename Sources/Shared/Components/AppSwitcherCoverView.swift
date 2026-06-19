//
//  AppSwitcherCoverView.swift
//  VexTrainer
//
//  Covers the current screen with a branded placeholder while the app
//  is in the background. iOS takes a snapshot of the topmost view
//  during scenePhase transitions to populate the App Switcher
//  thumbnail; with this overlay in place, anything sensitive (a
//  half-typed support message, a personal email on the Profile tab,
//  partially-answered quiz, etc.) is hidden behind a clean splash.
//
//  Intentionally minimal — just the logo on navy. The visual matches
//  the launch screen so the transition from background → foreground
//  feels continuous with the first-launch experience.
//

import SwiftUI

struct AppSwitcherCoverView: View {
    var body: some View {
        ZStack {
            Color.vexNavy.ignoresSafeArea()
            Image("LogoVexTrainer")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 120, height: 120)
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        }
    }
}
