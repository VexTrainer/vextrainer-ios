//
//  Validators.swift
//  VexTrainer
//
//  Client-side input validation. Deliberately permissive — the server validates
//  authoritatively. We just want to disable the submit button until the form
//  is plausibly fillable.
//

import Foundation

enum Validators {

    /// Basic email shape check. Doesn't validate against RFC 5322 in full —
    /// that's pointless on the client. We only need to filter obvious garbage.
    static func isValidEmail(_ email: String) -> Bool {
        let trimmed = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }
        let regex = #"^[A-Za-z0-9._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,}$"#
        return trimmed.range(of: regex, options: .regularExpression) != nil
    }

    /// Minimum password length. Server may enforce more (complexity, no common
    /// passwords, etc.) — we just gate the obvious cases here.
    static func isValidPasswordForRegistration(_ password: String) -> Bool {
        password.count >= 8
    }

    /// On Login we don't enforce length — even if the user's stored password
    /// pre-dates the current rules, they should still be able to sign in.
    static func isValidPasswordForLogin(_ password: String) -> Bool {
        !password.isEmpty
    }
}
