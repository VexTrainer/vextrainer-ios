//
//  QuizzesTabView.swift
//  VexTrainer
//
//  Quizzes tab root. Path is lifted to MainShellView so tab tap pops to
//  root. The path binding is also exposed via Environment so the quiz
//  flow (QuizDetailContentView → session → results) can push and replace
//  entries programmatically.
//

import SwiftUI

struct QuizzesTabView: View {

    @Environment(AppEnvironment.self) private var env
    @Binding var path: NavigationPath

    var body: some View {
        NavigationStack(path: $path) {
            CategoryListView(env: env)
                .navigationTitle("Quizzes")
                .navigationBarTitleDisplayMode(.inline)
                .toolbarColorScheme(.dark, for: .navigationBar)
                .toolbarBackground(Color.vexNavy, for: .navigationBar)
                .toolbarBackground(.visible, for: .navigationBar)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        NavigationLink(value: QuizRoute.quizHistory) {
                            Image(systemName: "clock.arrow.circlepath")
                                .foregroundStyle(.white.opacity(0.85))
                        }
                        .accessibilityLabel("Quiz history")
                    }
                }
                .navigationDestination(for: QuizRoute.self) { route in
                    QuizRouter.destination(for: route, env: env)
                }
        }
        .environment(\.appNavigationPath, $path)
        .tint(Color.vexOrange)
    }
}
