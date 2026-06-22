//
//  QuizResultsViewModel.swift
//  VexTrainer
//

import Foundation
import Observation

@Observable
@MainActor
final class QuizResultsViewModel {

    enum LoadState {
        case idle
        case loading
        case loaded(QuizResults)
        case failed(String)
    }

    var state: LoadState = .idle

    let attemptId: Int
    private let service: QuizServicing

    init(attemptId: Int, service: QuizServicing) {
        self.attemptId = attemptId
        self.service = service
    }

    func loadIfNeeded() async {
        if case .loaded = state { return }
        await fetch()
    }

    func refresh() async { await fetch() }

    private func fetch() async {
        if case .loaded = state {} else { state = .loading }
        do {
            let results = try await service.fetchResults(attemptId: attemptId)
            state = .loaded(results)
        } catch let e as APIError {
            state = .failed(e.localizedDescription)
        } catch {
            state = .failed(error.localizedDescription)
        }
    }
}
