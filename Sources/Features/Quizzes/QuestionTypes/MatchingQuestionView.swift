//
//  MatchingQuestionView.swift
//  VexTrainer
//
//  Two columns of tappable items (L = left, R = right). Tap an L to select
//  it; tap an R to form a pair. Tap a paired item to unpair. Colored pair
//  index matches Android's PAIR_COLORS sequence for visual matching.
//

import SwiftUI

struct MatchingQuestionView: View {
    let answers: [QuizAnswer]
    let matchingPairs: [(leftId: Int, rightId: Int)]
    let selectedLeftId: Int?
    let isRevealed: Bool
    let correctRightIds: [Int]   // parsed from correctAnswerJson, used post-reveal
    let onTap: (Int, String) -> Void
    let onReset: () -> Void

    private var leftItems: [QuizAnswer] {
        answers.filter { $0.matchSide == "L" }
    }
    private var rightItems: [QuizAnswer] {
        answers.filter { $0.matchSide == "R" }
    }
    private var pairedLeftIds: [Int] {
        matchingPairs.map { $0.leftId }
    }

    var body: some View {
        VStack(spacing: 12) {
            HStack(alignment: .top, spacing: 10) {
                leftColumn
                rightColumn
            }
            if !isRevealed {
                footerRow
            }
        }
    }

    // MARK: - Columns

    private var leftColumn: some View {
        VStack(alignment: .leading, spacing: 8) {
            columnHeader("Component")
            ForEach(leftItems) { answer in
                MatchingItemButton(
                    text: answer.answerText,
                    imageUrl: answer.answerImagePath,
                    style: styleFor(answer: answer, side: "L"),
                    enabled: !isRevealed,
                    action: { onTap(answer.answerId, "L") }
                )
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var rightColumn: some View {
        VStack(alignment: .leading, spacing: 8) {
            columnHeader("Purpose / match")
            ForEach(rightItems) { answer in
                MatchingItemButton(
                    text: answer.answerText,
                    imageUrl: answer.answerImagePath,
                    style: styleFor(answer: answer, side: "R"),
                    enabled: !isRevealed,
                    action: { onTap(answer.answerId, "R") }
                )
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func columnHeader(_ text: String) -> some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .foregroundStyle(.white.opacity(0.5))
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Footer (paired N of M + reset)

    private var footerRow: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Paired: \(matchingPairs.count) of \(leftItems.count)")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.white.opacity(0.6))
                if let leftId = selectedLeftId,
                   let item = leftItems.first(where: { $0.answerId == leftId }) {
                    Text("Selected: \(item.answerText)")
                        .font(.caption)
                        .foregroundStyle(Color.vexCyan)
                        .lineLimit(1)
                }
            }
            Spacer()
            if !matchingPairs.isEmpty {
                Button("Reset", role: .destructive, action: onReset)
                    .font(.caption.weight(.semibold))
                    .buttonStyle(.bordered)
                    .tint(Color.vexOrange)
            }
        }
    }

    // MARK: - Per-item style resolution

    private func styleFor(answer: QuizAnswer, side: String) -> MatchingItemStyle {
        if side == "L" {
            // Selected (in mid-tap) state
            if !isRevealed, selectedLeftId == answer.answerId,
               !pairedLeftIds.contains(answer.answerId) {
                return .selected
            }
            // Paired state
            if let pairIdx = pairedLeftIds.firstIndex(of: answer.answerId) {
                if isRevealed {
                    let rId = matchingPairs[pairIdx].rightId
                    return correctRightIds.contains(rId) ? .correct : .incorrect
                }
                return .paired(index: pairIdx)
            }
            return .default
        }

        // R side
        let pairedToL = matchingPairs.first(where: { $0.rightId == answer.answerId })?.leftId
        if let leftId = pairedToL, let pairIdx = pairedLeftIds.firstIndex(of: leftId) {
            if isRevealed {
                return correctRightIds.contains(answer.answerId) ? .correct : .incorrect
            }
            return .paired(index: pairIdx)
        }
        return .default
    }
}

// MARK: - Style enum & button view

enum MatchingItemStyle {
    case `default`
    case selected
    case paired(index: Int)
    case correct
    case incorrect
}

private struct MatchingItemButton: View {
    let text: String
    let imageUrl: String?
    let style: MatchingItemStyle
    let enabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Text(attributedText)
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(textColor)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                QuizImageView(urlString: imageUrl, maxHeight: 100)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 8)
            .background(background)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .strokeBorder(borderColor, lineWidth: 2)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
    }

    /// Markdown-parsed item label. `.full` covers inline backticks /
    /// **bold** / *italic*. Matching items are usually short phrases,
    /// so fenced code blocks aren't expected here either.
    private var attributedText: AttributedString {
        if let parsed = try? AttributedString(
            markdown: text,
            options: .init(interpretedSyntax: .full)
        ) {
            return parsed
        }
        return AttributedString(text)
    }

    private var pairColor: (bg: Color, border: Color)? {
        if case .paired(let idx) = style {
            return MatchingQuestionView.pairColors[idx % MatchingQuestionView.pairColors.count]
        }
        return nil
    }

    private var background: Color {
        switch style {
        case .default:   return Color.white.opacity(0.05)
        case .selected:  return Color.vexCyan.opacity(0.20)
        case .paired:    return pairColor?.bg ?? .clear
        case .correct:   return Color.vexGreen.opacity(0.18)
        case .incorrect: return Color(red: 0.7, green: 0.18, blue: 0.18).opacity(0.18)
        }
    }

    private var borderColor: Color {
        switch style {
        case .default:   return .white.opacity(0.15)
        case .selected:  return Color.vexCyan
        case .paired:    return pairColor?.border ?? .clear
        case .correct:   return Color.vexGreen
        case .incorrect: return Color(red: 1, green: 0.4, blue: 0.4)
        }
    }

    private var textColor: Color {
        switch style {
        case .default:   return .white.opacity(0.9)
        case .selected:  return Color.vexCyan
        case .paired:    return pairColor?.border ?? .white
        case .correct:   return Color.vexGreen
        case .incorrect: return Color(red: 1, green: 0.5, blue: 0.5)
        }
    }
}

// Expose the pair palette so MatchingItemButton (private struct in this file)
// can index into it.
extension MatchingQuestionView {
    static var pairColors: [(bg: Color, border: Color)] {
        [
            (Color(red: 0.30, green: 0.70, blue: 1.0).opacity(0.20),
             Color(red: 0.30, green: 0.70, blue: 1.0)),
            (Color(red: 0.74, green: 0.42, blue: 0.95).opacity(0.20),
             Color(red: 0.74, green: 0.42, blue: 0.95)),
            (Color.vexGreen.opacity(0.20), Color.vexGreen),
            (Color.vexOrange.opacity(0.20), Color.vexOrange),
            (Color(red: 1, green: 0.45, blue: 0.45).opacity(0.20),
             Color(red: 1, green: 0.45, blue: 0.45)),
        ]
    }
}
