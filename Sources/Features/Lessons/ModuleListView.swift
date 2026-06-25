//
//  ModuleListView.swift
//  VexTrainer
//
//  Root content of the Lessons tab. Lists all modules with progress.
//

import SwiftUI

struct ModuleListView: View {
    @State private var vm: ModuleListViewModel
    let env: AppEnvironment

    init(env: AppEnvironment) {
        _vm = State(initialValue: ModuleListViewModel(service: env.lessonService))
        self.env = env
    }

    var body: some View {
        ZStack {
            Color.vexNavy.ignoresSafeArea()
            content
        }
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
        case .loaded(let modules):
            loaded(modules)
        }
    }

    private func loaded(_ modules: [ModuleSummary]) -> some View {
        ScrollView {
            VStack(spacing: 12) {
                ForEach(modules) { module in
                    ModuleCard(module: module)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
        }
        .refreshable { await vm.refresh() }
    }
}
