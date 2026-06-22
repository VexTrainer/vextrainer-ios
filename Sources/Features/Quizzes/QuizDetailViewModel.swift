//
//  QuizDetailViewModel.swift
//  VexTrainer
//
//  Owns the Start Quiz API call from the detail page. When startQuiz()
//  succeeds, sets `startedAttempt` — the view observes this via
//  `.navigationDestination(item:)` and pushes the session player.
//

import Foundation
import Observation

@Observable
@MainActor
final class QuizDetailViewModel {

    /// Set when startQuiz succeeds. Triggers a navigation push.
    var startedAttempt: StartQuizResponse?
    var isStarting: Bool = false
    var error: String?

    private let quizId: Int
    private let service: QuizServicing

    init(quizId: Int, service: QuizServicing) {
        self.quizId = quizId
        self.service = service
    }

    func startQuiz() async {
        guard !isStarting else { return }
        isStarting = true
        error = nil
        defer { isStarting = false }

        do {
            let response = try await service.startQuiz(quizId: quizId)
            startedAttempt = response
        } catch let apiError as APIError {
            error = apiError.localizedDescription
        } catch {
            self.error = error.localizedDescription
        }
    }
}
