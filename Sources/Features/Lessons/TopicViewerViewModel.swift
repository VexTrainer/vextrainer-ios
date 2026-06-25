//
//  TopicViewerViewModel.swift
//  VexTrainer
//
//  Two-step load: first fetch TopicDetails (metadata, prev/next, isRead,
//  isBookmarked, fileName), then fetch the markdown content from the file
//  URL. Both must succeed to render. Network errors surface as a retry-able
//  failure state.
//
//  Prev/Next replace state in place (we do NOT push new viewers onto the
//  stack — the user navigates by content, but the back-button still goes to
//  the topic list).
//

import Foundation
import Observation

@Observable
@MainActor
final class TopicViewerViewModel {

    struct TopicData {
        var details: TopicDetails
        var markdown: String
    }

    enum LoadState {
        case idle
        case loading
        case loaded(TopicData)
        case failed(String)
    }

    var state: LoadState = .idle
    var isBookmarkInFlight: Bool = false
    var isMarkReadInFlight: Bool = false

    private(set) var currentTopicId: Int

    /// The full TopicDetails of whatever topic is currently displayed, or
    /// nil if we're still loading / failed. The iPad split view observes
    /// this so column 2 can drill into the correct lesson — including
    /// across lesson and module boundaries — when the user navigates
    /// inside the topic viewer with prev/next or mark-as-read auto-advance.
    var loadedTopic: TopicDetails? {
        if case let .loaded(data) = state {
            return data.details
        }
        return nil
    }

    private let service: LessonServicing

    init(service: LessonServicing, initialTopicId: Int) {
        self.service = service
        self.currentTopicId = initialTopicId
    }

    // MARK: - Loading

    func loadIfNeeded() async {
        if case .loaded = state { return }
        await load(topicId: currentTopicId)
    }

    func refresh() async {
        await load(topicId: currentTopicId)
    }

    func loadAdjacent(topicId: Int) async {
        currentTopicId = topicId
        await load(topicId: topicId)
    }

    private func load(topicId: Int) async {
        state = .loading
        do {
            let details = try await service.fetchTopicDetails(topicId: topicId)
            let markdown = try await service.fetchTopicMarkdown(fileName: details.fileName)
            state = .loaded(TopicData(details: details, markdown: markdown))
        } catch let error as APIError {
            state = .failed(error.localizedDescription)
        } catch {
            state = .failed(error.localizedDescription)
        }
    }

    // MARK: - Bookmark toggle (optimistic)

    func toggleBookmark() async {
        guard case .loaded(var data) = state, !isBookmarkInFlight else { return }
        isBookmarkInFlight = true
        defer { isBookmarkInFlight = false }

        let wasBookmarked = data.details.isBookmarked
        // Optimistic flip
        data.details = data.details.with(isBookmarked: !wasBookmarked)
        state = .loaded(data)

        do {
            if wasBookmarked {
                try await service.removeBookmark(topicId: data.details.topicId)
            } else {
                try await service.addBookmark(topicId: data.details.topicId)
            }
            // Dashboard's Bookmarks section is now out of date — flag a
            // refresh for the next Home visit.
            DashboardInvalidator.shared.markDirty()
        } catch {
            // Revert on failure. No toast system yet (Phase 7) — the icon snaps back.
            data.details = data.details.with(isBookmarked: wasBookmarked)
            state = .loaded(data)
        }
    }

    // MARK: - Mark-as-read

    func markAsRead() async {
        guard case .loaded(var data) = state,
              !data.details.isRead,
              !isMarkReadInFlight else { return }
        isMarkReadInFlight = true
        defer { isMarkReadInFlight = false }

        // Capture nextTopicId before mutation — we'll auto-advance on success.
        let nextId = data.details.nextTopicId

        // Optimistic flip on the local copy so the "Read" indicator shows
        // immediately. If the server call fails, we'll revert below.
        data.details = data.details.with(isRead: true)
        state = .loaded(data)

        do {
            try await service.markTopicRead(topicId: data.details.topicId)
            // Stats on the dashboard (topicsRead, reading streak, progress
            // percentages, continue-learning list) now reflect this read,
            // so the next time the user lands on Home we want the cached
            // dashboard refreshed.
            DashboardInvalidator.shared.markDirty()
            // Auto-advance to the next topic if one exists. If we're at the
            // last topic of the lesson, stay put — the user can hit Back.
            if let nextId {
                await loadAdjacent(topicId: nextId)
            }
        } catch {
            // Revert the optimistic flip. No toast yet (Phase 7).
            data.details = data.details.with(isRead: false)
            state = .loaded(data)
        }
    }
}

// MARK: - TopicDetails mutating helpers

private extension TopicDetails {
    func with(isRead: Bool? = nil, isBookmarked: Bool? = nil) -> TopicDetails {
        TopicDetails(
            topicId: topicId,
            topicTitle: topicTitle,
            headingLevel: headingLevel,
            fileName: fileName,
            isRead: isRead ?? self.isRead,
            isBookmarked: isBookmarked ?? self.isBookmarked,
            previousTopicId: previousTopicId,
            previousTopicTitle: previousTopicTitle,
            previousFileName: previousFileName,
            nextTopicId: nextTopicId,
            nextTopicTitle: nextTopicTitle,
            nextFileName: nextFileName,
            moduleId: moduleId,
            moduleName: moduleName,
            lessonId: lessonId,
            lessonTitle: lessonTitle,
            parentTopicTitle: parentTopicTitle
        )
    }
}

// MARK: - TopicDetails memberwise init (Decodable struct doesn't synthesize one)

extension TopicDetails {
    fileprivate init(
        topicId: Int, topicTitle: String, headingLevel: Int, fileName: String,
        isRead: Bool, isBookmarked: Bool,
        previousTopicId: Int?, previousTopicTitle: String?, previousFileName: String?,
        nextTopicId: Int?, nextTopicTitle: String?, nextFileName: String?,
        moduleId: Int, moduleName: String, lessonId: Int, lessonTitle: String,
        parentTopicTitle: String?
    ) {
        // Round-trip via JSONDecoder using our existing Decodable init.
        let dict: [String: Any?] = [
            "topicId": topicId,
            "topicTitle": topicTitle,
            "headingLevel": headingLevel,
            "fileName": fileName,
            "isRead": isRead,
            "isBookmarked": isBookmarked,
            "previousTopicId": previousTopicId as Any,
            "previousTopicTitle": previousTopicTitle as Any,
            "previousFileName": previousFileName as Any,
            "nextTopicId": nextTopicId as Any,
            "nextTopicTitle": nextTopicTitle as Any,
            "nextFileName": nextFileName as Any,
            "moduleId": moduleId,
            "moduleName": moduleName,
            "lessonId": lessonId,
            "lessonTitle": lessonTitle,
            "parentTopicTitle": parentTopicTitle as Any
        ].compactMapValues { $0 }
        let data = try! JSONSerialization.data(withJSONObject: dict)
        self = try! JSONDecoder().decode(TopicDetails.self, from: data)
    }
}
