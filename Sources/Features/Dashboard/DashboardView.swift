//
//  DashboardView.swift
//  VexTrainer
//
//  Home tab content. NavigationStack path lives in MainShellView so that
//  tapping the Home tab returns the user to the dashboard root.
//

import SwiftUI

struct DashboardView: View {

    @State private var vm: DashboardViewModel
    let env: AppEnvironment
    let session: AuthSession
    @Binding var path: NavigationPath

    /// The DashboardInvalidator revision we've last reacted to. Initialized
    /// to whatever the singleton's current value is, so the very first
    /// render doesn't fire a spurious refresh — the initial fetch is
    /// handled by loadIfNeeded() / the .onAppear path below.
    @State private var lastSeenRevision: Int = DashboardInvalidator.shared.revision

    init(env: AppEnvironment, session: AuthSession, path: Binding<NavigationPath>) {
        _vm = State(initialValue: DashboardViewModel(service: env.dashboardService))
        self.env = env
        self.session = session
        self._path = path
    }

    var body: some View {
        NavigationStack(path: $path) {
            ZStack {
                Color.vexNavy.ignoresSafeArea()
                content
            }
            // No nav title — the dashboard greets the user with its own
            // "Welcome back, …" header at the top of the scroll content.
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: LessonRoute.self) { route in
                LessonRouter.destination(for: route, env: env)
            }
        }
        .environment(\.appNavigationPath, $path)
        .tint(Color.vexOrange)
        // Two triggers, one handler. Either firing is sufficient; both are
        // wired for defense in depth.
        //
        // .onChange — the primary trigger. When DashboardInvalidator.revision
        // bumps (because some other VM called markDirty()), SwiftUI's
        // Observation framework re-evaluates this view, .onChange fires,
        // and we kick off a background refresh. This works regardless of
        // which tab is currently active, because @Observable tracking
        // doesn't depend on the view being visible.
        //
        // .onAppear — backup. In iOS 18+/iPadOS 18+ TabView, .onAppear
        // got less reliable on tab transitions, so it's no longer
        // sufficient on its own. But for the cases where it DOES fire
        // (initial appearance most importantly), we want to either kick
        // off the first load or catch up on any revision changes that
        // happened while the view body wasn't being evaluated.
        .onChange(of: DashboardInvalidator.shared.revision) { _, _ in
            handleRevisionChange()
        }
        .onAppear {
            handleRevisionChange()
        }
    }

    /// Shared handler for both .onChange and .onAppear triggers. The
    /// `lastSeenRevision` check makes the function idempotent: firing
    /// it twice in succession won't cause two refreshes.
    private func handleRevisionChange() {
        let current = DashboardInvalidator.shared.revision
        if current != lastSeenRevision {
            lastSeenRevision = current
            // Background refresh — existing data stays visible while we
            // re-fetch. `refresh()` already uses `setLoadingState: false`
            // internally, so no spinner flash.
            Task { await vm.refresh() }
        } else if case .idle = vm.state {
            // First load. No revision change yet, but we don't have data
            // either, so kick off the initial fetch.
            Task { await vm.loadIfNeeded() }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch vm.state {
        case .idle, .loading:
            LoadingStateView()
        case .failed(let message):
            ErrorStateView(message: message) {
                await vm.loadIfNeeded()
            }
        case .loaded(let data):
            loaded(data)
        }
    }

    private func loaded(_ data: DashboardResponse) -> some View {
        ScrollView {
            VStack(spacing: 20) {
                greeting
                StreakBadge(days: data.stats.readingStreak)
                ProgressStatsCard(stats: data.stats)
                BookmarksSection(bookmarks: data.bookmarks ?? [])
                ContinueLearningSection(items: data.continueLearning)
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 24)
            .readableContentWidth(.ui)
        }
        .refreshable { await vm.refresh() }
    }

    private var greeting: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("Welcome back,")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.6))
            Text(session.userName.isEmpty ? "Friend" : session.userName)
                .font(.title2.weight(.bold))
                .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
