//
//  LessonsSplitView.swift
//  VexTrainer
//
//  iPad-regular-size-class layout for the Lessons tab. Three columns:
//
//    ┌────────────┬─────────────┬──────────────────────────────┐
//    │  Modules   │  Lessons    │                              │
//    │  (sidebar) │  (content)  │       Topic content          │
//    │            │             │       (detail)               │
//    │            │             │                              │
//    └────────────┴─────────────┴──────────────────────────────┘
//
//  • Sidebar:  module list. Selecting one swaps the content column to
//              that module's lessons.
//  • Content:  has its own NavigationStack. Default content is the
//              lesson list for the selected module; tapping a lesson
//              pushes a topic list onto this same column. The topic
//              list lets the user select a topic, which populates
//              the detail column.
//  • Detail:   wraps TopicViewerView in a NavigationStack so the
//              feedback button (LessonRoute.feedbackForm) still
//              pushes onto the detail's stack as it does on iPhone.
//
//  Compact size class (iPhone, iPad in split-screen ≤50%) uses the
//  existing LessonsTabView NavigationStack layout. The switch happens
//  in LessonsTabView based on horizontalSizeClass.
//
//  Cross-tab navigation into specific topics (Dashboard's Continue
//  Learning, Activity Report streak badge) goes onto the originating
//  tab's NavigationStack, not the Lessons tab — those flows are
//  untouched and continue to work.
//

import SwiftUI

/// Lightweight reference to a lesson used as the value type for column 2's
/// NavigationStack. We can't push a full LessonSummary when crossing a
/// lesson boundary via prev/next (the only info we have is lessonId and
/// lessonTitle from TopicDetails — no displayOrder, topicCount, etc.).
/// TopicsContentColumn only reads id + title anyway, so a tiny reference
/// type is cleaner than constructing a placeholder LessonSummary with
/// fake counts.
private struct LessonRef: Hashable {
    let lessonId: Int
    let lessonTitle: String
}

struct LessonsSplitView: View {

    let env: AppEnvironment

    // Modules list lives here so the cross-boundary nav handler can look up
    // a ModuleSummary by id when the user navigates to a topic in a
    // different module. The sidebar is a passive presentation view.
    @State private var modules: [ModuleSummary] = []
    @State private var modulesLoading = false
    @State private var modulesError: String?

    // Sidebar selection — the user's currently-active module.
    @State private var selectedModule: ModuleSummary?

    // Detail selection — the topic shown in the right pane.
    @State private var selectedTopic: Int?

    // Content column's own nav stack (lesson list ↔ topic list).
    @State private var contentPath = NavigationPath()

    // Detail column's own nav stack (topic viewer ↔ feedback form, etc.).
    // We need an explicit binding rather than an implicit path because we
    // have to programmatically pop it back to root when the user picks a
    // different topic in column 2 — otherwise sub-screens pushed via
    // NavigationLink (the feedback form, most notably) stay on top of
    // the stack and the new topic loads invisibly underneath.
    @State private var detailPath = NavigationPath()

    /// Custom binding for the sidebar's `List(selection:)`. The setter
    /// resets the content column and detail when the user picks a
    /// different module manually — this replaces the old
    /// `.onChange(of: selectedModule?.moduleId)` modifier. We need a
    /// custom binding rather than .onChange because the cross-boundary
    /// callback ALSO writes to `selectedModule` (when an internal
    /// prev/next lands in a different module), and we DON'T want to
    /// reset content in that case — the callback is about to fill in
    /// the new lesson and topic itself. Direct assignment to
    /// `selectedModule` bypasses this setter; only the sidebar's
    /// List(selection:) routes through it.
    private var moduleSelection: Binding<ModuleSummary?> {
        Binding(
            get: { selectedModule },
            set: { newValue in
                selectedModule = newValue
                contentPath = NavigationPath()
                selectedTopic = nil
                detailPath = NavigationPath()
            }
        )
    }

    var body: some View {
        NavigationSplitView {
            ModuleSidebarColumn(
                modules: modules,
                isLoading: modulesLoading,
                error: modulesError,
                selection: moduleSelection,
                onRetry: { Task { await loadModules() } }
            )
            .navigationTitle("Modules")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(Color.vexNavy, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        } content: {
            NavigationStack(path: $contentPath) {
                Group {
                    if let module = selectedModule {
                        LessonsContentColumn(
                            env: env,
                            moduleId: module.moduleId,
                            moduleName: module.moduleName,
                            selectedTopic: $selectedTopic
                        )
                    } else {
                        ContentUnavailableView(
                            "Select a module",
                            systemImage: "books.vertical.fill",
                            description: Text("Choose a module from the sidebar to see its lessons.")
                        )
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.vexNavy)
                    }
                }
                .navigationDestination(for: LessonRef.self) { ref in
                    TopicsContentColumn(
                        env: env,
                        lessonId: ref.lessonId,
                        lessonTitle: ref.lessonTitle,
                        selectedTopic: $selectedTopic
                    )
                }
            }
        } detail: {
            NavigationStack(path: $detailPath) {
                if let topicId = selectedTopic {
                    TopicViewerView(
                        env: env,
                        topicId: topicId,
                        onTopicChange: { details in
                            handleTopicChange(details)
                        }
                    )
                    .navigationDestination(for: LessonRoute.self) { route in
                        // Reuse the existing router so the feedback button,
                        // streak target, etc. all work inside the detail column.
                        LessonRouter.destination(for: route, env: env)
                    }
                } else {
                    ContentUnavailableView(
                        "Select a topic",
                        systemImage: "doc.text",
                        description: Text("Pick a topic from a lesson to read it here.")
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.vexNavy)
                }
            }
        }
        .navigationSplitViewStyle(.balanced)
        .tint(Color.vexOrange)
        .task { await loadModules() }
        // Whenever the displayed topic changes — whether the user picked
        // a different topic in column 2, or internal prev/next inside
        // the topic viewer advanced it via the callback — pop the
        // detail column's nav stack back to the topic viewer root.
        // Without this, sub-screens previously pushed onto the detail
        // stack (notably the feedback form via the bubble toolbar
        // icon) stay on top, hiding the newly-loaded topic.
        .onChange(of: selectedTopic) { _, _ in
            detailPath = NavigationPath()
        }
    }

    /// Called when the user navigates inside the topic viewer (prev/next,
    /// mark-as-read auto-advance) and the new topic differs from what's
    /// currently displayed. Updates selection state so column 2's lesson
    /// list and the sidebar's module highlight follow along, including
    /// across lesson and module boundaries.
    private func handleTopicChange(_ details: TopicDetails) {
        // 1. Selected topic: always updates. This drives column 2's
        //    highlight when the new topic is in the visible lesson list.
        selectedTopic = details.topicId

        // 2. Module: if the new topic is in a different module, switch
        //    the sidebar selection. Direct assignment bypasses the
        //    moduleSelection custom binding's reset logic — we're about
        //    to set contentPath ourselves below.
        if selectedModule?.moduleId != details.moduleId,
           let newModule = modules.first(where: { $0.moduleId == details.moduleId }) {
            selectedModule = newModule
        }

        // 3. Lesson: replace the content path with the lesson containing
        //    the new topic. If the lesson is the same as what's currently
        //    on top of the path, LessonRef equality means SwiftUI doesn't
        //    re-create the destination — a no-op for same-lesson prev/next.
        //    If different, column 2 swaps to the new lesson's topic list.
        let ref = LessonRef(lessonId: details.lessonId, lessonTitle: details.lessonTitle)
        contentPath = NavigationPath([ref])
    }

    private func loadModules() async {
        guard modules.isEmpty else { return }
        modulesLoading = true
        defer { modulesLoading = false }
        modulesError = nil
        do {
            modules = try await env.lessonService.fetchModules()
        } catch let apiError as APIError {
            modulesError = apiError.localizedDescription
        } catch {
            modulesError = error.localizedDescription
        }
    }
}


// MARK: - Sidebar: modules (now a passive presentation view)

private struct ModuleSidebarColumn: View {
    let modules: [ModuleSummary]
    let isLoading: Bool
    let error: String?
    @Binding var selection: ModuleSummary?
    let onRetry: () -> Void

    var body: some View {
        ZStack {
            Color.vexNavy.ignoresSafeArea()
            content
        }
    }

    @ViewBuilder
    private var content: some View {
        if isLoading && modules.isEmpty {
            ProgressView().tint(.white)
        } else if let error, modules.isEmpty {
            ErrorStateView(message: error) { onRetry() }
        } else {
            List(selection: $selection) {
                ForEach(modules) { module in
                    moduleRow(module).tag(module)
                }
            }
            .listStyle(.sidebar)
            .scrollContentBackground(.hidden)
            .background(Color.vexNavy)
        }
    }

    private func moduleRow(_ module: ModuleSummary) -> some View {
        HStack(alignment: .center, spacing: 10) {
            VStack(alignment: .leading, spacing: 4) {
                Text(module.moduleName)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.white)
                    .lineLimit(2)
                Text("\(module.completedLessons) / \(module.lessonCount) lessons")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.55))
                    .monospacedDigit()
            }
            Spacer(minLength: 4)
            if module.lessonCount > 0, module.completedLessons == module.lessonCount {
                Image(systemName: "checkmark.circle.fill")
                    .font(.subheadline)
                    .foregroundStyle(Color.vexGreen)
            }
        }
        .padding(.vertical, 2)
    }
}


// MARK: - Content (middle): lesson list for selected module

private struct LessonsContentColumn: View {
    let env: AppEnvironment
    let moduleId: Int
    let moduleName: String
    @Binding var selectedTopic: Int?

    @State private var lessons: [LessonSummary] = []
    @State private var isLoading = false
    @State private var error: String?

    var body: some View {
        ZStack {
            Color.vexNavy.ignoresSafeArea()
            content
        }
        .navigationTitle(moduleName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbarBackground(Color.vexNavy, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        // Re-fetch when the parent swaps to a different module.
        .task(id: moduleId) { await load() }
    }

    @ViewBuilder
    private var content: some View {
        if isLoading && lessons.isEmpty {
            ProgressView().tint(.white)
        } else if let error, lessons.isEmpty {
            ErrorStateView(message: error) { await load() }
        } else {
            ScrollView {
                LazyVStack(spacing: 10) {
                    ForEach(lessons) { lesson in
                        // Push a lightweight LessonRef instead of the full
                        // LessonSummary so the same navigation destination
                        // can be reached from either a user tap here OR a
                        // cross-boundary topic-viewer nav, where we only
                        // have id + title from TopicDetails.
                        NavigationLink(value: LessonRef(
                            lessonId: lesson.lessonId,
                            lessonTitle: lesson.lessonTitle
                        )) {
                            lessonRow(lesson)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
            }
            .refreshable { await load() }
        }
    }

    private func lessonRow(_ lesson: LessonSummary) -> some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(lesson.lessonTitle)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.leading)
                Text("\(lesson.completedTopics) / \(lesson.topicCount) topics")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.55))
                    .monospacedDigit()
            }
            Spacer(minLength: 8)
            if lesson.isCompleted {
                Image(systemName: "checkmark.circle.fill")
                    .font(.subheadline)
                    .foregroundStyle(Color.vexGreen)
            } else {
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white.opacity(0.35))
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(.white.opacity(0.1), lineWidth: 1)
        )
    }

    private func load() async {
        isLoading = true
        defer { isLoading = false }
        error = nil
        do {
            lessons = try await env.lessonService.fetchLessons(moduleId: moduleId)
        } catch let apiError as APIError {
            self.error = apiError.localizedDescription
        } catch {
            self.error = error.localizedDescription
        }
    }
}


// MARK: - Content (middle, drilled in): topic list for selected lesson

private struct TopicsContentColumn: View {
    let env: AppEnvironment
    let lessonId: Int
    let lessonTitle: String
    @Binding var selectedTopic: Int?

    @State private var topics: [TopicSummary] = []
    @State private var isLoading = false
    @State private var error: String?

    var body: some View {
        ZStack {
            Color.vexNavy.ignoresSafeArea()
            content
        }
        .navigationTitle(lessonTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbarBackground(Color.vexNavy, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .task(id: lessonId) { await load() }
    }

    @ViewBuilder
    private var content: some View {
        if isLoading && topics.isEmpty {
            ProgressView().tint(.white)
        } else if let error, topics.isEmpty {
            ErrorStateView(message: error) { await load() }
        } else {
            // Note: we deliberately do NOT use `List(selection:)` here.
            // In `.listStyle(.plain)` on iPadOS 26 with our `.tint(.vexOrange)`,
            // SwiftUI's selection indicator renders as a thin orange bar
            // that bleeds across the column divider — visually ugly and
            // can look like it spans into the sidebar. Plain List selection
            // is finicky on iPad in general. A button-driven ScrollView
            // with our own brand-color selection state is cleaner and
            // gives us full control of the look.
            ScrollView {
                LazyVStack(spacing: 6) {
                    ForEach(topics) { topic in
                        Button {
                            selectedTopic = topic.topicId
                        } label: {
                            topicRow(topic, isSelected: selectedTopic == topic.topicId)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
            }
            .refreshable { await load() }
        }
    }

    private func topicRow(_ topic: TopicSummary, isSelected: Bool) -> some View {
        HStack(alignment: .center, spacing: 10) {
            // H4 sub-topics get a small left indent so the visual hierarchy
            // matches the lesson reader on iPhone.
            if topic.headingLevel >= 4 {
                Color.clear.frame(width: 16)
            }
            Text(topic.topicTitle)
                .font(topic.headingLevel >= 4 ? .footnote : .subheadline.weight(.medium))
                .foregroundStyle(.white)
                .lineLimit(3)
                .multilineTextAlignment(.leading)
            Spacer(minLength: 8)
            if topic.isRead {
                Image(systemName: "checkmark.circle.fill")
                    .font(.caption)
                    .foregroundStyle(Color.vexGreen.opacity(0.85))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(isSelected ? Color.vexCyan.opacity(0.18) : Color.white.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(isSelected ? Color.vexCyan : .white.opacity(0.06), lineWidth: 1.5)
        )
    }

    private func load() async {
        isLoading = true
        defer { isLoading = false }
        error = nil
        do {
            topics = try await env.lessonService.fetchTopics(lessonId: lessonId)
        } catch let apiError as APIError {
            self.error = apiError.localizedDescription
        } catch {
            self.error = error.localizedDescription
        }
    }
}
