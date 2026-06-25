//
//  LessonsTabView.swift
//  VexTrainer
//
//  Lessons tab root. Path lives in MainShellView (lifted) so tapping
//  the tab pops to root; inline title stays visible on scroll.
//

import SwiftUI
import UIKit

struct LessonsTabView: View {

    @Environment(AppEnvironment.self) private var env
    @Binding var path: NavigationPath

    /// iPadOS 18+/26 reports `horizontalSizeClass == .compact` to views
    /// nested inside a TabView even on a full-screen iPad Pro — Apple
    /// intends the new TabView itself to be the iPad-adaptive container.
    /// We branch on UIDevice.userInterfaceIdiom instead, which is
    /// reported correctly regardless of the parent container. iPad in
    /// slide-over still gets the split layout; NavigationSplitView
    /// collapses columns gracefully when too narrow.
    private var isIPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }

    var body: some View {
        if isIPad {
            // iPad — three-column split layout. Note: the tab path passed in
            // from MainShellView isn't used here because split view manages
            // its own column-state. Tab tap pop-to-root behavior on the iPad
            // layout means "clear sidebar selection", handled inside
            // LessonsSplitView via its own state.
            LessonsSplitView(env: env)
                .environment(\.appNavigationPath, $path)
        } else {
            // iPhone — existing single-column stack.
            NavigationStack(path: $path) {
                ModuleListView(env: env)
                    .navigationTitle("Lessons")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbarColorScheme(.dark, for: .navigationBar)
                    .toolbarBackground(Color.vexNavy, for: .navigationBar)
                    .toolbarBackground(.visible, for: .navigationBar)
                    .navigationDestination(for: LessonRoute.self) { route in
                        LessonRouter.destination(for: route, env: env)
                    }
            }
            .environment(\.appNavigationPath, $path)
            .tint(Color.vexOrange)
        }
    }
}
