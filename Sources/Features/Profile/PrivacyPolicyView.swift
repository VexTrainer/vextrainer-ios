//
//  PrivacyPolicyView.swift
//  VexTrainer
//

import SwiftUI

struct PrivacyPolicyView: View {

    @Environment(\.appNavigationPath) private var navPath
    let onContactLinkTap: (() -> Void)?

    /// `onContactLinkTap` overrides the default behavior of pushing the
    /// in-app Contact Us screen when the privacy markdown's "Contact us"
    /// link is tapped. Used by the pre-login AuthFlow to substitute a
    /// `mailto:` action (no JWT, can't POST /Contact). When nil, falls
    /// back to the authenticated default — push ProfileRoute.contactUs.
    init(onContactLinkTap: (() -> Void)? = nil) {
        self.onContactLinkTap = onContactLinkTap
    }

    private var privacyURL: URL {
        AppConfig.contentBaseURL.appendingPathComponent("privacy.md")
    }

    var body: some View {
        MarkdownContentView(
            title: "Privacy Policy",
            contentURL: privacyURL,
            onContactLinkTap: contactHandler
        )
    }

    private var contactHandler: () -> Void {
        if let onContactLinkTap {
            return onContactLinkTap
        }
        return { navPath.wrappedValue.append(ProfileRoute.contactUs) }
    }
}
