//
//  MainShellView.swift
//  VexTrainer
//
//  Authenticated root. Owns the NavigationPath of each tab so we can:
//    1. Reset the destination tab's path to root on EVERY tab tap (matches
//       the Android behavior — tapping a tab always lands on its home page,
//       regardless of where the user was before). This handles both
//       different-tab taps (resetting the new tab) and same-tab taps
//       (acting as a scroll-to-top / pop-to-root gesture).
//    2. Hand a Binding<NavigationPath> down to each tab so deeply-nested
//       views can push/pop programmatically via @Environment(\.appNavigationPath).
//

import SwiftUI

enum AppTab: Hashable {
    case home, lessons, quizzes, profile
}

struct MainShellView: View {

    @Environment(AppEnvironment.self) private var env

    let session: AuthSession

    @State private var selection: AppTab = .home
    @State private var homePath = NavigationPath()
    @State private var lessonsPath = NavigationPath()
    @State private var quizzesPath = NavigationPath()
    @State private var profilePath = NavigationPath()

    /// Cross-tab navigation signal. ActivityReportView sets
    /// `pendingQuizDetail = quizId`; we handle it below by resetting the
    /// Quizzes path, pushing the route, and switching tabs.
    @State private var crossTab = CrossTabRouter()

    var body: some View {
        TabView(selection: selectionBinding) {
            DashboardView(env: env, session: session, path: $homePath)
                .tabItem {
                    Label("Home", image: "LogoVexTrainerTab")
                }
                .tag(AppTab.home)

            LessonsTabView(path: $lessonsPath)
                .tabItem {
                    Label("Lessons", systemImage: "book.fill")
                }
                .tag(AppTab.lessons)

            QuizzesTabView(path: $quizzesPath)
                .tabItem {
                    Label("Quizzes", systemImage: "questionmark.circle.fill")
                }
                .tag(AppTab.quizzes)

            ProfileTabView(session: session, path: $profilePath)
                .tabItem {
                    Label("Profile", systemImage: "person.crop.circle.fill")
                }
                .tag(AppTab.profile)
        }
        .tint(Color.vexOrange)
        .environment(crossTab)
        .onChange(of: crossTab.pendingQuizDetail) { _, newValue in
            // Activity Report → quiz: reset Quizzes path so the loader is
            // the only entry, switch to Quizzes tab, then clear the signal.
            // Direct selection assignment bypasses selectionBinding, which
            // would otherwise re-reset the path we just set.
            if let quizId = newValue {
                quizzesPath = NavigationPath()
                quizzesPath.append(QuizRoute.quizDetailFromId(quizId: quizId))
                selection = .quizzes
                crossTab.pendingQuizDetail = nil
            }
        }
    }

    /// Wraps the selection so we can intercept EVERY tab tap — including
    /// same-tab taps that wouldn't fire `.onChange(of: selection)` — and
    /// reset that tab's path to the empty (root) state.
    private var selectionBinding: Binding<AppTab> {
        Binding(
            get: { selection },
            set: { newValue in
                switch newValue {
                case .home:     homePath     = NavigationPath()
                case .lessons:  lessonsPath  = NavigationPath()
                case .quizzes:  quizzesPath  = NavigationPath()
                case .profile:  profilePath  = NavigationPath()
                }
                selection = newValue
            }
        )
    }
}
