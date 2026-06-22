//
//  QuizHistoryViewModel.swift
//  VexTrainer
//

import Foundation
import Observation

@Observable
@MainActor
final class QuizHistoryViewModel {

    enum State {
        case idle
        case loading
        case loaded(items: [QuizHistoryItem], totalCount: Int)
        case failed(String)
    }

    var state: State = .idle
    var isLoadingMore: Bool = false

    private let pageSize = 20
    private var page = 1
    private var hasLoaded = false
    private let service: QuizServicing

    init(service: QuizServicing) {
        self.service = service
    }

    var hasMore: Bool {
        if case let .loaded(items, total) = state {
            return items.count < total
        }
        return false
    }

    func loadIfNeeded() async {
        guard !hasLoaded else { return }
        await loadFirstPage()
    }

    func refresh() async {
        await loadFirstPage()
    }

    private func loadFirstPage() async {
        state = .loading
        page = 1
        do {
            let response = try await service.fetchQuizHistory(page: page, limit: pageSize)
            state = .loaded(items: response.attempts, totalCount: response.totalCount)
            hasLoaded = true
        } catch let apiError as APIError {
            state = .failed(apiError.localizedDescription)
        } catch {
            state = .failed(error.localizedDescription)
        }
    }

    func loadMore() async {
        guard case let .loaded(existing, total) = state else { return }
        guard !isLoadingMore, existing.count < total else { return }

        isLoadingMore = true
        defer { isLoadingMore = false }

        let nextPage = page + 1
        do {
            let response = try await service.fetchQuizHistory(page: nextPage, limit: pageSize)
            // Defensive: if state changed under us (refresh fired), drop result.
            guard case let .loaded(currentItems, _) = state else { return }
            page = nextPage
            state = .loaded(
                items: currentItems + response.attempts,
                totalCount: response.totalCount
            )
        } catch {
            // Silently swallow load-more errors. The user can keep scrolling —
            // a next-attempt page will retry. If we showed an inline error
            // they'd lose what's already loaded. Matches Android behaviour.
        }
    }
}
