//
//  QuizService.swift
//  VexTrainer
//

import Foundation

protocol QuizServicing: Sendable {
    // Categories + quiz lists
    func fetchCategoriesPage(offset: Int, pageSize: Int) async throws -> PagedCategoriesResponse
    func fetchQuizzes(categoryId: Int) async throws -> [QuizSummary]
    func fetchQuizDetail(quizId: Int) async throws -> QuizDetailDto
    func fetchQuizHistory(page: Int, limit: Int) async throws -> QuizHistoryResponse

    // Session flow
    func startQuiz(quizId: Int) async throws -> StartQuizResponse
    func fetchQuestions(attemptId: Int) async throws -> QuizQuestionsResponse
    func submitAnswer(attemptId: Int, request: SubmitAnswerRequest) async throws -> SubmitAnswerResponse
    func completeQuiz(attemptId: Int) async throws -> CompleteQuizResponse
    func fetchResults(attemptId: Int) async throws -> QuizResults
}

final class QuizService: QuizServicing, @unchecked Sendable {

    private let http: HTTPClient

    init(http: HTTPClient) {
        self.http = http
    }

    // MARK: - Categories + quizzes

    func fetchCategoriesPage(offset: Int, pageSize: Int) async throws -> PagedCategoriesResponse {
        try await http.send(.quizCategoriesPaged(offset: offset, pageSize: pageSize))
    }

    func fetchQuizzes(categoryId: Int) async throws -> [QuizSummary] {
        try await http.send(.quizzes(categoryId: categoryId))
    }

    func fetchQuizDetail(quizId: Int) async throws -> QuizDetailDto {
        try await http.send(.quizDetail(quizId: quizId))
    }

    func fetchQuizHistory(page: Int, limit: Int) async throws -> QuizHistoryResponse {
        try await http.send(.quizHistory(page: page, limit: limit))
    }

    // MARK: - Session flow

    func startQuiz(quizId: Int) async throws -> StartQuizResponse {
        try await http.send(.startQuiz(quizId: quizId))
    }

    func fetchQuestions(attemptId: Int) async throws -> QuizQuestionsResponse {
        try await http.send(.attemptQuestions(attemptId: attemptId))
    }

    func submitAnswer(attemptId: Int, request: SubmitAnswerRequest) async throws -> SubmitAnswerResponse {
        try await http.send(.attemptAnswer(attemptId: attemptId, request: request))
    }

    func completeQuiz(attemptId: Int) async throws -> CompleteQuizResponse {
        try await http.send(.attemptComplete(attemptId: attemptId))
    }

    func fetchResults(attemptId: Int) async throws -> QuizResults {
        try await http.send(.attemptResults(attemptId: attemptId))
    }
}

// MARK: - Endpoint factories

private extension Endpoint {
    static func quizCategoriesPaged(offset: Int, pageSize: Int) -> Endpoint {
        Endpoint(
            path: "/Quiz/categories/paged",
            method: .get,
            queryItems: [
                URLQueryItem(name: "offset", value: "\(offset)"),
                URLQueryItem(name: "pageSize", value: "\(pageSize)")
            ],
            requiresAuth: true
        )
    }

    static func quizzes(categoryId: Int) -> Endpoint {
        Endpoint(
            path: "/Quiz/categories/\(categoryId)/quizzes",
            method: .get,
            requiresAuth: true
        )
    }

    static func quizDetail(quizId: Int) -> Endpoint {
        Endpoint(
            path: "/Quiz/quizzes/\(quizId)",
            method: .get,
            requiresAuth: true
        )
    }

    /// Paginated history of every quiz attempt the user has made.
    /// Note: lives under the `/User/` controller, not `/Quiz/` — that's
    /// the server convention (this is the user's own data view, not
    /// quiz mechanics).
    static func quizHistory(page: Int, limit: Int) -> Endpoint {
        Endpoint(
            path: "/User/history",
            method: .get,
            queryItems: [
                URLQueryItem(name: "page", value: "\(page)"),
                URLQueryItem(name: "limit", value: "\(limit)")
            ],
            requiresAuth: true
        )
    }

    static func startQuiz(quizId: Int) -> Endpoint {
        Endpoint(
            path: "/Quiz/quizzes/\(quizId)/start",
            method: .post,
            requiresAuth: true
        )
    }

    static func attemptQuestions(attemptId: Int) -> Endpoint {
        Endpoint(
            path: "/Quiz/attempts/\(attemptId)/questions",
            method: .get,
            requiresAuth: true
        )
    }

    static func attemptAnswer(attemptId: Int, request: SubmitAnswerRequest) -> Endpoint {
        Endpoint(
            path: "/Quiz/attempts/\(attemptId)/answer",
            method: .post,
            body: request,
            requiresAuth: true
        )
    }

    static func attemptComplete(attemptId: Int) -> Endpoint {
        Endpoint(
            path: "/Quiz/attempts/\(attemptId)/complete",
            method: .post,
            requiresAuth: true
        )
    }

    static func attemptResults(attemptId: Int) -> Endpoint {
        Endpoint(
            path: "/Quiz/attempts/\(attemptId)/results",
            method: .get,
            requiresAuth: true
        )
    }
}
