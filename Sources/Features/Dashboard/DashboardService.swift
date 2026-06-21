//
//  DashboardService.swift
//  VexTrainer
//
//  Read-only — fetches the aggregated dashboard payload. Bookmark mutations
//  live in LessonService because they're conceptually topic-level, not
//  dashboard-level. The dashboard displays the current bookmark list but
//  doesn't manage it.
//

import Foundation

protocol DashboardServicing: Sendable {
    func fetchDashboard() async throws -> DashboardResponse
}

final class DashboardService: DashboardServicing, @unchecked Sendable {

    private let http: HTTPClient

    init(http: HTTPClient) {
        self.http = http
    }

    func fetchDashboard() async throws -> DashboardResponse {
        try await http.send(.appDashboard)
    }
}

private extension Endpoint {
    static var appDashboard: Endpoint {
        Endpoint(path: "/Lesson/app-dashboard", method: .get, requiresAuth: true)
    }
}
