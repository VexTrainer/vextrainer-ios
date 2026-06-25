//
//  VexCodeHighlighter.swift
//  VexTrainer
//
//  Adapter that plugs Highlightr (highlight.js for Swift) into swift-markdown-ui's
//  CodeSyntaxHighlighter protocol. Used for the C++ code blocks in PROS curriculum
//  topics — highlightCode(_:language:) is called by MarkdownUI for each fenced block.
//

import SwiftUI
import MarkdownUI
import Highlightr

struct VexCodeHighlighter: CodeSyntaxHighlighter {

    private let highlightr: Highlightr?

    init(theme: String = "atom-one-dark") {
        self.highlightr = Highlightr()
        self.highlightr?.setTheme(to: theme)
    }

    func highlightCode(_ content: String, language: String?) -> Text {
        // Fallback to plain text if Highlightr couldn't initialize or the language
        // isn't recognized — better than crashing on an obscure tag.
        guard let highlightr else { return plain(content) }
        let lang = language ?? "plaintext"
        guard let attributed = highlightr.highlight(content, as: lang, fastRender: true) else {
            return plain(content)
        }
        return Text(AttributedString(attributed))
    }

    private func plain(_ content: String) -> Text {
        Text(content)
            .foregroundColor(.white.opacity(0.9))
            .font(.system(.callout, design: .monospaced))
    }
}

extension CodeSyntaxHighlighter where Self == VexCodeHighlighter {
    static var vexTrainer: VexCodeHighlighter { VexCodeHighlighter() }
}
