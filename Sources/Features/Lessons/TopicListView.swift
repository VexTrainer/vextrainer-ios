//
//  TopicListView.swift
//  VexTrainer
//

import SwiftUI

struct TopicListView: View {
    @State private var vm: TopicListViewModel
    let env: AppEnvironment
    let lessonTitle: String

    init(env: AppEnvironment, lessonId: Int, lessonTitle: String) {
        _vm = State(initialValue: TopicListViewModel(service: env.lessonService, lessonId: lessonId))
        self.env = env
        self.lessonTitle = lessonTitle
    }

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
        case .loaded(let topics):
            loaded(topics)
        }
    }

    private func loaded(_ topics: [TopicSummary]) -> some View {
        ScrollView {
            VStack(spacing: 8) {
                ForEach(topics) { topic in
                    TopicRow(topic: topic)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
        .refreshable { await vm.refresh() }
    }
}
