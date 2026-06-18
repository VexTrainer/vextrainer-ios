//
//  AuthSessionStore.swift
//  VexTrainer
//
//  Owns the persisted auth session. The HTTPClient calls `token()` before every
//  authenticated request; auth flows (login/refresh/logout) call `save()` and
//  `clear()`. Implemented as an actor so concurrent access from multiple in-flight
//  requests is safe without manual locking.
//
//  Tokens live in Keychain (survives app uninstall on some devices — that's actually
//  fine for auth tokens; the server's refresh-token revocation handles cleanup).
//  Non-sensitive fields (userName, email, roleName) could live in UserDefaults but
//  we keep them with the token for simplicity — one source of truth, atomic clear.
//

import Foundation

actor AuthSessionStore {

    // MARK: - Storage keys

    private enum Key {
        static let token = "auth.token"
        static let refreshToken = "auth.refreshToken"
        static let expiryDate = "auth.expiryDate"
        static let userId = "auth.userId"
        static let userName = "auth.userName"
        static let email = "auth.email"
        static let roleName = "auth.roleName"
    }

    private let keychain: KeychainStoring

    init(keychain: KeychainStoring) {
        self.keychain = keychain
    }

    // MARK: - Reads

    /// Current bearer token, if any. Fast path for HTTPClient's per-request lookup.
    func token() -> String? {
        keychain.string(forKey: Key.token)
    }

    /// Full session including user info. Returns nil if no session is persisted.
    func currentSession() -> AuthSession? {
        guard
            let token = keychain.string(forKey: Key.token),
            let refreshToken = keychain.string(forKey: Key.refreshToken),
            let expiryDate = keychain.string(forKey: Key.expiryDate),
            let userIdString = keychain.string(forKey: Key.userId),
            let userId = Int(userIdString),
            let userName = keychain.string(forKey: Key.userName),
            let email = keychain.string(forKey: Key.email),
            let roleName = keychain.string(forKey: Key.roleName)
        else {
            return nil
        }
        return AuthSession(
            userId: userId,
            userName: userName,
            email: email,
            token: token,
            refreshToken: refreshToken,
            expiryDate: expiryDate,
            roleName: roleName
        )
    }

    func refreshToken() -> String? {
        keychain.string(forKey: Key.refreshToken)
    }

    // MARK: - Writes

    func save(_ session: AuthSession) throws {
        try keychain.setString(session.token,        forKey: Key.token)
        try keychain.setString(session.refreshToken, forKey: Key.refreshToken)
        try keychain.setString(session.expiryDate,   forKey: Key.expiryDate)
        try keychain.setString(String(session.userId), forKey: Key.userId)
        try keychain.setString(session.userName,     forKey: Key.userName)
        try keychain.setString(session.email,        forKey: Key.email)
        try keychain.setString(session.roleName,     forKey: Key.roleName)
    }

    /// Updates ONLY the token-related fields, leaving user info (userId, userName,
    /// email, roleName) untouched. Used by token refresh — the server's refresh
    /// response doesn't include reliable user info, so refresh must not touch it.
    func updateTokens(
        token: String,
        refreshToken: String,
        expiryDate: String
    ) throws {
        try keychain.setString(token,        forKey: Key.token)
        try keychain.setString(refreshToken, forKey: Key.refreshToken)
        try keychain.setString(expiryDate,   forKey: Key.expiryDate)
    }

    func clear() {
        // Best-effort — if keychain throws on remove, there's nothing useful we can do.
        try? keychain.remove(forKey: Key.token)
        try? keychain.remove(forKey: Key.refreshToken)
        try? keychain.remove(forKey: Key.expiryDate)
        try? keychain.remove(forKey: Key.userId)
        try? keychain.remove(forKey: Key.userName)
        try? keychain.remove(forKey: Key.email)
        try? keychain.remove(forKey: Key.roleName)
    }
}
