//
//  AuthDTOTests.swift
//  VexTrainerTests
//
//  Decode actual JSON fixtures into our DTOs. Catches name mismatches and
//  optional/required errors early — way cheaper than catching them by hitting
//  a live API.
//

import XCTest
@testable import VexTrainer

final class AuthDTOTests: XCTestCase {

    private let decoder = JSONDecoder.vexTrainer

    func test_decodeSuccessfulLogin() throws {
        let json = try fixture("LoginSuccess")
        let envelope = try decoder.decode(ApiResponse<LoginData>.self, from: json)

        XCTAssertTrue(envelope.success)
        XCTAssertEqual(envelope.message, "Login successful")
        XCTAssertEqual(envelope.resultCode, 0)

        let data = try XCTUnwrap(envelope.data)
        XCTAssertEqual(data.userId, 42)
        XCTAssertEqual(data.userName, "testuser")
        XCTAssertEqual(data.email, "test@example.com")
        XCTAssertEqual(data.roleName, "Student")
        XCTAssertFalse(data.token.isEmpty)
        XCTAssertFalse(data.refreshToken.isEmpty)
        XCTAssertEqual(data.expiryDate, "2026-06-09T10:30:00")
    }

    func test_decodeFailedLogin() throws {
        let json = try fixture("LoginFailure")
        let envelope = try decoder.decode(ApiResponse<LoginData>.self, from: json)

        XCTAssertFalse(envelope.success)
        XCTAssertNil(envelope.data)
        XCTAssertEqual(envelope.message, "Invalid credentials")
        XCTAssertEqual(envelope.resultCode, 1001)
    }

    func test_decodeRefresh_extractsTokensIgnoresUserInfo() throws {
        // Server returns the full LoginData shape on refresh, but its user info
        // fields are placeholders ("User", empty email, userId=0). RefreshData
        // models only the three token fields — Decodable ignores extras, so
        // we never accidentally read the placeholders.
        let json = try fixture("RefreshResponse")
        let envelope = try decoder.decode(ApiResponse<RefreshData>.self, from: json)

        XCTAssertTrue(envelope.success)
        let data = try XCTUnwrap(envelope.data)
        XCTAssertEqual(data.token, "eyJhbGciOiJIUzI1NiJ9.refreshed.token")
        XCTAssertEqual(data.refreshToken, "rt_new_xyz789")
        XCTAssertEqual(data.expiryDate, "2026-06-09T11:30:00")
    }

    func test_authSessionRoundTrip() {
        let data = LoginData(
            userId: 1,
            userName: "u",
            email: "u@e.com",
            token: "t",
            refreshToken: "rt",
            expiryDate: "2026-12-31T23:59:59",
            roleName: "Student"
        )
        let session = AuthSession(from: data)
        XCTAssertEqual(session.userId, data.userId)
        XCTAssertEqual(session.token, data.token)
        XCTAssertEqual(session.refreshToken, data.refreshToken)
    }

    // MARK: - Helpers

    private func fixture(_ name: String) throws -> Data {
        let bundle = Bundle(for: type(of: self))
        // Resource folders sometimes end up flattened, sometimes preserved —
        // try both. Robust to XcodeGen configuration variations.
        let url = bundle.url(forResource: name, withExtension: "json")
            ?? bundle.url(forResource: name, withExtension: "json", subdirectory: "Fixtures")
        guard let url else {
            throw FixtureError.notFound(name)
        }
        return try Data(contentsOf: url)
    }

    enum FixtureError: Error { case notFound(String) }
}
