//
//  TokenRefreshCoordinatorTests.swift
//  VexTrainerTests
//
//  Verifies that the coordinator's deduplication actually works under concurrency:
//  five simultaneous refresh() calls must result in exactly ONE invocation of the
//  underlying refresh operation.
//

import XCTest
@testable import VexTrainer

final class TokenRefreshCoordinatorTests: XCTestCase {

    func test_concurrentRefreshesDedupe() async throws {
        let callCount = Counter()
        let coordinator = TokenRefreshCoordinator { [callCount] in
            await callCount.increment()
            // Simulate ~50ms of network latency so concurrent calls genuinely overlap.
            try await Task.sleep(nanoseconds: 50_000_000)
            return AuthSession(
                userId: 1,
                userName: "u",
                email: "e@e.com",
                token: "new-token",
                refreshToken: "new-rt",
                expiryDate: "2027-01-01T00:00:00",
                roleName: "Student"
            )
        }

        // Fire five concurrent refreshes.
        let results = await withTaskGroup(of: AuthSession?.self) { group in
            for _ in 0..<5 {
                group.addTask {
                    try? await coordinator.refresh()
                }
            }
            return await group.reduce(into: [AuthSession?]()) { $0.append($1) }
        }

        let count = await callCount.value
        XCTAssertEqual(count, 1, "Expected exactly one underlying refresh call, got \(count)")
        XCTAssertEqual(results.compactMap { $0 }.count, 5, "All five callers should receive a session")
        XCTAssertTrue(results.compactMap { $0 }.allSatisfy { $0.token == "new-token" })
    }

    func test_sequentialRefreshesEachCallTheOperation() async throws {
        let callCount = Counter()
        let coordinator = TokenRefreshCoordinator { [callCount] in
            await callCount.increment()
            return AuthSession(
                userId: 1, userName: "u", email: "e@e.com",
                token: "t", refreshToken: "rt",
                expiryDate: "2027-01-01T00:00:00", roleName: "Student"
            )
        }

        _ = try await coordinator.refresh()
        _ = try await coordinator.refresh()
        _ = try await coordinator.refresh()

        let count = await callCount.value
        XCTAssertEqual(count, 3, "Sequential refreshes should each trigger the operation")
    }
}

/// Tiny actor-based counter for thread-safe call counting in tests.
private actor Counter {
    private(set) var value = 0
    func increment() { value += 1 }
}
