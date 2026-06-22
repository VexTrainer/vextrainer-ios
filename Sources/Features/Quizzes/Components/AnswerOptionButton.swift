//
//  AnswerOptionButton.swift
//  VexTrainer
//
//  A tappable answer option, with state-driven coloring:
//   - default      (not selected, not revealed)
//   - selected     (user picked it, not yet submitted)
//   - correct      (revealed, user picked it, it's right)
//   - incorrect    (revealed, user picked it, it's wrong)
//   - missed       (revealed, user didn't pick it, it WAS right)
//
//  Text rendering uses AttributedString(markdown:.full) so inline
//  backticks, **bold**, *italic*, and links style correctly while the
//  outer Text's .foregroundStyle still propagates — that's how the
//  state-coloured text (green for correct, red for incorrect, …)
//  keeps working. Multi-line fenced code blocks aren't expected in
//  answer options; if they appear, they render as raw markdown text
//  inside the same bubble.
//
//  When the server provides an answerImagePath, the image renders
//  below the text inside the option, capped at 140pt tall.
//

import SwiftUI

enum AnswerOptionState {
    case `default`
    case selected
    case correct
    case incorrect
    case missed
}

struct AnswerOptionButton: View {
    let label: String        // "A", "B", "C", ...
    let text: String
    let imageUrl: String?
    let state: AnswerOptionState
    let enabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(alignment: .top, spacing: 12) {
                labelBubble
                VStack(alignment: .leading, spacing: 10) {
                    Text(attributedText)
                        .font(.subheadline)
                        .foregroundStyle(textColor)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    QuizImageView(urlString: imageUrl, maxHeight: 140)
                }
                if let trailing = trailingIcon {
                    Image(systemName: trailing)
                        .foregroundStyle(trailingTint)
                        .padding(.top, 2)
                }
            }
            .padding(14)
            .background(background)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(borderColor, lineWidth: 1.5)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
        .opacity(enabled ? 1 : 0.95)
    }

    /// Markdown-parsed answer text. `.full` lets bold/italic/inline-code
    /// span paragraph breaks. Falls back to plain text on parse error.
    private var attributedText: AttributedString {
        if let parsed = try? AttributedString(
            markdown: text,
            options: .init(interpretedSyntax: .full)
        ) {
            return parsed
        }
        return AttributedString(text)
    }

    private var labelBubble: some View {
        ZStack {
            Circle()
                .strokeBorder(borderColor, lineWidth: 1.5)
                .background(Circle().fill(labelBackground))
                .frame(width: 30, height: 30)
            Text(label)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(labelTextColor)
        }
    }

    // MARK: - State-driven colors

    private var background: Color {
        switch state {
        case .default:   return Color.white.opacity(0.05)
        case .selected:  return Color.vexOrange.opacity(0.12)
        case .correct:   return Color.vexGreen.opacity(0.18)
        case .missed:    return Color.vexGreen.opacity(0.08)
        case .incorrect: return Color(red: 0.7, green: 0.18, blue: 0.18).opacity(0.18)
        }
    }

    private var borderColor: Color {
        switch state {
        case .default:   return .white.opacity(0.15)
        case .selected:  return Color.vexOrange
        case .correct:   return Color.vexGreen
        case .missed:    return Color.vexGreen.opacity(0.5)
        case .incorrect: return Color(red: 0.95, green: 0.35, blue: 0.35)
        }
    }

    private var textColor: Color {
        switch state {
        case .default:   return .white.opacity(0.9)
        case .selected:  return .white
        case .correct, .missed:  return Color.vexGreen
        case .incorrect: return Color(red: 1, green: 0.5, blue: 0.5)
        }
    }

    private var labelBackground: Color {
        switch state {
        case .selected:  return Color.vexOrange.opacity(0.25)
        case .correct:   return Color.vexGreen.opacity(0.2)
        case .incorrect: return Color(red: 0.7, green: 0.2, blue: 0.2).opacity(0.25)
        default:         return .clear
        }
    }

    private var labelTextColor: Color {
        switch state {
        case .selected:  return Color.vexOrange
        case .correct, .missed:  return Color.vexGreen
        case .incorrect: return Color(red: 1, green: 0.5, blue: 0.5)
        default:         return .white.opacity(0.7)
        }
    }

    private var trailingIcon: String? {
        switch state {
        case .correct:   return "checkmark.circle.fill"
        case .incorrect: return "xmark.circle.fill"
        case .missed:    return "checkmark.circle"
        default:         return nil
        }
    }

    private var trailingTint: Color {
        switch state {
        case .correct, .missed:  return Color.vexGreen
        case .incorrect: return Color(red: 1, green: 0.5, blue: 0.5)
        default:         return .clear
        }
    }
}
