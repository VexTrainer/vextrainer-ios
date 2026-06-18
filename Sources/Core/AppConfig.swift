//
//  AppConfig.swift
//  VexTrainer
//
//  Production configuration constants. Committed to git. For local-only secrets
//  (e.g. test credentials), use DebugCredentials.swift which is gitignored.
//

import Foundation

enum AppConfig {
    /// Production API base URL.
    static let apiBaseURL = URL(string: "https://api.vextrainer.com")!

    /// Where markdown content (lessons, about, privacy) is hosted.
    /// Note: NO `api.` subdomain — content is served from the public web host,
    /// not the API host.
    static let contentBaseURL = URL(string: "https://vextrainer.com/content")!

    /// Marketing site root — used as the About screen's "Visit website" link.
    static let websiteURL = URL(string: "https://vextrainer.com")!

    /// Donate page — opens in the system browser from the Profile menu.
    /// Rich HTML, payment integrations, farmer-welfare context.
    static let donateURL = URL(string: "https://vextrainer.com/Donate")!

    /// Support inbox used by pre-login fallbacks (the sign-in screen's
    /// Contact link, and the Contact-us link inside privacy.md when
    /// rendered to an unauthenticated user). The in-app Contact Us
    /// form is the preferred channel — this is the escape hatch when
    /// the user isn't signed in and we can't POST /Contact (JWT-only).
    static let supportEmail = "support@vextrainer.com"

    /// `mailto:` URL pointing at supportEmail. Safe to pass to openURL —
    /// iOS opens the Mail composer with the address pre-filled.
    static var supportMailtoURL: URL {
        URL(string: "mailto:\(supportEmail)")!
    }
}
