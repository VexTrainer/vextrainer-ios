//
//  CrossTabRouter.swift
//  VexTrainer
//
//  Lightweight signal for cross-tab navigation. The Activity Report
//  (rendered inside the Home tab's NavigationStack) needs to open
//  QuizDetail in the Quizzes tab when the user taps a quiz row.
//
//  Rather than refactoring the per-tab NavigationPath ownership, we
//  use this Observable as a one-shot signal: callers set
//  `pendingQuizDetail = quizId`, MainShellView observes the change,
//  resets the Quizzes path, pushes the route, switches the selected
//  tab, then clears the signal.
//

import Foundation
import Observation

@Observable
@MainActor
final class CrossTabRouter {
    /// Set non-nil to request: switch to Quizzes tab, reset its path,
    /// push `.quizDetailFromId(quizId:)`. MainShellView clears this
    /// back to nil after handling.
    var pendingQuizDetail: Int?
}
