//
//  DashboardViewModel.swift
//  VexTrainer
//

import Foundation
import Observation

@Observable
@MainActor
final class DashboardViewModel {

    enum LoadState {
        case idle
        case loading
        case loaded(DashboardResponse)
        case failed(String)
    }

    var state: LoadState = .idle
    var isRefreshing: Bool = false

    private let service: DashboardServicing

    init(service: DashboardServicing) {
        self.service = service
    }

    /// First fetch when the user lands on the Home tab, or after a
    /// failure. Pure "load if we don't already have data" — the
    /// reactive refresh-on-data-change logic now lives in the view,
    /// observing DashboardInvalidator.revision via @Observable.
    func loadIfNeeded() async {
        if case .loaded = state { return }
        await fetch(setLoadingState: true)
    }

    /// Pull-to-refresh path. Keeps existing data visible while reloading.
    func refresh() async {
        isRefreshing = true
        defer { isRefreshing = false }
        await fetch(setLoadingState: false)
    }

    private func fetch(setLoadingState: Bool) async {
        if setLoadingState { state = .loading }
        do {
            let response = try await service.fetchDashboard()
            state = .loaded(response)
        } catch APIError.unauthorized {
            state = .failed("Your session has expired. Please sign in again.")
        } catch APIError.network {
            state = .failed("Network error. Check your connection and try again.")
        } catch let error as APIError {
            state = .failed(error.localizedDescription)
        } catch {
            state = .failed(error.localizedDescription)
        }
    }
}
