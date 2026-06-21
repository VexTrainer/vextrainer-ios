//
//  AppNavigationPath.swift
//  VexTrainer
//
//  Environment plumbing for the current tab's NavigationPath. The path
//  state lives in MainShellView (so we can reset on tab tap), and we
//  expose it via Environment to deeply-nested views that need to push
//  or pop programmatically — like QuizDetailContentView pushing the
//  session, and QuizSessionView replacing session with results on
//  completion. Each tab sets `.environment(\.appNavigationPath, $path)`
//  on its NavigationStack root.
//

import SwiftUI

private struct AppNavigationPathKey: EnvironmentKey {
    static let defaultValue: Binding<NavigationPath> = .constant(NavigationPath())
}

extension EnvironmentValues {
    var appNavigationPath: Binding<NavigationPath> {
        get { self[AppNavigationPathKey.self] }
        set { self[AppNavigationPathKey.self] = newValue }
    }
}
