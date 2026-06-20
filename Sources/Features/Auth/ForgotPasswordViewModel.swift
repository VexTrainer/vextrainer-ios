//
//  ForgotPasswordViewModel.swift
//  VexTrainer
//

import Foundation
import Observation

@Observable
@MainActor
final class ForgotPasswordViewModel {

    var email: String = ""
    var isSubmitting: Bool = false
    var didSucceed: Bool = false
    var errorMessage: String?

    private let authService: AuthServicing

    init(authService: AuthServicing, prefilledEmail: String = "") {
        self.authService = authService
        self.email = prefilledEmail
    }

    var canSubmit: Bool {
        !isSubmitting && Validators.isValidEmail(email)
    }

    func submit() async {
        guard canSubmit else { return }
        isSubmitting = true
        errorMessage = nil
        defer { isSubmitting = false }

        do {
            try await authService.forgotPassword(
                email: email.trimmingCharacters(in: .whitespaces)
            )
            didSucceed = true
        } catch APIError.business(let message) {
            errorMessage = message
        } catch APIError.network {
            errorMessage = "Network error. Check your connection and try again."
        } catch APIError.http(_, let message) {
            errorMessage = message ?? "Couldn't send the reset link. Please try again."
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func clearErrorOnEdit() {
        if errorMessage != nil { errorMessage = nil }
    }
}
