//
//  ContactService.swift
//  VexTrainer
//

import Foundation

protocol ContactServicing: Sendable {
    func sendMessage(category: String, message: String) async throws
}

final class ContactService: ContactServicing, @unchecked Sendable {

    private let http: HTTPClient

    init(http: HTTPClient) {
        self.http = http
    }

    func sendMessage(category: String, message: String) async throws {
        let request = ContactRequest(category: category, message: message)
        try await http.sendVoid(.submitContact(request: request))
    }
}

// MARK: - Endpoint factories

private extension Endpoint {
    static func submitContact(request: ContactRequest) -> Endpoint {
        Endpoint(
            path: "/Contact",
            method: .post,
            body: request,
            requiresAuth: true
        )
    }
}
