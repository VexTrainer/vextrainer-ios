//
//  CategoryListView.swift
//  VexTrainer
//
//  Root of the Quizzes tab. Paged loading of parent categories; each row
//  expands inline to reveal its subcategories.
//

import SwiftUI

struct CategoryListView: View {

    @State private var vm: CategoryListViewModel
    let env: AppEnvironment

    init(env: AppEnvironment) {
        _vm = State(initialValue: CategoryListViewModel(service: env.quizService))
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
                await vm.loadIfNeeded()
            }
        case .loaded(let categories):
            loaded(categories)
        }
    }

    private func loaded(_ categories: [QuizCategory]) -> some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(categories) { category in
                    CategoryDisclosureCard(category: category)
                }
                if vm.hasMore {
                    bottomSentinel
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
        }
        .refreshable { await vm.refresh() }
    }

    /// Bottom sentinel — its `.task` fires when it scrolls into view,
    /// triggering the next page fetch. Disappears when hasMore = false.
    private var bottomSentinel: some View {
        HStack(spacing: 10) {
            ProgressView()
                .progressViewStyle(.circular)
                .tint(.white.opacity(0.6))
            Text(vm.isLoadingMore ? "Loading more…" : " ")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.5))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .task {
            await vm.loadNextPageIfPossible()
        }
    }
}
