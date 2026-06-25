//
//  LessonService.swift
//  VexTrainer
//

import Foundation

protocol LessonServicing: Sendable {
    func fetchModules() async throws -> [ModuleSummary]
    func fetchLessons(moduleId: Int) async throws -> [LessonSummary]
    func fetchTopics(lessonId: Int) async throws -> [TopicSummary]
    func fetchTopicDetails(topicId: Int) async throws -> TopicDetails
    func fetchTopicMarkdown(fileName: String) async throws -> String
    func markTopicRead(topicId: Int) async throws
    func addBookmark(topicId: Int) async throws
    func removeBookmark(topicId: Int) async throws
    func fetchStreakReport(timezoneOffsetMinutes: Int) async throws -> StreakBadgeReportDTO
}

final class LessonService: LessonServicing, @unchecked Sendable {

    private let http: HTTPClient
    private let session: URLSession

    init(http: HTTPClient, session: URLSession = .shared) {
        self.http = http
        self.session = session
    }

    // MARK: - API-backed reads

    func fetchModules() async throws -> [ModuleSummary] {
        try await http.send(.modules)
    }

    func fetchLessons(moduleId: Int) async throws -> [LessonSummary] {
        try await http.send(.lessons(moduleId: moduleId))
    }

    func fetchTopics(lessonId: Int) async throws -> [TopicSummary] {
        try await http.send(.topics(lessonId: lessonId))
    }

    func fetchTopicDetails(topicId: Int) async throws -> TopicDetails {
        try await http.send(.topicDetails(topicId: topicId))
    }

    // MARK: - Content (markdown) fetch — bypasses the ApiResponse envelope

    /// Markdown content lives at https://vextrainer.com/content/lessons/{fileName}.md
    /// as plain text — no ApiResponse wrapper. We use URLSession directly here.
    ///
    /// In-memory LRU cache (MarkdownCache.shared) wraps the network
    /// fetch. Cached entries return immediately on next access, which
    /// makes back-flipping and re-reading inside a lesson feel
    /// instant. Cache is keyed by full URL so different files never
    /// collide; capacity 20 (set on the cache itself) keeps the
    /// memory footprint bounded at roughly 1MB worst-case.
    func fetchTopicMarkdown(fileName: String) async throws -> String {
        let url = AppConfig.contentBaseURL.appendingPathComponent("lessons/\(fileName).md")
        let cacheKey = url.absoluteString

        if let cached = await MarkdownCache.shared.get(cacheKey) {
            return cached
        }

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
            throw APIError.http(status: http.statusCode, message: "Couldn't load topic content")
        }
        guard let text = String(data: data, encoding: .utf8) else {
            throw APIError.http(status: -1, message: "Topic content isn't valid UTF-8")
        }

        await MarkdownCache.shared.set(cacheKey, text)
        return text
    }

    // MARK: - Writes

    func markTopicRead(topicId: Int) async throws {
        // Server returns `{success:true, data:null, message:"Topic marked as read"}`.
        // Use sendVoid because there's no meaningful payload to decode.
        try await http.sendVoid(.markTopicRead(topicId: topicId))
    }

    func addBookmark(topicId: Int) async throws {
        try await http.sendVoid(.addBookmark(topicId: topicId))
    }

    func removeBookmark(topicId: Int) async throws {
        try await http.sendVoid(.removeBookmark(topicId: topicId))
    }

    // MARK: - Streak / activity report

    func fetchStreakReport(timezoneOffsetMinutes: Int) async throws -> StreakBadgeReportDTO {
        try await http.send(.streakReport(timezoneOffsetMinutes: timezoneOffsetMinutes))
    }
}

// MARK: - Endpoint factories

private extension Endpoint {
    static var modules: Endpoint {
        Endpoint(path: "/Lesson/modules", method: .get, requiresAuth: true)
    }
    static func lessons(moduleId: Int) -> Endpoint {
        Endpoint(path: "/Lesson/modules/\(moduleId)/lessons", method: .get, requiresAuth: true)
    }
    static func topics(lessonId: Int) -> Endpoint {
        Endpoint(path: "/Lesson/lessons/\(lessonId)/topics", method: .get, requiresAuth: true)
    }
    static func topicDetails(topicId: Int) -> Endpoint {
        Endpoint(path: "/Lesson/topics/\(topicId)/details", method: .get, requiresAuth: true)
    }
    static func markTopicRead(topicId: Int) -> Endpoint {
        Endpoint(path: "/Lesson/topics/\(topicId)/mark-read", method: .post, requiresAuth: true)
    }
    static func addBookmark(topicId: Int) -> Endpoint {
        Endpoint(path: "/Lesson/topics/\(topicId)/bookmark", method: .post, requiresAuth: true)
    }
    static func removeBookmark(topicId: Int) -> Endpoint {
        Endpoint(path: "/Lesson/topics/\(topicId)/bookmark", method: .delete, requiresAuth: true)
    }
    static func streakReport(timezoneOffsetMinutes: Int) -> Endpoint {
        Endpoint(
            path: "/Lesson/streak-report",
            method: .get,
            queryItems: [
                URLQueryItem(name: "timezoneOffsetMinutes", value: "\(timezoneOffsetMinutes)")
            ],
            requiresAuth: true
        )
    }
}
