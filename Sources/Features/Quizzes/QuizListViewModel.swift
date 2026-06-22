//
//  QuizListViewModel.swift
//  VexTrainer
//

import Foundation
import Observation

@Observable
@MainActor
final class QuizListViewModel {

    enum LoadState {
        case idle
        case loading
        case loaded([QuizSummary])
        case failed(String)
    }

    var state: LoadState = .idle
    let categoryId: Int

    private let service: QuizServicing

    init(service: QuizServicing, categoryId: Int) {
        self.service = service
        self.categoryId = categoryId
    }

    func loadIfNeeded() async {
        if case .loaded = state { return }
        await fetch()
    }

    func refresh() async { await fetch() }

    private func fetch() async {
        if case .loaded = state {} else { state = .loading }
        do {
            let quizzes = try await service.fetchQuizzes(categoryId: categoryId)
            state = .loaded(quizzes)
        } catch let error as APIError {
            state = .failed(error.localizedDescription)
        } catch {
            state = .failed(error.localizedDescription)
        }
    }
}
