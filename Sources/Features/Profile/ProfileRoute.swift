//
//  ProfileRoute.swift
//  VexTrainer
//
//  Navigation routes within the Profile tab. Donate and Delete-Account
//  are NOT routes — they open in the system browser directly from the
//  menu tap. Only the three in-app destinations are listed here.
//

import Foundation
import SwiftUI

enum ProfileRoute: Hashable {
    case about
    case contactUs
    case privacy
    case deleteAccount
}

enum ProfileRouter {
    @ViewBuilder
    static func destination(for route: ProfileRoute, env: AppEnvironment, session: AuthSession) -> some View {
        switch route {
        case .about:
            AboutView()
        case .contactUs:
            ContactUsView(env: env, session: session)
        case .privacy:
            PrivacyPolicyView()
        case .deleteAccount:
            DeleteAccountView(env: env, session: session)
        }
    }
}
