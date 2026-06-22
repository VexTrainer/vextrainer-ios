//
//  QuizHistoryView.swift
//  VexTrainer
//
//  Paginated list of every quiz attempt the user has ever made, most
//  recent first. Each row shows quiz title + category + status pill
//  + score (if completed) + start-or-complete timestamp. Taps push
//  QuizResultsView for that attempt. Layout mirrors Android's
//  QuizHistoryScreen + HistoryItemCard.
//

import SwiftUI

struct QuizHistoryView: View {

    @State private var vm: QuizHistoryViewModel

    init(env: AppEnvironment) {
        _vm = State(initialValue: QuizHistoryViewModel(service: env.quizService))
    }

    var body: some View {
        ZStack {
            Color.vexNavy.ignoresSafeArea()
            content
        }
        .navigationTitle("Quiz History")
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
        case .loaded(let items, _):
            if items.isEmpty {
                emptyState
            } else {
                list(items)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 44))
                .foregroundStyle(.white.opacity(0.4))
            Text("No quiz attempts yet")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white.opacity(0.7))
            Text("Your attempts will appear here once you take a quiz.")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.5))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func list(_ items: [QuizHistoryItem]) -> some View {
        ScrollView {
            LazyVStack(spacing: 10) {
                ForEach(items) { item in
                    NavigationLink(value: QuizRoute.quizResults(
                        attemptId: item.attemptId,
                        completionSummary: nil
                    )) {
                        historyCard(item)
                    }
                    .buttonStyle(.plain)
                }

                // Pagination sentinel + loading indicator
                if vm.hasMore {
                    Color.clear
                        .frame(height: 1)
                        .onAppear {
                            Task { await vm.loadMore() }
                        }
                    if vm.isLoadingMore {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .tint(.white)
                            .padding(.vertical, 12)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 24)
        }
        .refreshable { await vm.refresh() }
    }

    // MARK: - Card

    private func historyCard(_ item: QuizHistoryItem) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(item.quizTitle)
                .font(.body.weight(.semibold))
                .foregroundStyle(.white)
                .multilineTextAlignment(.leading)
            Text(item.categoryName)
                .font(.footnote)
                .foregroundStyle(.white.opacity(0.6))
            HStack(spacing: 10) {
                statusPill(item)
                if item.isCompleted, let score = item.score {
                    Text("\(Int(score.rounded()))%")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.white)
                        .monospacedDigit()
                }
                Spacer()
                Text(formattedDate(referenceDateString(for: item)))
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.55))
                    .monospacedDigit()
            }
            .padding(.top, 4)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(.white.opacity(0.1), lineWidth: 1)
        )
    }

    @ViewBuilder
    private func statusPill(_ item: QuizHistoryItem) -> some View {
        if item.isCompleted {
            pill(label: "Complete", tint: Color.vexGreen)
        } else {
            pill(label: "Incomplete", tint: Color(red: 0.95, green: 0.65, blue: 0.20))
        }
    }

    private func pill(label: String, tint: Color) -> some View {
        Text(label)
            .font(.caption.weight(.bold))
            .foregroundStyle(tint)
            .padding(.horizontal, 10)
            .padding(.vertical, 3)
            .background(tint.opacity(0.15))
            .clipShape(Capsule())
            .overlay(Capsule().strokeBorder(tint.opacity(0.45), lineWidth: 1))
    }

    /// Completed attempts use completedDate; otherwise startedDate.
    private func referenceDateString(for item: QuizHistoryItem) -> String {
        item.completedDate ?? item.startedDate
    }

    /// "2026-05-21T11:04:57.1666667" (UTC) → "2026-05-21 14:04" in local.
    /// Falls back to "yyyy-MM-dd HH:mm" extracted from the first 16 chars
    /// if the parse fails for any reason.
    private func formattedDate(_ raw: String) -> String {
        let prefix = String(raw.prefix(19))  // drop sub-second + offset
        let parser = DateFormatter()
        parser.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        parser.timeZone = TimeZone(identifier: "UTC")
        parser.locale = Locale(identifier: "en_US_POSIX")
        guard let date = parser.date(from: prefix) else {
            return String(raw.prefix(16)).replacingOccurrences(of: "T", with: " ")
        }
        let display = DateFormatter()
        display.dateFormat = "yyyy-MM-dd HH:mm"
        display.timeZone = .current
        display.locale = .current
        return display.string(from: date)
    }
}
