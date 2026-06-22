//
//  FeedbackCard.swift
//  VexTrainer
//

import SwiftUI
import MarkdownUI

struct FeedbackCard: View {
    let result: SubmitAnswerResponse

    private var isCorrect: Bool { result.isCorrect }

    private var bg: Color {
        isCorrect ? Color.vexGreen.opacity(0.15) : Color(red: 0.7, green: 0.2, blue: 0.2).opacity(0.18)
    }
    private var tint: Color {
        isCorrect ? Color.vexGreen : Color(red: 1, green: 0.5, blue: 0.5)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundStyle(tint)
                Text(isCorrect ? "Correct" : "Incorrect")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(tint)
            }
            if let explanation = result.explanation, !explanation.isEmpty {
                explanationView(explanation)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(bg)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(tint.opacity(0.4), lineWidth: 1)
        )
    }

    /// Server explanations can contain inline markdown AND fenced code
    /// blocks (```cpp …```), which AttributedString(markdown:) renders
    /// as raw text. MarkdownUI handles both. The .vexTrainer theme
    /// gives us the same code styling used in lesson content.
    private func explanationView(_ markdown: String) -> some View {
        Markdown(markdown)
            .markdownTheme(.vexTrainer)
            .markdownCodeSyntaxHighlighter(.vexTrainer)
    }
}
