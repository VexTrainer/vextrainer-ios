//
//  Date+APIFormat.swift
//  VexTrainer
//
//  Single source of truth for date handling across the API boundary.
//
//  Server-side rule: all timestamps are stored AND transmitted in UTC. Many
//  strings come in the form "2026-06-09T10:30:00" with NO timezone marker —
//  these must be parsed as UTC explicitly, not as device-local time.
//
//  Client-side rule: ALWAYS display in the user's local timezone.
//

import Foundation

extension Date {

    // MARK: - Parsing

    /// Parses a server timestamp as UTC. Accepts:
    ///   • "2026-06-09T10:30:00"           (no timezone marker — treated as UTC)
    ///   • "2026-06-09T10:30:00Z"          (ISO-8601 with Z)
    ///   • "2026-06-09T10:30:00.123Z"      (ISO-8601 with fractional seconds)
    ///   • "2026-06-09T10:30:00+00:00"     (ISO-8601 with offset)
    ///
    /// Returns nil if none of these match.
    static func fromAPIString(_ string: String) -> Date? {
        // Try ISO-8601 variants first (handle timezone markers).
        for formatter in Self.iso8601Formatters {
            if let date = formatter.date(from: string) { return date }
        }
        // Fallback: bare "yyyy-MM-dd'T'HH:mm:ss" with no marker → parse as UTC.
        return Self.utcFallbackFormatter.date(from: string)
    }

    // MARK: - Display formatting (always local)

    /// User-facing date + time in their local timezone, e.g. "Jun 9, 2026 at 6:30 AM".
    func formattedLocalDateTime() -> String {
        Self.localDateTimeFormatter.string(from: self)
    }

    /// User-facing date only in their local timezone, e.g. "Jun 9, 2026".
    func formattedLocalDate() -> String {
        Self.localDateFormatter.string(from: self)
    }

    // MARK: - Formatter cache
    //
    // DateFormatter creation is expensive — cache one of each.

    private static let iso8601Formatters: [ISO8601DateFormatter] = {
        let withFraction = ISO8601DateFormatter()
        withFraction.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        let withoutFraction = ISO8601DateFormatter()
        withoutFraction.formatOptions = [.withInternetDateTime]

        return [withFraction, withoutFraction]
    }()

    private static let utcFallbackFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        f.timeZone = TimeZone(identifier: "UTC")
        f.locale = Locale(identifier: "en_US_POSIX")  // robust to user locale changes
        return f
    }()

    private static let localDateTimeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        f.timeZone = .current   // explicit; default behavior, but make the intent clear
        return f
    }()

    private static let localDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .none
        f.timeZone = .current
        return f
    }()
}
