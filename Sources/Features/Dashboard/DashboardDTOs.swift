//
//  DashboardDTOs.swift
//  VexTrainer
//
//  Wire-format types for /Lesson/app-dashboard. Field names match the server
//  schema verbatim (verified against the Android DTOs and the live response).
//

import Foundation

struct DashboardResponse: Decodable, Sendable {
    let stats: DashboardStats
    let continueLearning: [ContinueLearningItem]
    /// Nullable on the wire — server returns `null` when the user has no bookmarks
    /// yet, NOT an empty array.
    let bookmarks: [BookmarkItem]?
}

struct DashboardStats: Decodable, Sendable {
    let totalModules: Int
    let completedModules: Int
    let totalLessons: Int
    let completedLessons: Int
    let totalTopics: Int
    let topicsRead: Int
    let quizzesAttempted: Int
    let quizzesCompleted: Int
    let averageQuizScore: Double
    let bestQuizScore: Double
    let readingStreak: Int
    let modulesProgressPercent: Double
    let lessonsProgressPercent: Double
    let topicsProgressPercent: Double
}

struct ContinueLearningItem: Decodable, Sendable, Identifiable, Hashable {
    let lessonId: Int
    let lessonTitle: String
    let moduleId: Int
    let moduleName: String
    let topicsRead: Int
    let totalTopics: Int
    let nextTopicId: Int
    let nextTopicTitle: String

    /// Synthesized for SwiftUI's ForEach. Composite because a user could have
    /// multiple lessons in progress within the same module.
    var id: String { "\(moduleId)-\(lessonId)" }
}

struct BookmarkItem: Decodable, Sendable, Identifiable, Hashable {
    let moduleId: Int
    let moduleName: String
    let lessonId: Int
    let lessonTitle: String
    let topicId: Int
    let topicTitle: String

    var id: Int { topicId }
}
