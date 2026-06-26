//
//  ContactUsViewModel.swift
//  VexTrainer
//

import Foundation
import Observation

@Observable
@MainActor
final class ContactUsViewModel {

    static let categories = ["Suggestion", "Correction", "Other"]
    static let maxMessageChars = 2000

    var category: String = "Suggestion"
    var message: String = ""

    var isSending: Bool = false
    var error: String?
    var didSendSuccessfully: Bool = false

    private let service: ContactServicing

    init(service: ContactServicing, initialMessage: String = "") {
        self.service = service
        // Seed the message field — used by the topic-feedback flow to
        // pre-populate "Feedback on: Module X / Lesson Y / Topic Z\n\n".
        // Truncated to the character cap defensively.
        if !initialMessage.isEmpty {
            self.message = String(initialMessage.prefix(Self.maxMessageChars))
        }
    }

    var canSend: Bool {
        !isSending && hasMinimumContent && message.count <= Self.maxMessageChars
    }

    /// Minimum-content gate: at least two words separated by whitespace,
    /// AND the trimmed body is at least 4 characters long. The two-word
    /// rule matches what a "real" message tends to look like (e.g.,
    /// "Fix typo" qualifies; "ok" doesn't). The char floor keeps "a b"
    /// from sneaking through.
    var hasMinimumContent: Bool {
        let trimmed = trimmedMessage
        guard trimmed.count >= 4 else { return false }
        let words = trimmed.split(whereSeparator: { $0.isWhitespace })
        return words.count >= 2
    }

    /// User-facing hint shown beneath the message field while the
    /// content is non-empty but doesn't yet meet the send threshold.
    /// Empty string means "no hint needed".
    var minimumContentHint: String {
        guard !trimmedMessage.isEmpty, !hasMinimumContent else { return "" }
        return "Please write at least a couple of words."
    }

    var characterCountLabel: String {
        "\(message.count) / \(Self.maxMessageChars)"
    }

    var isOverLimit: Bool {
        message.count >= Self.maxMessageChars
    }

    private var trimmedMessage: String {
        message.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func send() async {
        guard canSend else { return }
        isSending = true
        error = nil
        defer { isSending = false }
        do {
            // Append device/app context so support can triage without
            // a back-and-forth ("what device are you on?"). The user
            // never sees this in the compose field — it's added only
            // at send time. See DeviceInfo.contactFooter.
            let body = trimmedMessage + "\n\n" + DeviceInfo.contactFooter
            try await service.sendMessage(category: category, message: body)
            didSendSuccessfully = true
            message = ""
        } catch let apiError as APIError {
            error = apiError.localizedDescription
        } catch {
            self.error = error.localizedDescription
        }
    }
}
