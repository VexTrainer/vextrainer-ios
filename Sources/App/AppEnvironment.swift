//
//  AppEnvironment.swift
//  VexTrainer
//
//  Composition root — constructs the dependency graph once at launch.
//

import Foundation
import Observation

@Observable
@MainActor
final class AppEnvironment {

    let router: AppRouter
    let authSessionStore: AuthSessionStore
    let authService: AuthServicing
    let dashboardService: DashboardServicing
    let lessonService: LessonServicing
    let quizService: QuizServicing
    let contactService: ContactServicing

    init() {
        let keychain = KeychainStore()
        let sessionStore = AuthSessionStore(keychain: keychain)
        self.authSessionStore = sessionStore
        self.router = AppRouter()

        // Refresh-only HTTPClient — has no refresh coordinator (so it can't recurse).
        // Used solely by the TokenRefreshCoordinator's refresh closure below.
        let refreshOnlyClient = URLSessionHTTPClient(
            baseURL: AppConfig.apiBaseURL,
            sessionStore: sessionStore,
            refreshCoordinator: nil
        )

        let refreshCoordinator = TokenRefreshCoordinator { [weak sessionStore] in
            guard let sessionStore else { throw APIError.unauthorized }
            guard let refreshToken = await sessionStore.refreshToken() else {
                throw APIError.unauthorized
            }
            let data: RefreshData = try await refreshOnlyClient.send(.refreshToken(
                RefreshTokenRequest(refreshToken: refreshToken)
            ))
            guard !data.token.isEmpty, !data.refreshToken.isEmpty else {
                throw APIError.business(message: "Refresh response returned empty tokens.")
            }
            try await sessionStore.updateTokens(
                token: data.token,
                refreshToken: data.refreshToken,
                expiryDate: data.expiryDate
            )
            guard let session = await sessionStore.currentSession() else {
                throw APIError.unauthorized
            }
            return session
        }

        // The real HTTPClient — used by every feature service. Silent refresh
        // happens transparently on 401.
        let http = URLSessionHTTPClient(
            baseURL: AppConfig.apiBaseURL,
            sessionStore: sessionStore,
            refreshCoordinator: refreshCoordinator
        )

        self.authService = AuthService(http: http, sessionStore: sessionStore)
        self.dashboardService = DashboardService(http: http)
        self.lessonService = LessonService(http: http)
        self.quizService = QuizService(http: http)
        self.contactService = ContactService(http: http)
    }

    // MARK: - Bootstrap

    func bootstrap() async {
        guard let saved = await authSessionStore.currentSession() else {
            router.route = .unauthenticated
            return
        }

        // Fast path: access token still valid → go straight in.
        if let expiry = Date.fromAPIString(saved.expiryDate),
           expiry > Date().addingTimeInterval(300) {
            router.route = .authenticated(saved)
            return
        }

        // Slow path: try refreshing up-front. If the refresh token has
        // expired, fall back to Login.
        do {
            let refreshed = try await authService.refresh(using: saved.refreshToken)
            router.route = .authenticated(refreshed)
        } catch {
            await authSessionStore.clear()
            router.route = .unauthenticated
        }
    }
}

private extension Endpoint {
    static func refreshToken(_ req: RefreshTokenRequest) -> Endpoint {
        Endpoint(path: "/Auth/refresh", method: .post, body: req, requiresAuth: false)
    }
}
