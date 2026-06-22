//
//  CategoryListViewModel.swift
//  VexTrainer
//
//  Offset-based paged loading. First page replaces state.idle/loading;
//  subsequent pages append to the existing array without changing the loaded
//  state, so the UI doesn't flash.
//

import Foundation
import Observation

@Observable
@MainActor
final class CategoryListViewModel {

    enum LoadState {
        case idle
        case loading
        case loaded([QuizCategory])
        case failed(String)
    }

    var state: LoadState = .idle
    /// True while a "next page" fetch is in flight. The view shows a bottom
    /// sentinel spinner when this is true.
    var isLoadingMore: Bool = false
    /// Server-reported "more available" flag. When false, the bottom sentinel
    /// disappears and no further fetches happen.
    var hasMore: Bool = true

    private var currentOffset: Int = 0
    private let pageSize: Int = 14   // matches Android's chunk size

    private let service: QuizServicing

    init(service: QuizServicing) {
        self.service = service
    }

    // MARK: - First load + refresh

    func loadIfNeeded() async {
        if case .loaded = state { return }
        await loadFirstPage()
    }

    func refresh() async {
        // Reset paging state, then fetch page 1. Existing data stays visible
        // until the new data overwrites it.
        currentOffset = 0
        hasMore = true
        do {
            let response = try await service.fetchCategoriesPage(offset: 0, pageSize: pageSize)
            currentOffset = response.categories.count
            hasMore = response.hasMore
            state = .loaded(response.categories)
        } catch {
            // Keep showing what we have. Pull-to-refresh failure is silent.
        }
    }

    // MARK: - Incremental load (triggered by bottom sentinel .task)

    /// Called by the bottom sentinel View's `.task`. Guards against
    /// concurrent fetches and "no more data" cases.
    func loadNextPageIfPossible() async {
        guard !isLoadingMore, hasMore else { return }
        guard case .loaded(let existing) = state else { return }

        isLoadingMore = true
        defer { isLoadingMore = false }

        do {
            let response = try await service.fetchCategoriesPage(
                offset: currentOffset,
                pageSize: pageSize
            )
            currentOffset += response.categories.count
            hasMore = response.hasMore
            state = .loaded(existing + response.categories)
        } catch {
            // Soft failure — keep showing existing items. Sentinel stays visible
            // so the user can scroll back into view to retry (next .task fires).
        }
    }

    // MARK: - Private

    private func loadFirstPage() async {
        state = .loading
        do {
            let response = try await service.fetchCategoriesPage(offset: 0, pageSize: pageSize)
            currentOffset = response.categories.count
            hasMore = response.hasMore
            state = .loaded(response.categories)
        } catch let error as APIError {
            state = .failed(error.localizedDescription)
        } catch {
            state = .failed(error.localizedDescription)
        }
    }
}
