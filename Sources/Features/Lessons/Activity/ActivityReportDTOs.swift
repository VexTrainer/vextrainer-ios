//
//  ActivityReportDTOs.swift
//  VexTrainer
//
//  Wire types for GET /Lesson/streak-report. Shape matches the Android
//  client's Moshi DTOs and the .NET StreakBadgeReport model exactly.
//
//  Server returns dates already converted to the caller's local timezone
//  (we send timezoneOffsetMinutes as a query parameter). The date strings
//  look like "2026-05-30T00:00:00" — we use the first 10 chars (YYYY-MM-DD)
//  as the grouping key.
//

import Foundation

struct StreakBadgeReportDTO: Decodable, Sendable {
    let topics: [ActivityTopicItemDTO]
    let quizzes: [ActivityQuizItemDTO]
}

struct ActivityTopicItemDTO: Decodable, Sendable {
    let readDate: String        // "2026-05-30T00:00:00"
    let moduleId: Int
    let moduleName: String
    let lessonId: Int
    let lessonTitle: String
    let topicId: Int
    let topicTitle: String
}

struct ActivityQuizItemDTO: Decodable, Sendable {
    let attemptDate: String     // "2026-06-02T00:00:00"
    let quizId: Int
    let quizTitle: String
    let bestScore: Double?      // null when all attempts on this day are incomplete
    let isCompleted: Bool       // true if any attempt on this day completed
    let attemptCount: Int       // > 1 → display "(Nx)" suffix
    let latestAttemptId: Int
}
