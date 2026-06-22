//
//  QuizListView.swift
//  VexTrainer
//

import SwiftUI

struct QuizListView: View {
    @State private var vm: QuizListViewModel
    let env: AppEnvironment
    let categoryName: String

    init(env: AppEnvironment, categoryId: Int, categoryName: String) {
        _vm = State(initialValue: QuizListViewModel(service: env.quizService, categoryId: categoryId))
        self.env = env
        self.categoryName = categoryName
    }

    var body: some View {
        ZStack {
            Color.vexNavy.ignoresSafeArea()
            content
        }
        .navigationTitle(categoryName)
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
            LoadingStateView()
        case .failed(let message):
            ErrorStateView(message: message) {
                await vm.refresh()
            }
        case .loaded(let quizzes):
            loaded(quizzes)
        }
    }

    @ViewBuilder
    private func loaded(_ quizzes: [QuizSummary]) -> some View {
        if quizzes.isEmpty {
            emptyState
        } else if quizzes.count == 1 {
            // Auto-promote: skip the list-of-one and show the detail content
            // directly. Subcategory name stays as the nav title.
            QuizDetailContentView(env: env, quiz: quizzes[0], categoryName: categoryName)
        } else {
            quizListContent(quizzes)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "questionmark.app.dashed")
                .font(.system(size: 44))
                .foregroundStyle(.white.opacity(0.4))
            Text("No quizzes here yet")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white.opacity(0.7))
            Text("Quizzes for this lesson will appear once they're published.")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.5))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func quizListContent(_ quizzes: [QuizSummary]) -> some View {
        ScrollView {
            VStack(spacing: 12) {
                ForEach(quizzes) { quiz in
                    QuizCard(quiz: quiz, categoryName: categoryName)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
        .refreshable { await vm.refresh() }
    }
}
