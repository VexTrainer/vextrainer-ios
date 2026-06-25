//
//  TopicViewerView.swift
//  VexTrainer
//
//  The reading screen. Renders markdown content with custom theme + code
//  syntax highlighting. Top-right toolbar has the bookmark toggle.
//  Footer has the Mark-as-Read button and Prev/Next navigation.
//

import SwiftUI
import MarkdownUI

struct TopicViewerView: View {

    @State private var vm: TopicViewerViewModel
    let env: AppEnvironment
    let topicId: Int
    /// Optional sync hook. Fires whenever the VM finishes loading a topic
    /// whose id differs from the externally-supplied `topicId` prop — i.e.
    /// when the user navigated via prev/next or mark-as-read auto-advance.
    /// Receives the full TopicDetails so the iPad split view can drill
    /// column 2 into the correct lesson and module if the new topic
    /// crossed a boundary. iPhone passes nil; its navigation is purely
    /// path-based and doesn't need this signal.
    let onTopicChange: ((TopicDetails) -> Void)?

    init(env: AppEnvironment, topicId: Int, onTopicChange: ((TopicDetails) -> Void)? = nil) {
        _vm = State(initialValue: TopicViewerViewModel(
            service: env.lessonService,
            initialTopicId: topicId
        ))
        self.env = env
        self.topicId = topicId
        self.onTopicChange = onTopicChange
    }

    var body: some View {
        ZStack {
            Color.vexNavy.ignoresSafeArea()
            content
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbarBackground(Color.vexNavy, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbar { toolbarItems }
        .task { await vm.loadIfNeeded() }
        // External → internal sync. When the parent changes `topicId`
        // (e.g. the user picks a different topic in column 2 of the
        // iPad split view), tell the VM to load it. We don't recreate
        // the view via `.id()` for this — keeping the same view instance
        // avoids a flash to the loading state and a redundant fetch.
        .onChange(of: topicId) { _, newId in
            guard vm.currentTopicId != newId else { return }
            Task { await vm.loadAdjacent(topicId: newId) }
        }
        // Internal → external sync. We observe the LOADED topic id (not
        // just `currentTopicId`, which updates synchronously when nav
        // starts before details are fetched). Firing only on .loaded
        // means we hand the parent full TopicDetails it can use to
        // drill column 2 into the right lesson/module if the user
        // crossed a boundary.
        .onChange(of: vm.loadedTopic?.topicId) { _, newId in
            guard let newId,
                  newId != topicId,
                  let details = vm.loadedTopic else { return }
            onTopicChange?(details)
        }
    }

    // MARK: - Content states

    @ViewBuilder
    private var content: some View {
        switch vm.state {
        case .idle, .loading:
            LoadingStateView(message: "Loading topic…")
        case .failed(let message):
            ErrorStateView(message: message) {
                await vm.refresh()
            }
        case .loaded(let data):
            loaded(data)
        }
    }

    private func loaded(_ data: TopicViewerViewModel.TopicData) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                breadcrumb(for: data.details)
                titleHeader(for: data.details)

                Markdown(data.markdown)
                    .markdownTheme(.vexTrainer)
                    .markdownCodeSyntaxHighlighter(.vexTrainer)
                    .padding(.horizontal, 2)

                markAsReadButton(for: data.details)
                Divider().background(.white.opacity(0.1)).padding(.vertical, 4)
                prevNextRow(for: data.details)
            }
            .padding(.horizontal, 20)
            .padding(.top, 4)
            .padding(.bottom, 32)
            .readableContentWidth(.reading)
        }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarItems: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            if case .loaded(let data) = vm.state {
                NavigationLink(value: LessonRoute.feedbackForm(
                    initialMessage: feedbackPrefill(for: data.details)
                )) {
                    Image(systemName: "exclamationmark.bubble")
                        .foregroundStyle(.white.opacity(0.8))
                }
                .accessibilityLabel("Send feedback about this topic")
            }
        }
        ToolbarItem(placement: .topBarTrailing) {
            if case .loaded(let data) = vm.state {
                Button {
                    Task { await vm.toggleBookmark() }
                } label: {
                    Image(systemName: data.details.isBookmarked ? "bookmark.fill" : "bookmark")
                        .foregroundStyle(
                            data.details.isBookmarked ? Color.vexCyan : .white.opacity(0.8)
                        )
                }
                .disabled(vm.isBookmarkInFlight)
            }
        }
    }

    /// Body of the Contact Us message when the feedback icon is tapped.
    /// Pre-populates the module/lesson/topic context so the user doesn't
    /// have to type it. They can edit or delete the block before sending.
    private func feedbackPrefill(for details: TopicDetails) -> String {
        """
        Feedback on:
        Module: \(details.moduleName)
        Lesson: \(details.lessonTitle)
        Topic: \(details.topicTitle)


        """
    }

    // MARK: - Header components

    private func breadcrumb(for details: TopicDetails) -> some View {
        let crumbs: [String] = {
            var parts = [details.moduleName, details.lessonTitle]
            if let parent = details.parentTopicTitle, !parent.isEmpty {
                parts.append(parent)
            }
            return parts
        }()
        return Text(crumbs.joined(separator: " › "))
            .font(.caption.weight(.medium))
            .foregroundStyle(Color.vexCyan.opacity(0.8))
            .lineLimit(2)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func titleHeader(for details: TopicDetails) -> some View {
        Text(details.topicTitle)
            .font(.title2.weight(.bold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.bottom, 4)
    }

    // MARK: - Mark-as-read button

    @ViewBuilder
    private func markAsReadButton(for details: TopicDetails) -> some View {
        if details.isRead {
            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(Color.vexGreen)
                Text("Read")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.vexGreen)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .padding(.top, 16)
        } else {
            PrimaryButton(
                "Mark as read",
                isLoading: vm.isMarkReadInFlight,
                isEnabled: !vm.isMarkReadInFlight,
                style: .outlined
            ) {
                Task { await vm.markAsRead() }
            }
            .padding(.top, 16)
        }
    }

    // MARK: - Prev / Next

    private func prevNextRow(for details: TopicDetails) -> some View {
        HStack(spacing: 12) {
            navButton(
                direction: .previous,
                topicId: details.previousTopicId,
                title: details.previousTopicTitle
            )
            navButton(
                direction: .next,
                topicId: details.nextTopicId,
                title: details.nextTopicTitle
            )
        }
    }

    private enum NavDirection { case previous, next }

    @ViewBuilder
    private func navButton(direction: NavDirection, topicId: Int?, title: String?) -> some View {
        if let topicId, let title {
            Button {
                Task { await vm.loadAdjacent(topicId: topicId) }
            } label: {
                VStack(alignment: direction == .previous ? .leading : .trailing, spacing: 4) {
                    HStack(spacing: 4) {
                        if direction == .previous {
                            Image(systemName: "chevron.left")
                                .font(.caption.weight(.bold))
                        }
                        Text(direction == .previous ? "Previous" : "Next")
                            .font(.caption.weight(.semibold))
                        if direction == .next {
                            Image(systemName: "chevron.right")
                                .font(.caption.weight(.bold))
                        }
                    }
                    .foregroundStyle(Color.vexOrange)

                    Text(title)
                        .font(.footnote.weight(.medium))
                        .foregroundStyle(.white)
                        .lineLimit(2)
                        .frame(
                            maxWidth: .infinity,
                            alignment: direction == .previous ? .leading : .trailing
                        )
                        .multilineTextAlignment(direction == .previous ? .leading : .trailing)
                }
                .padding(12)
                .frame(maxWidth: .infinity)
                .background(Color.white.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(.white.opacity(0.1), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
        } else {
            // Empty slot to keep the row balanced when there's no prev or no next.
            Color.clear.frame(maxWidth: .infinity)
        }
    }
}
