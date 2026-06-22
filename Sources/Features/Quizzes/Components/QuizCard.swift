//
//  QuizCard.swift
//  VexTrainer
//

import SwiftUI

struct QuizCard: View {
    let quiz: QuizSummary
    let categoryName: String

    var body: some View {
        NavigationLink(value: QuizRoute.quizDetail(quiz: quiz, categoryName: categoryName)) {
            HStack(spacing: 14) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(quiz.quizTitle)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)

                    HStack(spacing: 6) {
                        metadataPill(
                            icon: "questionmark.circle",
                            text: "\(quiz.totalQuestions) " +
                                  (quiz.totalQuestions == 1 ? "question" : "questions")
                        )
                        if quiz.userAttempts > 0, let best = quiz.userBestScore {
                            metadataPill(
                                icon: "star.fill",
                                text: "\(Int(best.rounded()))%",
                                tint: Color.vexOrange
                            )
                        }
                    }
                }

                Spacer()

                if quiz.isCompleted {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color.vexGreen)
                } else {
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.3))
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(.white.opacity(0.1), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private func metadataPill(icon: String, text: String, tint: Color = Color.vexCyan) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon).font(.caption2)
            Text(text).font(.caption2.weight(.medium))
        }
        .foregroundStyle(tint)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(tint.opacity(0.1))
        .clipShape(Capsule())
    }
}
