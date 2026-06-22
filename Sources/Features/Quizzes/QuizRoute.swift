//
//  QuizRoute.swift
//  VexTrainer
//

import Foundation
import SwiftUI

enum QuizRoute: Hashable {
    /// Subcategory tap from CategoryListView's inline disclosure.
    case quizList(categoryId: Int, categoryName: String)

    /// Quiz card tap from a multi-quiz QuizListView.
    case quizDetail(quiz: QuizSummary, categoryName: String)

    /// Cross-tab entry from the Activity Report — we only have the quizId,
    /// so QuizDetailLoaderView fetches the full record before rendering.
    case quizDetailFromId(quizId: Int)

    /// Paginated history of every quiz attempt this user has made.
    /// Pushed from the history-icon toolbar button on CategoryListView.
    case quizHistory

    /// Pushed after Start Quiz succeeds. Carries the StartQuizResponse
    /// (attemptId + totalQuestions) so the session view can fetch.
    case quizSession(attempt: StartQuizResponse)

    /// Pushed after a quiz is completed. The session view does
    /// path.removeLast() + path.append(.quizResults) so back from
    /// Results goes directly to the quiz detail screen, not through
    /// the orphaned session "completing" state.
    case quizResults(attemptId: Int, completionSummary: CompleteQuizResponse?)
}

enum QuizRouter {
    @ViewBuilder
    static func destination(for route: QuizRoute, env: AppEnvironment) -> some View {
        switch route {
        case .quizList(let categoryId, let categoryName):
            QuizListView(env: env, categoryId: categoryId, categoryName: categoryName)
        case .quizDetail(let quiz, let categoryName):
            QuizDetailView(quiz: quiz, categoryName: categoryName)
        case .quizDetailFromId(let quizId):
            QuizDetailLoaderView(env: env, quizId: quizId)
        case .quizHistory:
            QuizHistoryView(env: env)
        case .quizSession(let attempt):
            QuizSessionView(env: env, attempt: attempt)
        case .quizResults(let attemptId, let summary):
            QuizResultsView(env: env, attemptId: attemptId, completionSummary: summary)
        }
    }
}
