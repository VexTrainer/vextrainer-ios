//
//  DashboardInvalidator.swift
//  VexTrainer
//
//  Process-wide signal used by other view models to tell the dashboard
//  that its data is stale. Other VMs (TopicViewerViewModel for bookmark
//  toggles and mark-as-read; QuizSessionViewModel for quiz completion)
//  call `markDirty()` after their network operations succeed. The
//  dashboard view observes `revision` via @Observable, reacts to every
//  bump, and re-fetches its data in the background — keeping the
//  existing data visible until the new payload arrives.
//
//  Why a monotonic Int counter rather than a Bool latch:
//
//  An earlier version of this used `isDirty: Bool` with markDirty()
//  setting true and the dashboard calling consume() to set it false
//  after refresh. That had a race condition: a markDirty() that fired
//  while a refresh was in flight could be clobbered when the refresh
//  completed and reset the flag. The counter approach is monotonic —
//  the dashboard remembers the last revision it processed, and any
//  larger revision is by construction unprocessed.
//
//  Why @Observable (rather than the previous "check the flag in
//  .onAppear" model):
//
//  In iOS 18+/iPadOS 18+ TabView, view lifecycle events like
//  .onAppear and .onDisappear are less reliable on tab transitions
//  than they were in iOS 16/17. Apple now intends developers to use
//  observable state to react to data changes rather than relying on
//  view lifecycle. The @Observable revision counter is the
//  recommended approach: when revision bumps, SwiftUI re-evaluates
//  any view that reads it, the dashboard's .onChange fires, and the
//  refresh kicks off — regardless of which tab is active or whether
//  the dashboard view's lifecycle has been invoked.
//

import Foundation
import Observation

@MainActor
@Observable
final class DashboardInvalidator {

    static let shared = DashboardInvalidator()

    /// Monotonically incremented every time something happens that the
    /// dashboard would care about. The dashboard view tracks its own
    /// `lastSeenRevision`; whenever this property exceeds that value,
    /// a refresh is needed.
    private(set) var revision: Int = 0

    private init() {}

    /// Called by other view models after a state change the dashboard
    /// would care about (read counts, streak, completed quizzes, etc.).
    func markDirty() {
        revision += 1
    }
}
