//
//  ContactDTOs.swift
//  VexTrainer
//
//  POST /Contact request body. Server stores the message with the
//  caller's user ID (taken from the JWT) and dispatches an email to
//  the admin inbox via the configured SMTP relay.
//

import Foundation

struct ContactRequest: Encodable, Sendable {
    let category: String   // "Suggestion" | "Correction" | "Other"
    let message: String
}
