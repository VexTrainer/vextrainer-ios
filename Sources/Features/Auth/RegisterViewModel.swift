//
//  RegisterViewModel.swift
//  VexTrainer
//

import Foundation
import Observation

@Observable
@MainActor
final class RegisterViewModel {

    var userName: String = ""
    var email: String = ""
    var phone: String = ""
    var password: String = ""
    var confirmPassword: String = ""

    var isSubmitting: Bool = false
    var didSucceed: Bool = false
    var errorMessage: String?

    private let authService: AuthServicing

    init(authService: AuthServicing, prefilledEmail: String = "") {
        self.authService = authService
        self.email = prefilledEmail
    }

    var passwordsMatch: Bool {
        password == confirmPassword
    }

    var canSubmit: Bool {
        !isSubmitting
            && !userName.trimmingCharacters(in: .whitespaces).isEmpty
            && Validators.isValidEmail(email)
            && Validators.isValidPasswordForRegistration(password)
            && passwordsMatch
    }

    func submit() async {
        guard canSubmit else { return }
        isSubmitting = true
        errorMessage = nil
        defer { isSubmitting = false }

        let trimmedPhone = phone.trimmingCharacters(in: .whitespaces)
        let phoneArg: String? = trimmedPhone.isEmpty ? nil : trimmedPhone

        do {
            try await authService.register(
                userName: userName.trimmingCharacters(in: .whitespaces),
                email: email.trimmingCharacters(in: .whitespaces),
                phone: phoneArg,
                password: password
            )
            didSucceed = true
        } catch APIError.business(let message) {
            errorMessage = message
        } catch APIError.network {
            errorMessage = "Network error. Check your connection and try again."
        } catch APIError.http(_, let message) {
            errorMessage = message ?? "Registration failed. Please try again."
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func clearErrorOnEdit() {
        if errorMessage != nil { errorMessage = nil }
    }
}
