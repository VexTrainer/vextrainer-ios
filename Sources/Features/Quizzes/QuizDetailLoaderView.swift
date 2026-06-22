//
//  QuizDetailLoaderView.swift
//  VexTrainer
//
//  Pushed when entering the quiz detail screen with only a quizId in
//  hand (cross-tab navigation from the Activity Report). Fetches the
//  full quiz detail from /Quiz/quizzes/{id}, then renders the same
//  QuizDetailContentView that the in-tab navigation path uses.
//

import SwiftUI

struct QuizDetailLoaderView: View {
    let env: AppEnvironment
    let quizId: Int

    @State private var phase: Phase = .loading

    enum Phase {
        case loading
        case loaded(quiz: QuizSummary, categoryName: String)
        case failed(message: String)
    }

    var body: some View {
        ZStack {
            Color.vexNavy.ignoresSafeArea()
            content
        }
        .navigationTitle(navTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbarBackground(Color.vexNavy, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .task { await load() }
    }

    private var navTitle: String {
        switch phase {
        case .loaded(let quiz, _): return quiz.quizTitle
        default: return ""
        }
    }

    @ViewBuilder
    private var content: some View {
        switch phase {
        case .loading:
            LoadingStateView()
        case .loaded(let quiz, let categoryName):
            QuizDetailContentView(env: env, quiz: quiz, categoryName: categoryName)
        case .failed(let message):
            ErrorStateView(message: message) {
                await load()
            }
        }
    }

    private func load() async {
        phase = .loading
        do {
            let detail = try await env.quizService.fetchQuizDetail(quizId: quizId)
            phase = .loaded(quiz: detail.asSummary, categoryName: detail.categoryName)
        } catch let apiError as APIError {
            phase = .failed(message: apiError.localizedDescription)
        } catch {
            phase = .failed(message: error.localizedDescription)
        }
    }
}
