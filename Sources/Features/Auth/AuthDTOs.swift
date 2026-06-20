//
//  AuthDTOs.swift
//  VexTrainer
//
//  Wire-format types for /Auth/* endpoints. Match the server schema exactly —
//  field names, optionality, and casing all derived from the live API.
//
//  These are transport types. UI code talks to AuthSession (the domain model in
//  AuthSession.swift), not these DTOs directly.
//

import Foundation

// MARK: - Requests

struct LoginRequest: Encodable, Sendable {
    let identifier: String   // Email or username — server accepts either.
    let password: String
}

struct RegisterRequest: Encodable, Sendable {
    let userName: String
    let email: String
    let phone: String?
    let password: String
}

struct RefreshTokenRequest: Encodable, Sendable {
    let refreshToken: String
}

struct ForgotPasswordRequest: Encodable, Sendable {
    let email: String
}

struct UpdateProfileRequest: Encodable, Sendable {
    let email: String?
    let phone: String?
}

struct ChangePasswordRequest: Encodable, Sendable {
    let oldPassword: String
    let newPassword: String
}

struct DeleteAccountRequest: Encodable, Sendable {
    let email: String
}

// MARK: - Responses

/// Server's login/refresh payload. Wrapped in ApiResponse<LoginData> on the wire.
struct LoginData: Decodable, Sendable {
    let userId: Int
    let userName: String
    let email: String
    let token: String
    let refreshToken: String
    let expiryDate: String   // ISO-8601-ish — parsed lazily if needed.
    let roleName: String
}

/// Response shape used for `/Auth/refresh`.
///
/// IMPORTANT: even though the server returns a full LoginData-shaped envelope on
/// refresh, only the three token fields below are trustworthy. The server fills
/// in placeholders for userName/email/roleName ("User", empty string, etc.) because
/// refresh tokens carry minimal user identity. Modeling refresh as its own type
/// guarantees we never accidentally overwrite the persisted user info with
/// placeholders — Decodable simply ignores the other fields when they're present.
struct RefreshData: Decodable, Sendable {
    let token: String
    let refreshToken: String
    let expiryDate: String
}
