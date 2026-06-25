//
//  ActivityReportModels.swift
//  VexTrainer
//
//  Grouped domain shapes built from the flat DTO lists.
//
//    DayActivity
//      ├── modules: [ModuleActivity]  ── topics read, hierarchical
//      │     └── lessons: [LessonActivity]
//      │           └── topics: [ActivityTopic]
//      └── quizzes: [ActivityQuiz]    ── flat list per day
//
//  Date key is the first 10 chars of the server's date string (e.g.
//  "2026-05-30"), used both as a stable identifier for ForEach and as
//  the input for "Today" / "Yesterday" / "Month d, yyyy" label resolution.
//

import Foundation

struct DayActivity: Identifiable, Hashable {
    let dateKey: String                 // "2026-05-30"
    let modules: [ModuleActivity]
    let quizzes: [ActivityQuiz]

    var id: String { dateKey }
}

struct ModuleActivity: Identifiable, Hashable {
    let moduleId: Int
    let moduleName: String
    let lessons: [LessonActivity]

    var id: Int { moduleId }
}

struct LessonActivity: Identifiable, Hashable {
    let lessonId: Int
    let lessonTitle: String
    let topics: [ActivityTopic]

    var id: Int { lessonId }
}

struct ActivityTopic: Identifiable, Hashable {
    let topicId: Int
    let topicTitle: String

    var id: Int { topicId }
}

struct ActivityQuiz: Identifiable, Hashable {
    let quizId: Int
    let quizTitle: String
    let bestScore: Double?
    let isCompleted: Bool
    let attemptCount: Int

    var id: Int { quizId }
}

// MARK: - DTO → Domain grouping

enum ActivityReportGrouper {

    /// Takes the flat DTO response and groups it into the day hierarchy.
    /// Days are sorted newest-first; modules/lessons inside each day are
    /// sorted by ID ascending (the order they were created on the server,
    /// which matches the curriculum order).
    static func group(_ report: StreakBadgeReportDTO) -> [DayActivity] {
        let topicsByDate  = Dictionary(grouping: report.topics)  { dateKey(from: $0.readDate)    }
        let quizzesByDate = Dictionary(grouping: report.quizzes) { dateKey(from: $0.attemptDate) }

        let allDates = Set(topicsByDate.keys).union(quizzesByDate.keys)
            .sorted(by: >)  // newest first

        return allDates.map { date in
            let dayTopics  = topicsByDate[date]  ?? []
            let dayQuizzes = quizzesByDate[date] ?? []

            let modules = groupTopicsByModule(dayTopics)
            let quizzes = dayQuizzes.map {
                ActivityQuiz(
                    quizId: $0.quizId,
                    quizTitle: $0.quizTitle,
                    bestScore: $0.bestScore,
                    isCompleted: $0.isCompleted,
                    attemptCount: $0.attemptCount
                )
            }

            return DayActivity(dateKey: date, modules: modules, quizzes: quizzes)
        }
    }

    private static func groupTopicsByModule(_ topics: [ActivityTopicItemDTO]) -> [ModuleActivity] {
        // Group by moduleId; within each module, group by lessonId.
        // Use first occurrence's name/title to avoid empty strings if a
        // later row's denormalised value were missing.
        let byModule = Dictionary(grouping: topics, by: { $0.moduleId })
        return byModule.keys.sorted().map { moduleId in
            let rows = byModule[moduleId] ?? []
            let moduleName = rows.first?.moduleName ?? ""
            let byLesson = Dictionary(grouping: rows, by: { $0.lessonId })
            let lessons = byLesson.keys.sorted().map { lessonId in
                let lessonRows = byLesson[lessonId] ?? []
                let lessonTitle = lessonRows.first?.lessonTitle ?? ""
                let topics = lessonRows.map {
                    ActivityTopic(topicId: $0.topicId, topicTitle: $0.topicTitle)
                }
                return LessonActivity(lessonId: lessonId, lessonTitle: lessonTitle, topics: topics)
            }
            return ModuleActivity(moduleId: moduleId, moduleName: moduleName, lessons: lessons)
        }
    }

    /// Extract YYYY-MM-DD from a server datetime like "2026-05-30T00:00:00".
    /// Tolerates any prefix-style ISO date — we only need the first 10 chars.
    private static func dateKey(from serverDate: String) -> String {
        String(serverDate.prefix(10))
    }
}

// MARK: - Date label formatting

enum ActivityDateLabel {

    /// Converts a "YYYY-MM-DD" key into the user-facing label: "Today",
    /// "Yesterday", or "May 30, 2026". Locale-aware on the long form.
    static func label(for dateKey: String, calendar: Calendar = .current) -> String {
        let parser = DateFormatter()
        parser.dateFormat = "yyyy-MM-dd"
        parser.timeZone = calendar.timeZone
        parser.locale = Locale(identifier: "en_US_POSIX")  // fixed format parsing

        guard let date = parser.date(from: dateKey) else { return dateKey }

        if calendar.isDateInToday(date) { return "Today" }
        if calendar.isDateInYesterday(date) { return "Yesterday" }

        let display = DateFormatter()
        display.dateStyle = .long
        display.timeStyle = .none
        display.locale = .current
        display.timeZone = calendar.timeZone
        return display.string(from: date)
    }
}
