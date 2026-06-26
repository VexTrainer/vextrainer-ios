//
//  DateAPIFormatTests.swift
//  VexTrainerTests
//
//  Server sends timestamps in UTC, often without a timezone marker. The most common
//  bug in client code is parsing "2026-06-09T10:30:00" as device-local time, which
//  silently shifts everything by the user's UTC offset. These tests pin down the
//  correct behavior so a future "improvement" can't regress it.
//

import XCTest
@testable import VexTrainer

final class DateAPIFormatTests: XCTestCase {

    func test_parsesBareTimestampAsUTC() throws {
        // 2026-06-09T10:30:00 UTC == Unix timestamp 1781001000
        let date = try XCTUnwrap(Date.fromAPIString("2026-06-09T10:30:00"))
        XCTAssertEqual(date.timeIntervalSince1970, 1781001000, accuracy: 1.0)
    }

    func test_parsesISO8601WithZ() throws {
        let date = try XCTUnwrap(Date.fromAPIString("2026-06-09T10:30:00Z"))
        XCTAssertEqual(date.timeIntervalSince1970, 1781001000, accuracy: 1.0)
    }

    func test_parsesISO8601WithFractionalSeconds() throws {
        let date = try XCTUnwrap(Date.fromAPIString("2026-06-09T10:30:00.500Z"))
        XCTAssertEqual(date.timeIntervalSince1970, 1781001000.5, accuracy: 0.1)
    }

    func test_parsesISO8601WithOffset() throws {
        // 10:30 at -04:00 == 14:30 UTC
        let date = try XCTUnwrap(Date.fromAPIString("2026-06-09T10:30:00-04:00"))
        XCTAssertEqual(date.timeIntervalSince1970, 1781015400, accuracy: 1.0)
    }

    func test_rejectsGarbage() {
        XCTAssertNil(Date.fromAPIString(""))
        XCTAssertNil(Date.fromAPIString("not a date"))
        XCTAssertNil(Date.fromAPIString("2026-99-99"))
    }

    func test_bareTimestampDoesNotPickUpDeviceTimezone() throws {
        // Same string parsed twice — result must be identical regardless of
        // when/where the test runs. This is the regression test for the
        // most-common UTC-vs-local bug.
        let a = try XCTUnwrap(Date.fromAPIString("2026-01-15T12:00:00"))
        let b = try XCTUnwrap(Date.fromAPIString("2026-01-15T12:00:00"))
        XCTAssertEqual(a, b)
        // And confirm it's the UTC interpretation, not whatever the device thinks.
        XCTAssertEqual(a.timeIntervalSince1970, 1768521600, accuracy: 1.0)
    }
}
