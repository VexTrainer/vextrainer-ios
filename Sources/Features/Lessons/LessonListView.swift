//
//  LessonListView.swift
//  VexTrainer
//

import SwiftUI

struct LessonListView: View {
    @State private var vm: LessonListViewModel
    let env: AppEnvironment
    let moduleName: String

    init(env: AppEnvironment, moduleId: Int, moduleName: String) {
        _vm = State(initialValue: LessonListViewModel(service: env.lessonService, moduleId: moduleId))
        self.env = env
        self.moduleName = moduleName
    }

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
        .task { await vm.loadIfNeeded() }
    }

    @ViewBuilder
    private var content: some View {
        switch vm.state {
        case .idle, .loading:
            LoadingStateView()
        case .failed(let message):
            ErrorStateView(message: message) {
                await vm.refresh()
            }
        case .loaded(let lessons):
            loaded(lessons)
        }
    }

    private func loaded(_ lessons: [LessonSummary]) -> some View {
        ScrollView {
            VStack(spacing: 12) {
                ForEach(lessons) { lesson in
                    LessonCard(lesson: lesson)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
        .refreshable { await vm.refresh() }
    }
}
