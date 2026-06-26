//
//  MarkdownContentView.swift
//  VexTrainer
//
//  Shared "fetch a markdown URL, render it themed, show loading/error
//  state" screen used by AboutView and PrivacyPolicyView.
//
//  Link handling mirrors Android (see InfoScreens.kt's linkResolver):
//  any link whose URL contains "contact" (case-insensitive) is treated
//  as a request for the in-app Contact Us screen and invokes
//  `onContactLinkTap`. Every other link falls through to the system
//  openURL action, which opens it in Safari.
//

import SwiftUI
import MarkdownUI

struct MarkdownContentView<Footer: View>: View {
    let title: String
    let contentURL: URL
    let onContactLinkTap: (() -> Void)?
    @ViewBuilder let footer: () -> Footer

    @State private var markdown: String?
    @State private var error: String?

    init(
        title: String,
        contentURL: URL,
        onContactLinkTap: (() -> Void)? = nil,
        @ViewBuilder footer: @escaping () -> Footer = { EmptyView() }
    ) {
        self.title = title
        self.contentURL = contentURL
        self.onContactLinkTap = onContactLinkTap
        self.footer = footer
    }

    var body: some View {
        ZStack {
            Color.vexNavy.ignoresSafeArea()
            content
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbarBackground(Color.vexNavy, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .environment(\.openURL, linkAction)
        .task { await loadIfNeeded() }
    }

    /// SwiftUI's link-tap dispatch hook. MarkdownUI (and Text's link
    /// handling) call this when a rendered link is tapped. We pick off
    /// "contact" URLs and forward to the in-app callback; everything
    /// else returns `.systemAction` to open in Safari as usual.
    private var linkAction: OpenURLAction {
        OpenURLAction { url in
            if let handler = onContactLinkTap,
               url.absoluteString.localizedCaseInsensitiveContains("contact") {
                handler()
                return .handled
            }
            return .systemAction
        }
    }

    @ViewBuilder
    private var content: some View {
        if let markdown {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Markdown(markdown)
                        .markdownTheme(.vexTrainer)
                        .markdownCodeSyntaxHighlighter(.vexTrainer)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    footer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 32)
            }
        } else if let error {
            ErrorStateView(message: error) {
                await load()
            }
        } else {
            LoadingStateView()
        }
    }

    private func loadIfNeeded() async {
        guard markdown == nil, error == nil else { return }
        await load()
    }

    private func load() async {
        error = nil
        do {
            let text = try await ContentMarkdownLoader.fetch(url: contentURL)
            markdown = text
        } catch let apiError as APIError {
            error = apiError.localizedDescription
        } catch {
            self.error = error.localizedDescription
        }
    }
}
