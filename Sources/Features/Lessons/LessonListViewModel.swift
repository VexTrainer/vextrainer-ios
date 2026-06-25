//
//  LessonListViewModel.swift
//  VexTrainer
//

import Foundation
import Observation

@Observable
@MainActor
final class LessonListViewModel {

    enum LoadState {
        case idle
        case loading
        case loaded([LessonSummary])
        case failed(String)
    }

    var state: LoadState = .idle
    let moduleId: Int

    private let service: LessonServicing

    init(service: LessonServicing, moduleId: Int) {
        self.service = service
        self.moduleId = moduleId
    }

    func loadIfNeeded() async {
        if case .loaded = state { return }
        await fetch()
    }

    func refresh() async { await fetch() }

    private func fetch() async {
        if case .loaded = state {} else { state = .loading }
        do {
            let lessons = try await service.fetchLessons(moduleId: moduleId)
                .sorted { $0.displayOrder < $1.displayOrder }
            state = .loaded(lessons)
        } catch let error as APIError {
            state = .failed(error.localizedDescription)
        } catch {
            state = .failed(error.localizedDescription)
        }
    }
}
