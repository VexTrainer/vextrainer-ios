//
//  DeleteAccountViewModel.swift
//  VexTrainer
//

import Foundation
import Observation

@Observable
@MainActor
final class DeleteAccountViewModel {

    var isSending: Bool = false
    var error: String?
    var didSendSuccessfully: Bool = false

    let email: String
    private let authService: AuthServicing

    init(authService: AuthServicing, email: String) {
        self.authService = authService
        self.email = email
    }

    func sendDeletionEmail() async {
        guard !isSending else { return }
        isSending = true
        error = nil
        defer { isSending = false }
        do {
            try await authService.requestAccountDeletion(email: email)
            didSendSuccessfully = true
        } catch let apiError as APIError {
            error = apiError.localizedDescription
        } catch {
            self.error = error.localizedDescription
        }
    }
}
