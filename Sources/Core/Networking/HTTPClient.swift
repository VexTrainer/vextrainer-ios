//
//  HTTPClient.swift
//  VexTrainer
//
//  Transport layer. One protocol, one concrete implementation. Feature services
//  depend on the protocol so they can be unit-tested against a mock client.
//
//  Responsibilities:
//   • Build URLRequest from Endpoint
//   • Attach Bearer token when endpoint.requiresAuth is true
//   • Send via URLSession
//   • Decode the ApiResponse<T> envelope
//   • On 401 (except for refresh endpoint itself): refresh via TokenRefreshCoordinator,
//     retry the original request once with the new token, then give up.
//

import Foundation

protocol HTTPClient: Sendable {
    /// Send a request expecting a non-empty payload back.
    func send<T: Decodable & Sendable>(_ endpoint: Endpoint) async throws -> T

    /// Send a request where we only care about success/failure.
    func sendVoid(_ endpoint: Endpoint) async throws
}

final class URLSessionHTTPClient: HTTPClient, @unchecked Sendable {

    private let baseURL: URL
    private let session: URLSession
    private let sessionStore: AuthSessionStore
    private let refreshCoordinator: TokenRefreshCoordinator?
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    /// Path used to detect "this is the refresh endpoint" — refresh failures must NOT
    /// trigger another refresh attempt (infinite recursion).
    private let refreshEndpointPath = "/Auth/refresh"

    init(
        baseURL: URL,
        session: URLSession = .shared,
        sessionStore: AuthSessionStore,
        refreshCoordinator: TokenRefreshCoordinator? = nil,
        decoder: JSONDecoder = .vexTrainer,
        encoder: JSONEncoder = .vexTrainer
    ) {
        self.baseURL = baseURL
        self.session = session
        self.sessionStore = sessionStore
        self.refreshCoordinator = refreshCoordinator
        self.decoder = decoder
        self.encoder = encoder
    }

    // MARK: - Public API

    func send<T: Decodable & Sendable>(_ endpoint: Endpoint) async throws -> T {
        let envelope: ApiResponse<T> = try await perform(endpoint, allowRefresh: true)
        guard envelope.success else {
            throw APIError.business(message: envelope.message)
        }
        guard let data = envelope.data else {
            throw APIError.missingData
        }
        return data
    }

    func sendVoid(_ endpoint: Endpoint) async throws {
        let envelope: ApiResponse<EmptyResponse> = try await perform(endpoint, allowRefresh: true)
        guard envelope.success else {
            throw APIError.business(message: envelope.message)
        }
    }

    // MARK: - Core request flow

    private func perform<T: Decodable & Sendable>(
        _ endpoint: Endpoint,
        allowRefresh: Bool
    ) async throws -> ApiResponse<T> {
        let request = try await buildRequest(for: endpoint)
        HTTPLogger.logRequest(request)

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch let urlError as URLError {
            HTTPLogger.logResponse(nil, data: nil, error: urlError)
            throw APIError.network(urlError)
        }

        HTTPLogger.logResponse(response, data: data, error: nil)

        guard let http = response as? HTTPURLResponse else {
            throw APIError.http(status: -1, message: "Non-HTTP response")
        }

        // 401 → attempt one silent refresh and retry, unless this WAS the refresh endpoint.
        if http.statusCode == 401,
           allowRefresh,
           endpoint.requiresAuth,
           !endpoint.path.contains(refreshEndpointPath),
           let refreshCoordinator {
            do {
                _ = try await refreshCoordinator.refresh()
            } catch {
                await sessionStore.clear()
                throw APIError.unauthorized
            }
            // Retry once with allowRefresh=false to prevent infinite recursion.
            return try await perform(endpoint, allowRefresh: false)
        }

        // After a failed retry: surface as unauthorized.
        if http.statusCode == 401 {
            await sessionStore.clear()
            throw APIError.unauthorized
        }

        // Other 4xx/5xx: try to extract a server message from the envelope, fall back
        // to a generic HTTP error.
        guard (200...299).contains(http.statusCode) else {
            let serverMessage = try? decoder
                .decode(ApiResponse<EmptyResponse>.self, from: data)
                .message
            throw APIError.http(status: http.statusCode, message: serverMessage)
        }

        do {
            return try decoder.decode(ApiResponse<T>.self, from: data)
        } catch let decodingError as DecodingError {
            throw APIError.decoding(decodingError)
        }
    }

    // MARK: - URLRequest construction

    private func buildRequest(for endpoint: Endpoint) async throws -> URLRequest {
        var components = URLComponents(
            url: baseURL.appendingPathComponent(endpoint.path),
            resolvingAgainstBaseURL: false
        )!
        if !endpoint.queryItems.isEmpty {
            components.queryItems = endpoint.queryItems
        }
        guard let url = components.url else {
            throw APIError.http(status: -1, message: "Invalid URL")
        }

        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        if let body = endpoint.body {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try encoder.encode(AnyEncodable(body))
        }

        if endpoint.requiresAuth, let token = await sessionStore.token() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        return request
    }
}

// MARK: - JSON coders

extension JSONDecoder {
    /// Project-standard decoder. The API returns ISO-8601-ish dates as strings; we
    /// keep them as String in DTOs (parsed lazily by the domain layer) so decoding
    /// stays forgiving across mild format variations.
    static var vexTrainer: JSONDecoder {
        let decoder = JSONDecoder()
        // Don't set keyDecodingStrategy — server already returns camelCase.
        return decoder
    }
}

extension JSONEncoder {
    static var vexTrainer: JSONEncoder {
        let encoder = JSONEncoder()
        return encoder
    }
}

// MARK: - Encodable existential helper

/// Workaround for `(any Encodable)?`  JSONEncoder can't encode the existential directly,
/// but it can encode a concrete wrapper that delegates to the underlying value.
private struct AnyEncodable: Encodable {
    private let encode: (Encoder) throws -> Void

    init(_ value: any Encodable) {
        self.encode = value.encode
    }

    func encode(to encoder: Encoder) throws {
        try encode(encoder)
    }
}
