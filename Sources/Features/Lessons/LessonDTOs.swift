//
//  LessonDTOs.swift
//  VexTrainer
//
//  Wire-format types for /Lesson/* endpoints. Field names match the server
//  schema verbatim, derived from the Android DTOs.
//

import Foundation

// MARK: - Modules

struct ModuleSummary: Decodable, Sendable, Identifiable, Hashable {
    let moduleId: Int
    let moduleName: String
    let displayOrder: Int
    let description: String?
    let lessonCount: Int
    let completedLessons: Int

    var id: Int { moduleId }

    private enum CodingKeys: String, CodingKey {
        case moduleId, moduleName, displayOrder, description, lessonCount, completedLessons
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        moduleId = try c.decode(Int.self, forKey: .moduleId)
        moduleName = try c.decode(String.self, forKey: .moduleName)
        displayOrder = try c.decode(Int.self, forKey: .displayOrder)
        description = try c.decodeIfPresent(String.self, forKey: .description)
        // lessonCount / completedLessons may be missing on older backends — default to 0.
        lessonCount = (try? c.decode(Int.self, forKey: .lessonCount)) ?? 0
        completedLessons = (try? c.decode(Int.self, forKey: .completedLessons)) ?? 0
    }
}

// MARK: - Lessons

struct LessonSummary: Decodable, Sendable, Identifiable, Hashable {
    let lessonId: Int
    let lessonTitle: String
    let displayOrder: Int
    let topicCount: Int
    let completedTopics: Int
    let isCompleted: Bool

    var id: Int { lessonId }
}

// MARK: - Topics

struct TopicSummary: Decodable, Sendable, Identifiable, Hashable {
    let topicId: Int
    let topicTitle: String
    /// 3 = H3 (main topic), 4 = H4 (sub-topic). Used to visually indent sub-topics.
    let headingLevel: Int
    let displayOrder: Int
    let isRead: Bool
    let parentTopicTitle: String?

    var id: Int { topicId }
}

struct TopicDetails: Decodable, Sendable {
    let topicId: Int
    let topicTitle: String
    let headingLevel: Int
    /// Used to fetch markdown from
    /// `https://api.vextrainer.com/content/lessons/{fileName}.md`
    let fileName: String
    let isRead: Bool
    let isBookmarked: Bool
    let previousTopicId: Int?
    let previousTopicTitle: String?
    let previousFileName: String?
    let nextTopicId: Int?
    let nextTopicTitle: String?
    let nextFileName: String?
    let moduleId: Int
    let moduleName: String
    let lessonId: Int
    let lessonTitle: String
    let parentTopicTitle: String?

    private enum CodingKeys: String, CodingKey {
        case topicId, topicTitle, headingLevel, fileName, isRead, isBookmarked
        case previousTopicId, previousTopicTitle, previousFileName
        case nextTopicId, nextTopicTitle, nextFileName
        case moduleId, moduleName, lessonId, lessonTitle, parentTopicTitle
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        topicId = try c.decode(Int.self, forKey: .topicId)
        topicTitle = try c.decode(String.self, forKey: .topicTitle)
        headingLevel = try c.decode(Int.self, forKey: .headingLevel)
        fileName = try c.decode(String.self, forKey: .fileName)
        isRead = try c.decode(Bool.self, forKey: .isRead)
        isBookmarked = (try? c.decode(Bool.self, forKey: .isBookmarked)) ?? false
        previousTopicId = try c.decodeIfPresent(Int.self, forKey: .previousTopicId)
        previousTopicTitle = try c.decodeIfPresent(String.self, forKey: .previousTopicTitle)
        previousFileName = try c.decodeIfPresent(String.self, forKey: .previousFileName)
        nextTopicId = try c.decodeIfPresent(Int.self, forKey: .nextTopicId)
        nextTopicTitle = try c.decodeIfPresent(String.self, forKey: .nextTopicTitle)
        nextFileName = try c.decodeIfPresent(String.self, forKey: .nextFileName)
        moduleId = try c.decode(Int.self, forKey: .moduleId)
        moduleName = try c.decode(String.self, forKey: .moduleName)
        lessonId = try c.decode(Int.self, forKey: .lessonId)
        lessonTitle = try c.decode(String.self, forKey: .lessonTitle)
        parentTopicTitle = try c.decodeIfPresent(String.self, forKey: .parentTopicTitle)
    }
}

struct MarkReadResponse: Decodable, Sendable {
    let hasNextTopic: Bool
    let nextTopicUrl: String?
}
