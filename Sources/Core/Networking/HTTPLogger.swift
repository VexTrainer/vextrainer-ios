//
//  HTTPLogger.swift
//  VexTrainer
//
//  Logs every HTTP request and response to the Xcode console in DEBUG builds only.
//  Release builds compile this out entirely — zero overhead.
//
//  Tokens are redacted: only the first 8 characters are shown, followed by "…".
//  Never log full Bearer tokens; even in development, console output ends up in
//  screenshots, screen recordings, and pasted help-desk tickets.
//

import Foundation
import OSLog

enum HTTPLogger {

    #if DEBUG
    private static let log = Logger(subsystem: "com.vextrainer.ios", category: "HTTP")
    #endif

    static func logRequest(_ request: URLRequest) {
        #if DEBUG
        let method = request.httpMethod ?? "?"
        let url = request.url?.absoluteString ?? "?"
        log.debug("→ \(method, privacy: .public) \(url, privacy: .public)")

        if let auth = request.value(forHTTPHeaderField: "Authorization") {
            log.debug("  Authorization: \(redact(auth), privacy: .public)")
        }
        if let body = request.httpBody, let json = String(data: body, encoding: .utf8) {
            log.debug("  Body: \(redactBody(json), privacy: .public)")
        }
        #endif
    }

    static func logResponse(_ response: URLResponse?, data: Data?, error: Error?) {
        #if DEBUG
        if let error = error {
            log.error("← ERROR \(error.localizedDescription, privacy: .public)")
            return
        }
        guard let http = response as? HTTPURLResponse else {
            log.debug("← (non-HTTP response)")
            return
        }
        let url = http.url?.absoluteString ?? "?"
        log.debug("← \(http.statusCode) \(url, privacy: .public)")

        if let data = data, !data.isEmpty,
           let body = String(data: data, encoding: .utf8) {
            // Truncate noisy responses (questions list, etc.)
            let preview = body.count > 1500
                ? String(body.prefix(1500)) + "…(\(body.count) bytes total)"
                : body
            log.debug("  Body: \(redactBody(preview), privacy: .public)")
        }
        #endif
    }

    // MARK: - Redaction

    /// "Bearer eyJhbGciOiJIUzI1…" → "Bearer eyJhbGciOi…"
    private static func redact(_ header: String) -> String {
        guard header.hasPrefix("Bearer "), header.count > 15 else { return header }
        let prefix = header.prefix(15)  // "Bearer " + 8 chars
        return "\(prefix)…"
    }

    /// Mask token-shaped values inside JSON bodies.
    private static func redactBody(_ body: String) -> String {
        body
            .replacingOccurrences(
                of: #""token"\s*:\s*"[^"]+""#,
                with: #""token":"[REDACTED]""#,
                options: .regularExpression
            )
            .replacingOccurrences(
                of: #""refreshToken"\s*:\s*"[^"]+""#,
                with: #""refreshToken":"[REDACTED]""#,
                options: .regularExpression
            )
            .replacingOccurrences(
                of: #""password"\s*:\s*"[^"]+""#,
                with: #""password":"[REDACTED]""#,
                options: .regularExpression
            )
    }
}
