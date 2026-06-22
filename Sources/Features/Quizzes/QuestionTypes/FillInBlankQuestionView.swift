//
//  FillInBlankQuestionView.swift
//  VexTrainer
//

import SwiftUI

struct FillInBlankQuestionView: View {
    let text: String
    let isRevealed: Bool
    let answerResult: SubmitAnswerResponse?
    let onTextChanged: (String) -> Void
    let onSubmit: () -> Void

    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            TextField("Type your answer", text: Binding(
                get: { text },
                set: { onTextChanged($0) }
            ))
            .focused($isFocused)
            .submitLabel(.go)
            .onSubmit {
                if !text.trimmingCharacters(in: .whitespaces).isEmpty {
                    onSubmit()
                }
            }
            .disabled(isRevealed)
            .vexFieldStyle()

            if isRevealed, let result = answerResult {
                resultRow(for: result)
            }
        }
        .onAppear {
            // Focusing inside .onAppear synchronously sometimes loses the
            // focus assignment because the TextField isn't fully laid out
            // when the run-loop tick fires. A tiny delay lets SwiftUI
            // finish first, then @FocusState takes reliably.
            if !isRevealed {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    isFocused = true
                }
            }
        }
        .onChange(of: isRevealed) { _, revealed in
            if revealed { isFocused = false }
        }
    }

    @ViewBuilder
    private func resultRow(for result: SubmitAnswerResponse) -> some View {
        let isCorrect = result.isCorrect
        HStack(spacing: 8) {
            Image(systemName: isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundStyle(isCorrect ? Color.vexGreen
                                           : Color(red: 1, green: 0.5, blue: 0.5))
            Text(isCorrect ? "Your answer was correct." : "Your answer was incorrect.")
                .font(.footnote.weight(.medium))
                .foregroundStyle(.white.opacity(0.85))
        }
    }
}
