//
//  LoginViewModel.swift
//  VexTrainer
//

import Foundation
import Observation

@Observable
@MainActor
final class LoginViewModel {

    var email: String = ""
    var password: String = ""
    var isSubmitting: Bool = false
    var errorMessage: String?

    private let authService: AuthServicing
    private let router: AppRouter

    init(authService: AuthServicing, router: AppRouter) {
        self.authService = authService
        self.router = router
    }

    var canSubmit: Bool {
        !isSubmitting
            && Validators.isValidEmail(email)
            && Validators.isValidPasswordForLogin(password)
    }

    /// Used by the View to gate "Forgot password?" and "Sign up" until the user
    /// has provided a plausible email. The email value carries over to those
    /// screens and pre-fills them, so we want it valid before letting the user
    /// navigate away.
    var isEmailValid: Bool {
        Validators.isValidEmail(email)
    }

    func submit() async {
        guard canSubmit else { return }
        isSubmitting = true
        errorMessage = nil
        defer { isSubmitting = false }

        do {
            let session = try await authService.login(
                email: email.trimmingCharacters(in: .whitespacesAndNewlines),
                password: password
            )
            router.route = .authenticated(session)
        } catch APIError.unauthorized {
            errorMessage = "Invalid email or password."
        } catch APIError.business(let message) {
            errorMessage = message
        } catch APIError.network {
            errorMessage = "Network error. Check your connection and try again."
        } catch APIError.http(_, let message) {
            errorMessage = message ?? "Sign-in failed. Please try again."
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Clear the inline error when the user starts typing again.
    func clearErrorOnEdit() {
        if errorMessage != nil { errorMessage = nil }
    }
}
