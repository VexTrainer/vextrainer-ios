//
//  AboutView.swift
//  VexTrainer
//
//  Fetches about.md from the public content host and renders it. Adds
//  a "Visit our website" outlined button below the content as a CTA.
//

import SwiftUI

struct AboutView: View {

    @Environment(\.openURL) private var openURL
    @Environment(\.appNavigationPath) private var navPath
    let onContactLinkTap: (() -> Void)?

    /// See PrivacyPolicyView — same semantics. Pre-login AuthFlow
    /// passes a mailto handler; authenticated profile flow leaves
    /// this nil and uses the default in-app push.
    init(onContactLinkTap: (() -> Void)? = nil) {
        self.onContactLinkTap = onContactLinkTap
    }

    private var aboutURL: URL {
        AppConfig.contentBaseURL.appendingPathComponent("about.md")
    }

    private var version: String {
        let v = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
        let b = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String
        let short = v ?? "—"
        if let b, !b.isEmpty, b != short { return "v\(short) (\(b))" }
        return "v\(short)"
    }

    var body: some View {
        MarkdownContentView(
            title: "About Us",
            contentURL: aboutURL,
            onContactLinkTap: contactHandler
        ) {
            VStack(spacing: 12) {
                Divider().background(.white.opacity(0.1))
                Text(version)
                    .font(.footnote)
                    .foregroundStyle(.white.opacity(0.5))
                    .monospacedDigit()
                websiteButton
            }
            .padding(.top, 8)
        }
    }

    private var contactHandler: () -> Void {
        if let onContactLinkTap {
            return onContactLinkTap
        }
        return { navPath.wrappedValue.append(ProfileRoute.contactUs) }
    }

    private var websiteButton: some View {
        Button {
            openURL(AppConfig.websiteURL)
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "safari")
                Text(AppConfig.websiteURL.absoluteString)
                    .font(.subheadline.weight(.semibold))
                Image(systemName: "arrow.up.right")
                    .font(.caption.weight(.semibold))
            }
            .foregroundStyle(Color.vexCyan)
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity)
            .background(Color.vexCyan.opacity(0.10))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(Color.vexCyan.opacity(0.35), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}
