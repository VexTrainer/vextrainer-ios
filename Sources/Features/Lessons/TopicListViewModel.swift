//
//  TopicListViewModel.swift
//  VexTrainer
//

import Foundation
import Observation

@Observable
@MainActor
final class TopicListViewModel {

    enum LoadState {
        case idle
        case loading
        case loaded([TopicSummary])
        case failed(String)
    }

    var state: LoadState = .idle
    let lessonId: Int

    private let service: LessonServicing

    init(service: LessonServicing, lessonId: Int) {
        self.service = service
        self.lessonId = lessonId
    }

    func loadIfNeeded() async {
        if case .loaded = state { return }
        await fetch()
    }

    func refresh() async { await fetch() }

    private func fetch() async {
        if case .loaded = state {} else { state = .loading }
        do {
            let topics = try await service.fetchTopics(lessonId: lessonId)
                .sorted { $0.displayOrder < $1.displayOrder }
            state = .loaded(topics)
        } catch let error as APIError {
            state = .failed(error.localizedDescription)
        } catch {
            state = .failed(error.localizedDescription)
        }
    }
}
