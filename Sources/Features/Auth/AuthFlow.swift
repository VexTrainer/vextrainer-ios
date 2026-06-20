//
//  AuthFlow.swift
//  VexTrainer
//
//  NavigationStack rooted at Login, with Register, Forgot Password,
//  pre-login About, and pre-login Privacy as pushable destinations.
//  The whole stack is destroyed when the user successfully signs in
//  (RootView switches branches).
//
//  This file also owns the pre-login Contact fallback. Because the
//  user has no JWT, we can't POST /Contact — instead we open a
//  mailto: composer to AppConfig.supportEmail. When no mail app can
//  handle that URL (iOS Simulator, deleted Mail.app, or no email
//  accounts configured), we surface an alert with the email address
//  and a Copy button so the user can complete the action manually.
//

import SwiftUI
import UIKit

enum AuthRoute: Hashable {
    case register(prefilledEmail: String)
    case forgotPassword(prefilledEmail: String)
    /// Pre-login About screen — same markdown content as the authenticated
    /// version, but the "Contact us" link inside falls back to mailto since
    /// the user has no JWT to hit POST /Contact.
    case about
    /// Pre-login Privacy Policy — same fallback semantics as `.about`.
    case privacy
}

struct AuthFlow: View {

    @Environment(AppEnvironment.self) private var env
    @Environment(AppRouter.self) private var router

    @State private var path = NavigationPath()
    @State private var showMailFallback = false

    var body: some View {
        NavigationStack(path: $path) {
            LoginView(
                env: env,
                router: router,
                path: $path,
                onContactTap: openSupportMail
            )
            .navigationDestination(for: AuthRoute.self) { route in
                switch route {
                case .register(let email):
                    RegisterView(env: env, path: $path, prefilledEmail: email)
                case .forgotPassword(let email):
                    ForgotPasswordView(env: env, path: $path, prefilledEmail: email)
                case .about:
                    AboutView(onContactLinkTap: openSupportMail)
                case .privacy:
                    PrivacyPolicyView(onContactLinkTap: openSupportMail)
                }
            }
        }
        .tint(Color.vexOrange)  // back button + nav-bar accents
        .alert("Email Us", isPresented: $showMailFallback) {
            Button("Copy Address") {
                UIPasteboard.general.string = AppConfig.supportEmail
            }
            Button("OK", role: .cancel) { }
        } message: {
            Text("No mail app is set up on this device. Please email us at \(AppConfig.supportEmail).")
        }
    }

    /// Pre-login Contact handler. Used by both the LoginView's Contact
    /// text-link AND the "Contact us" link inside about.md / privacy.md
    /// when those screens are reached from AuthFlow.
    ///
    /// We deliberately use UIApplication.shared.open here rather than
    /// the SwiftUI @Environment(\.openURL) action, because we need the
    /// completion handler — SwiftUI's OpenURLAction doesn't expose one.
    /// `accepted == false` means no installed app is registered for the
    /// scheme (Simulator, deleted Mail.app, etc.), so we surface the
    /// fallback alert instead of failing silently.
    private func openSupportMail() {
        UIApplication.shared.open(AppConfig.supportMailtoURL, options: [:]) { accepted in
            if !accepted {
                showMailFallback = true
            }
        }
    }
}
