//
//  AuthService.swift
//  VexTrainer
//

import Foundation

protocol AuthServicing: Sendable {
    func login(email: String, password: String) async throws -> AuthSession

    /// Server emails an activation link. The new account is unusable until the
    /// user clicks that link, so we do NOT auto-login — even if the response
    /// happens to include a session payload, we discard it.
    func register(userName: String, email: String, phone: String?, password: String) async throws

    func refresh(using refreshToken: String) async throws -> AuthSession
    func logout() async throws
    func forgotPassword(email: String) async throws
    func updateProfile(email: String?, phone: String?) async throws
    func changePassword(old: String, new: String) async throws
    func requestAccountDeletion(email: String) async throws
}

final class AuthService: AuthServicing, @unchecked Sendable {

    private let http: HTTPClient
    private let sessionStore: AuthSessionStore

    init(http: HTTPClient, sessionStore: AuthSessionStore) {
        self.http = http
        self.sessionStore = sessionStore
    }

    // MARK: - Operations

    func login(email: String, password: String) async throws -> AuthSession {
        // Wire format keeps the `identifier` field — the server accepts email there.
        let data: LoginData = try await http.send(.login(
            LoginRequest(identifier: email, password: password)
        ))
        let session = AuthSession(from: data)
        try await sessionStore.save(session)
        return session
    }

    func register(userName: String, email: String, phone: String?, password: String) async throws {
        try await http.sendVoid(.register(
            RegisterRequest(userName: userName, email: email, phone: phone, password: password)
        ))
    }

    func refresh(using refreshToken: String) async throws -> AuthSession {
        let data: RefreshData = try await http.send(.refreshToken(
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

    func logout() async throws {
        // Best-effort server logout — keychain clears either way.
        defer { Task { await sessionStore.clear() } }
        try await http.sendVoid(.logout)
    }

    func forgotPassword(email: String) async throws {
        try await http.sendVoid(.forgotPassword(ForgotPasswordRequest(email: email)))
    }

    func updateProfile(email: String?, phone: String?) async throws {
        try await http.sendVoid(.updateProfile(UpdateProfileRequest(email: email, phone: phone)))
    }

    func changePassword(old: String, new: String) async throws {
        try await http.sendVoid(.changePassword(ChangePasswordRequest(oldPassword: old, newPassword: new)))
    }

    func requestAccountDeletion(email: String) async throws {
        try await http.sendVoid(.requestAccountDeletion(DeleteAccountRequest(email: email)))
    }
}

// MARK: - Endpoint factories

private extension Endpoint {
    static func login(_ req: LoginRequest) -> Endpoint {
        Endpoint(path: "/Auth/login", method: .post, body: req, requiresAuth: false)
    }

    static func register(_ req: RegisterRequest) -> Endpoint {
        Endpoint(path: "/Auth/register", method: .post, body: req, requiresAuth: false)
    }

    static func refreshToken(_ req: RefreshTokenRequest) -> Endpoint {
        Endpoint(path: "/Auth/refresh", method: .post, body: req, requiresAuth: false)
    }

    static var logout: Endpoint {
        Endpoint(path: "/Auth/logout", method: .post, requiresAuth: true)
    }

    static func forgotPassword(_ req: ForgotPasswordRequest) -> Endpoint {
        Endpoint(path: "/Auth/forgot-password", method: .post, body: req, requiresAuth: false)
    }

    static func updateProfile(_ req: UpdateProfileRequest) -> Endpoint {
        Endpoint(path: "/Auth/profile", method: .put, body: req, requiresAuth: true)
    }

    static func changePassword(_ req: ChangePasswordRequest) -> Endpoint {
        Endpoint(path: "/Auth/change-password", method: .post, body: req, requiresAuth: true)
    }

    static func requestAccountDeletion(_ req: DeleteAccountRequest) -> Endpoint {
        Endpoint(path: "/Auth/delete-account/request", method: .post, body: req, requiresAuth: false)
    }
}
