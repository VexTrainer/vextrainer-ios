//
//  AppRouter.swift
//  VexTrainer
//
//  Owns the high-level route — Auth flow vs Main shell vs the brief launch
//  "checking saved session" state. Everything below this point in the view tree
//  observes the router and switches on it.
//

import Foundation
import Observation

enum AppRoute: Equatable {
    /// Briefly visible at launch while we read the keychain and validate the session.
    case checking
    /// No valid session — show Login / Register / Forgot Password.
    case unauthenticated
    /// User is signed in — show the main shell.
    case authenticated(AuthSession)
}

@Observable
@MainActor
final class AppRouter {
    var route: AppRoute = .checking
}
