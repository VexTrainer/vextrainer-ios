//
//  ChoiceQuestionView.swift
//  VexTrainer
//
//  Renders single-answer, multi-answer, and true/false questions. They all
//  share the same UI primitive (a list of AnswerOptionButtons) — only the
//  selection model and post-submit reveal differs, which is handled by the
//  view model + state resolver.
//

import SwiftUI

private let OPTION_LABELS = ["A", "B", "C", "D", "E", "F", "G", "H"]

struct ChoiceQuestionView: View {
    let question: QuizQuestion
    let selectedAnswerIds: [Int]
    let isRevealed: Bool
    let answerResult: SubmitAnswerResponse?
    let onSelect: (Int) -> Void

    var body: some View {
        VStack(spacing: 10) {
            ForEach(Array(question.answers.enumerated()), id: \.element.id) { idx, answer in
                AnswerOptionButton(
                    label: OPTION_LABELS[safe: idx] ?? "\(idx + 1)",
                    text: answer.answerText,
                    imageUrl: answer.answerImagePath,
                    state: resolveState(for: answer),
                    enabled: !isRevealed,
                    action: { onSelect(answer.answerId) }
                )
            }
        }
    }

    private func resolveState(for answer: QuizAnswer) -> AnswerOptionState {
        if !isRevealed {
            return selectedAnswerIds.contains(answer.answerId) ? .selected : .default
        }
        let wasSelected = selectedAnswerIds.contains(answer.answerId)
        let correctIds = CorrectAnswerParser.extractAnswerIds(from: answerResult?.correctAnswerJson)
        let apiSaysCorrect = answerResult?.isCorrect == true

        if !correctIds.isEmpty {
            let isCorrect = correctIds.contains(answer.answerId)
            switch (isCorrect, wasSelected) {
            case (true, true):   return .correct
            case (true, false):  return .missed
            case (false, true):  return .incorrect
            case (false, false): return .default
            }
        }
        // Fallback (fill-in-blank etc — no parseable IDs): trust the API flag.
        if wasSelected { return apiSaysCorrect ? .correct : .incorrect }
        return .default
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
