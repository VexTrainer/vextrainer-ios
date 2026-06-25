//
//  LessonRoute.swift
//  VexTrainer
//
//  Navigation route values for the Lessons feature. Both the Lessons tab and
//  the Dashboard tab register a `.navigationDestination(for: LessonRoute.self)`
//  so cards and links anywhere in the app push to the same destination views.
//

import Foundation
import SwiftUI

enum LessonRoute: Hashable {
    case lessonList(moduleId: Int, moduleName: String)
    case topicList(lessonId: Int, lessonTitle: String)
    case topicViewer(topicId: Int)
    /// Streak badge tap target — the 7-day activity report.
    case activityReport
    /// Topic-page feedback button. Renders ContactUsView inside the
    /// current tab's stack with the message field pre-populated with
    /// the module/lesson/topic context.
    case feedbackForm(initialMessage: String)
}

/// Central place that maps a LessonRoute to its destination view. Used in
/// `.navigationDestination(for: LessonRoute.self)` from any NavigationStack
/// that needs to navigate to lesson content (Lessons tab, Dashboard, etc.).
enum LessonRouter {
    @ViewBuilder
    static func destination(for route: LessonRoute, env: AppEnvironment) -> some View {
        switch route {
        case .lessonList(let moduleId, let moduleName):
            LessonListView(env: env, moduleId: moduleId, moduleName: moduleName)
        case .topicList(let lessonId, let lessonTitle):
            TopicListView(env: env, lessonId: lessonId, lessonTitle: lessonTitle)
        case .topicViewer(let topicId):
            TopicViewerView(env: env, topicId: topicId)
        case .activityReport:
            ActivityReportView(env: env)
        case .feedbackForm(let initialMessage):
            // Bridge: ContactUsView needs an AuthSession for its
            // identity card, but the lesson router doesn't have one
            // passed in. We pull it from AppRouter.route, which is
            // always `.authenticated(session)` when this route is
            // reachable.
            FeedbackFormBridge(env: env, initialMessage: initialMessage)
        }
    }
}

/// Wires ContactUsView into the LessonRouter by sourcing AuthSession
/// from AppRouter rather than requiring it as a router parameter.
private struct FeedbackFormBridge: View {
    let env: AppEnvironment
    let initialMessage: String

    @Environment(AppRouter.self) private var router

    var body: some View {
        if case let .authenticated(session) = router.route {
            ContactUsView(env: env, session: session, initialMessage: initialMessage)
        } else {
            // Defensive: only reachable from the authenticated stack.
            ErrorStateView(message: "Session unavailable.", retry: nil)
        }
    }
}
