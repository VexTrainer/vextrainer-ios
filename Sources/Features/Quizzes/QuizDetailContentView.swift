//
//  QuizDetailContentView.swift
//  VexTrainer
//
//  The body of the quiz detail page. Start Quiz button calls the API to
//  create an attempt, then `.navigationDestination(item:)` pushes the
//  QuizSessionView when the response arrives.
//

import SwiftUI

struct QuizDetailContentView: View {
    let env: AppEnvironment
    let quiz: QuizSummary
    let categoryName: String

    @State private var vm: QuizDetailViewModel
    @Environment(\.appNavigationPath) private var navPath

    init(env: AppEnvironment, quiz: QuizSummary, categoryName: String) {
        self.env = env
        self.quiz = quiz
        self.categoryName = categoryName
        _vm = State(initialValue: QuizDetailViewModel(
            quizId: quiz.quizId,
            service: env.quizService
        ))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                infoCard
                statisticsCard
                if let msg = vm.error {
                    InlineErrorBanner(message: msg)
                }
                startButton
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 32)
        }
        // Observe the start-quiz result and push onto the nav path. We use
        // path append (not navigationDestination(item:)) so that completion
        // can replace the session with results via removeLast + append,
        // and back from results pops cleanly to this screen.
        .onChange(of: vm.startedAttempt) { _, newValue in
            if let attempt = newValue {
                navPath.wrappedValue.append(QuizRoute.quizSession(attempt: attempt))
                vm.startedAttempt = nil  // clear so re-tap works
            }
        }
    }

    // MARK: - Info card

    private var infoCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(quiz.quizTitle)
                .font(.title3.weight(.bold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, alignment: .leading)

            infoRow(icon: "folder.fill", text: categoryName, tint: Color.vexCyan)
            infoRow(
                icon: "questionmark.circle.fill",
                text: "\(quiz.totalQuestions) " +
                      (quiz.totalQuestions == 1 ? "question" : "questions"),
                tint: Color.vexCyan
            )
            if let passing = quiz.passingScore, passing > 0 {
                infoRow(
                    icon: "target",
                    text: "Passing score: \(Int(passing.rounded()))%",
                    tint: Color.vexGreen
                )
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(.white.opacity(0.1), lineWidth: 1)
        )
    }

    private func infoRow(icon: String, text: String, tint: Color) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(tint)
                .frame(width: 16)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.85))
                .lineLimit(2)
                .multilineTextAlignment(.leading)
        }
    }

    // MARK: - Your Statistics

    private var statisticsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Your Statistics")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white.opacity(0.7))

            HStack(spacing: 0) {
                statisticTile(
                    label: quiz.userAttempts == 1 ? "attempt" : "attempts",
                    value: "\(quiz.userAttempts)"
                )
                Divider().frame(height: 36).background(.white.opacity(0.1))
                statisticTile(label: "Best", value: bestScoreDisplay)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(.white.opacity(0.1), lineWidth: 1)
        )
    }

    private var bestScoreDisplay: String {
        guard quiz.userAttempts > 0, let best = quiz.userBestScore else { return "—" }
        return "\(Int(best.rounded()))%"
    }

    private func statisticTile(label: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2.weight(.bold))
                .foregroundStyle(.white)
                .monospacedDigit()
            Text(label)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.5))
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Start CTA

    private var startButton: some View {
        PrimaryButton(
            quiz.userAttempts > 0 ? "Retake Quiz" : "Start Quiz",
            isLoading: vm.isStarting,
            isEnabled: !vm.isStarting,
            style: .filled
        ) {
            Task { await vm.startQuiz() }
        }
        .padding(.top, 4)
    }
}
