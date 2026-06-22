//
//  QuizResultsView.swift
//  VexTrainer
//
//  Shown after a quiz is completed. Hero score banner + per-question
//  list. Uses the completion summary (passed in from the session view)
//  for an immediate render, then fetches the full results.
//

import SwiftUI
import MarkdownUI

struct QuizResultsView: View {
    let env: AppEnvironment
    let attemptId: Int
    /// Optional eager render of the score banner using the completion
    /// response data. The full per-question detail still needs to fetch.
    let completionSummary: CompleteQuizResponse?

    @State private var vm: QuizResultsViewModel

    init(env: AppEnvironment, attemptId: Int, completionSummary: CompleteQuizResponse? = nil) {
        self.env = env
        self.attemptId = attemptId
        self.completionSummary = completionSummary
        _vm = State(initialValue: QuizResultsViewModel(
            attemptId: attemptId,
            service: env.quizService
        ))
    }

    var body: some View {
        ZStack {
            Color.vexNavy.ignoresSafeArea()
            content
        }
        .navigationTitle("Results")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbarBackground(Color.vexNavy, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .task { await vm.loadIfNeeded() }
    }

    @ViewBuilder
    private var content: some View {
        switch vm.state {
        case .idle, .loading:
            // If we have the completion summary, render it immediately and
            // let the questions list arrive in a moment.
            if let s = completionSummary {
                ScrollView {
                    VStack(spacing: 18) {
                        scoreBanner(
                            score: s.finalScore,
                            correct: s.correctAnswers,
                            total: s.totalQuestions,
                            passed: s.passed,
                            passingScore: s.passingScore
                        )
                        LoadingStateView(message: "Loading question details…")
                            .frame(minHeight: 200)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    .padding(.bottom, 32)
                }
            } else {
                LoadingStateView()
            }
        case .failed(let message):
            ErrorStateView(message: message) {
                await vm.refresh()
            }
        case .loaded(let results):
            loaded(results)
        }
    }

    private func loaded(_ results: QuizResults) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                scoreBanner(
                    score: results.summary.score ?? 0,
                    correct: results.summary.correctAnswers,
                    total: results.summary.totalQuestions,
                    passed: results.summary.passed,
                    passingScore: results.summary.passingScore
                )
                Text("Question by question")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.7))
                    .padding(.top, 4)
                ForEach(results.questions) { q in
                    QuestionResultCard(result: q)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 32)
        }
    }

    // MARK: - Hero score banner

    private func scoreBanner(score: Double, correct: Int, total: Int,
                             passed: Bool, passingScore: Double?) -> some View {
        let tint = passed ? Color.vexGreen : Color.vexOrange
        return VStack(spacing: 6) {
            Text("\(Int(score.rounded()))%")
                .font(.system(size: 56, weight: .bold))
                .foregroundStyle(tint)
                .monospacedDigit()
            Text("\(correct) of \(total) correct")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.7))
            if let ps = passingScore, ps > 0 {
                HStack(spacing: 6) {
                    Image(systemName: passed ? "checkmark.seal.fill" : "exclamationmark.triangle.fill")
                        .font(.caption)
                    Text(passed
                         ? "Passed (need \(Int(ps.rounded()))%)"
                         : "Below passing (\(Int(ps.rounded()))%)")
                        .font(.footnote.weight(.semibold))
                }
                .foregroundStyle(tint)
                .padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(tint.opacity(0.10))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(tint.opacity(0.3), lineWidth: 1)
        )
    }

}

// MARK: - Per-question card (collapsible)

/// Per-question card on the results page. Collapsed by default; tap the
/// header to expand and reveal the explanation. Each card owns its own
/// expansion state.
private struct QuestionResultCard: View {
    let result: QuestionResult

    @State private var isExpanded: Bool = false

    private var statusTint: Color {
        result.isCorrect ? Color.vexGreen : Color(red: 1, green: 0.5, blue: 0.5)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            if isExpanded {
                expandedContent
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(.white.opacity(0.1), lineWidth: 1)
        )
    }

    // MARK: - Header (tap target)

    private var header: some View {
        Button {
            withAnimation(.easeOut(duration: 0.22)) {
                isExpanded.toggle()
            }
        } label: {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: result.isCorrect ? "checkmark.circle.fill"
                                                  : "xmark.circle.fill")
                    .foregroundStyle(statusTint)
                    .padding(.top, 2)
                questionTextView
                    .frame(maxWidth: .infinity, alignment: .leading)
                Image(systemName: "chevron.down")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.5))
                    .rotationEffect(.degrees(isExpanded ? 180 : 0))
                    .padding(.top, 4)
            }
            .padding(14)
            // Make the whole padded area tappable, not just text/chevron.
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    /// Question text rendered as markdown (questions may contain `code`,
    /// **bold**, etc.).
    private var questionTextView: some View {
        Text(parseMarkdown(result.questionText))
            .font(.subheadline)
            .foregroundStyle(.white)
            .multilineTextAlignment(.leading)
    }

    // MARK: - Expanded content

    @ViewBuilder
    private var expandedContent: some View {
        Divider().background(.white.opacity(0.1))
        VStack(alignment: .leading, spacing: 12) {
            QuizImageView(urlString: result.questionImagePath, maxHeight: 220)
            if let explanation = result.explanation, !explanation.isEmpty {
                Markdown(explanation)
                    .markdownTheme(.vexTrainer)
                    .markdownCodeSyntaxHighlighter(.vexTrainer)
            } else {
                Text("No explanation provided.")
                    .font(.footnote)
                    .foregroundStyle(.white.opacity(0.5))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
    }

    private func parseMarkdown(_ string: String) -> AttributedString {
        if let parsed = try? AttributedString(
            markdown: string,
            options: .init(interpretedSyntax: .full)
        ) {
            return parsed
        }
        return AttributedString(string)
    }
}
