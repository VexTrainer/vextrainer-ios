//
//  QuizSessionView.swift
//  VexTrainer
//
//  The active quiz player. On completion we REPLACE this view in the
//  navigation stack with QuizResultsView (path.removeLast + append),
//  so back from results goes straight to the quiz detail screen with
//  no "Submitting your quiz…" limbo state.
//

import SwiftUI
import UIKit
import MarkdownUI

struct QuizSessionView: View {
    let env: AppEnvironment
    let attempt: StartQuizResponse

    @State private var vm: QuizSessionViewModel
    @State private var showExitDialog = false
    @Environment(\.appNavigationPath) private var navPath

    init(env: AppEnvironment, attempt: StartQuizResponse) {
        self.env = env
        self.attempt = attempt
        _vm = State(initialValue: QuizSessionViewModel(
            attemptId: attempt.attemptId,
            service: env.quizService
        ))
    }

    var body: some View {
        ZStack {
            Color.vexNavy.ignoresSafeArea()
            content
        }
        .navigationTitle(navTitle)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(vm.phase != .error)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbarBackground(Color.vexNavy, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                if vm.phase != .error {
                    Button {
                        showExitDialog = true
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundStyle(.white.opacity(0.8))
                    }
                }
            }
        }
        .confirmationDialog(
            "Exit quiz?",
            isPresented: $showExitDialog,
            titleVisibility: .visible
        ) {
            Button("Exit", role: .destructive) {
                showExitDialog = false
                if !navPath.wrappedValue.isEmpty {
                    navPath.wrappedValue.removeLast()
                }
            }
            Button("Cancel", role: .cancel) { showExitDialog = false }
        } message: {
            Text("Your progress on this attempt will not be saved.")
        }
        // On completion: replace this session view with results in the
        // path so back from results goes directly to the detail screen
        // (no orphaned session-in-.completing state).
        .onChange(of: vm.completedResult) { _, newValue in
            if let result = newValue {
                if !navPath.wrappedValue.isEmpty {
                    navPath.wrappedValue.removeLast()
                }
                navPath.wrappedValue.append(QuizRoute.quizResults(
                    attemptId: result.attemptId,
                    completionSummary: result
                ))
                vm.completedResult = nil
            }
        }
        .task { await vm.loadIfNeeded() }
    }

    private var navTitle: String {
        guard vm.totalQuestions > 0 else { return "Quiz" }
        return "\(vm.progressDisplay) / \(vm.totalQuestions)"
    }

    // MARK: - Content state branching

    @ViewBuilder
    private var content: some View {
        switch vm.phase {
        case .loading:
            LoadingStateView(message: "Loading questions…")
        case .completing:
            LoadingStateView(message: "Submitting your quiz…")
        case .error:
            ErrorStateView(message: vm.error ?? "Something went wrong.") {
                await vm.retry()
            }
        case .questionDisplayed, .answerSelected, .submitting, .answerRevealed:
            if let q = vm.currentQuestion {
                playerBody(question: q)
            } else {
                LoadingStateView()
            }
        }
    }

    private func playerBody(question: QuizQuestion) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                QuizProgressBar(current: vm.progressDisplay, total: vm.totalQuestions)
                questionHint(for: question)
                questionCard(question: question)
                answerArea(question: question)
                if vm.phase == .answerRevealed, let result = vm.answerResult {
                    FeedbackCard(result: result)
                }
                actionButton(for: question)
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 32)
        }
    }

    // MARK: - Question card

    private func questionCard(question: QuizQuestion) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            QuizImageView(urlString: question.questionImagePath, maxHeight: 220)
            Markdown(question.questionText)
                .markdownTheme(.vexTrainer)
                .markdownCodeSyntaxHighlighter(.vexTrainer)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.vexCyan.opacity(0.10))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(Color.vexCyan.opacity(0.25), lineWidth: 1)
        )
    }

    @ViewBuilder
    private func questionHint(for question: QuizQuestion) -> some View {
        switch question.kind {
        case .multipleAnswer:
            hintRow("Select all that apply", icon: "checklist")
        case .matching:
            hintRow("Tap to pair items", icon: "arrow.left.arrow.right")
        case .fillInBlank:
            hintRow("Type your answer", icon: "character.cursor.ibeam")
        default:
            EmptyView()
        }
    }

    private func hintRow(_ text: String, icon: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
            Text(text)
                .font(.caption.weight(.semibold))
        }
        .foregroundStyle(Color.vexOrange)
    }

    // MARK: - Answer area (dispatches to type-specific view)

    @ViewBuilder
    private func answerArea(question: QuizQuestion) -> some View {
        let isRevealed = vm.phase == .answerRevealed
        switch question.kind {
        case .fillInBlank:
            FillInBlankQuestionView(
                text: vm.fillInBlankText,
                isRevealed: isRevealed,
                answerResult: vm.answerResult,
                onTextChanged: { vm.onFillInBlankTextChanged($0) },
                onSubmit: { Task { await vm.submitAnswer() } }
            )
        case .matching:
            MatchingQuestionView(
                answers: question.answers,
                matchingPairs: vm.matchingPairs,
                selectedLeftId: vm.selectedLeftId,
                isRevealed: isRevealed,
                correctRightIds: CorrectAnswerParser.extractAnswerIds(
                    from: vm.answerResult?.correctAnswerJson
                ),
                onTap: { vm.selectMatchingAnswer(answerId: $0, matchSide: $1) },
                onReset: { vm.resetMatchingPairs() }
            )
        default:
            ChoiceQuestionView(
                question: question,
                selectedAnswerIds: vm.selectedAnswerIds,
                isRevealed: isRevealed,
                answerResult: vm.answerResult,
                onSelect: { vm.selectAnswer($0) }
            )
        }
    }

    // MARK: - Action button (Submit / Next)

    private func actionButton(for question: QuizQuestion) -> some View {
        Group {
            if vm.phase == .answerRevealed {
                PrimaryButton(
                    vm.isLastQuestion ? "Finish Quiz" : "Next Question",
                    style: .filled
                ) {
                    Task { await vm.nextQuestion() }
                }
            } else {
                PrimaryButton(
                    "Submit",
                    isLoading: vm.phase == .submitting,
                    isEnabled: vm.canSubmit && vm.phase != .submitting,
                    style: .filled
                ) {
                    UIApplication.shared.sendAction(
                        #selector(UIResponder.resignFirstResponder),
                        to: nil, from: nil, for: nil
                    )
                    Task { await vm.submitAnswer() }
                }
            }
        }
        .padding(.top, 6)
    }
}
