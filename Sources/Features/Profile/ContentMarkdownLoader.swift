//
//  ContentMarkdownLoader.swift
//  VexTrainer
//
//  Tiny helper to fetch public markdown content (about.md, privacy.md).
//  These files live on the public web host (vextrainer.com/content/),
//  not the API host — no auth, no ApiResponse envelope, just plain
//  text. Uses URLSession directly so it bypasses the authenticated
//  HTTPClient chain.
//

import Foundation

enum ContentMarkdownLoader {
    static func fetch(url: URL, session: URLSession = .shared) async throws -> String {
        var request = URLRequest(url: url)
        request.cachePolicy = .reloadRevalidatingCacheData

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch let urlError as URLError {
            throw APIError.network(urlError)
        }

        guard let http = response as? HTTPURLResponse else {
            throw APIError.http(status: -1, message: "Non-HTTP response from content server")
        }
        guard (200...299).contains(http.statusCode) else {
            throw APIError.http(status: http.statusCode, message: "Couldn't load content (HTTP \(http.statusCode))")
        }
        guard let text = String(data: data, encoding: .utf8) else {
            throw APIError.http(status: -1, message: "Content isn't valid UTF-8")
        }
        return text
    }
}
