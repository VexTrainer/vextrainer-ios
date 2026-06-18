//
//  TokenRefreshCoordinator.swift
//  VexTrainer
//
//  Serializes silent token refresh. If five concurrent requests all return 401
//  at the same time, only ONE refresh call hits the server — the other four
//  await the same Task and reuse its result.
//
//  Why an actor: refresh state (the in-flight Task) is shared mutable state
//  accessed from many concurrent request paths. Actors make this safe by
//  construction without manual locks.
//
//  Why reactive-only (no proactive timer): iOS suspends background timers
//  aggressively. A Timer scheduled to fire 60 seconds before token expiry
//  may never fire if the app is backgrounded or the device sleeps. Reactive
//  refresh on 401 is more robust — and the latency is one round-trip, not noticeable.
//

import Foundation

/// Refreshes the auth token. The closure passed at init does the actual network call;
/// the coordinator's job is purely to dedupe concurrent attempts and cache the in-flight Task.
actor TokenRefreshCoordinator {

    typealias RefreshOperation = () async throws -> AuthSession

    private let refreshOperation: RefreshOperation
    private var inFlightTask: Task<AuthSession, Error>?

    init(refresh: @escaping RefreshOperation) {
        self.refreshOperation = refresh
    }

    /// Performs a refresh, or joins the one already in flight. Multiple concurrent
    /// callers will all `await` the same Task and receive the same result.
    func refresh() async throws -> AuthSession {
        if let existing = inFlightTask {
            return try await existing.value
        }
        let task = Task<AuthSession, Error> {
            do {
                let session = try await refreshOperation()
                inFlightTask = nil
                return session
            } catch {
                inFlightTask = nil
                throw error
            }
        }
        inFlightTask = task
        return try await task.value
    }
}
