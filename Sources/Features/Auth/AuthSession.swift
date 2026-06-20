//
//  AuthSession.swift
//  VexTrainer
//
//  Domain model for an authenticated session. Built from LoginData (the wire DTO)
//  but used everywhere else in the app. Keeping it separate from LoginData means
//  if the server ever splits/renames fields, only the DTO and one mapping function
//  change — not every screen that reads userName or roleName.
//

import Foundation

struct AuthSession: Equatable, Sendable {
    let userId: Int
    let userName: String
    let email: String
    let token: String
    let refreshToken: String
    let expiryDate: String
    let roleName: String

    init(from data: LoginData) {
        self.userId = data.userId
        self.userName = data.userName
        self.email = data.email
        self.token = data.token
        self.refreshToken = data.refreshToken
        self.expiryDate = data.expiryDate
        self.roleName = data.roleName
    }

    init(
        userId: Int,
        userName: String,
        email: String,
        token: String,
        refreshToken: String,
        expiryDate: String,
        roleName: String
    ) {
        self.userId = userId
        self.userName = userName
        self.email = email
        self.token = token
        self.refreshToken = refreshToken
        self.expiryDate = expiryDate
        self.roleName = roleName
    }
}
