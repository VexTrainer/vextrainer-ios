//
//  ModuleListViewModel.swift
//  VexTrainer
//

import Foundation
import Observation

@Observable
@MainActor
final class ModuleListViewModel {

    enum LoadState {
        case idle
        case loading
        case loaded([ModuleSummary])
        case failed(String)
    }

    var state: LoadState = .idle

    private let service: LessonServicing

    init(service: LessonServicing) {
        self.service = service
    }

    func loadIfNeeded() async {
        if case .loaded = state { return }
        await fetch()
    }

    func refresh() async {
        await fetch()
    }

    private func fetch() async {
        if case .loaded = state {} else { state = .loading }
        do {
            let modules = try await service.fetchModules()
                .sorted { $0.displayOrder < $1.displayOrder }
            state = .loaded(modules)
        } catch let error as APIError {
            state = .failed(error.localizedDescription)
        } catch {
            state = .failed(error.localizedDescription)
        }
    }
}
