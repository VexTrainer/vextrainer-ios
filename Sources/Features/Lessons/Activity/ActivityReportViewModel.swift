//
//  ActivityReportViewModel.swift
//  VexTrainer
//

import Foundation
import Observation

@Observable
@MainActor
final class ActivityReportViewModel {

    enum State {
        case idle
        case loading
        case loaded([DayActivity])
        case failed(String)
    }

    var state: State = .idle

    private let service: LessonServicing
    private var hasLoaded = false

    init(service: LessonServicing) {
        self.service = service
    }

    func loadIfNeeded() async {
        guard !hasLoaded else { return }
        await load()
    }

    func refresh() async {
        await load()
    }

    private func load() async {
        state = .loading
        let offsetMinutes = Int(TimeZone.current.secondsFromGMT() / 60)
        do {
            let report = try await service.fetchStreakReport(timezoneOffsetMinutes: offsetMinutes)
            let days = ActivityReportGrouper.group(report)
            state = .loaded(days)
            hasLoaded = true
        } catch let apiError as APIError {
            state = .failed(apiError.localizedDescription)
        } catch {
            state = .failed(error.localizedDescription)
        }
    }
}
