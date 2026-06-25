//
//  ActivityReportView.swift
//  VexTrainer
//
//  Streak badge tap target. Shows the user's reading and quiz activity
//  for their 7 most-recent ACTIVE days (gaps allowed; may span > 7
//  calendar days). Layout mirrors the Android ActivityReportScreen:
//
//    Today
//      LESSONS
//        ┌ Module 5 — Sensors                       (card)
//        │   Lesson 5.1 — Digital Sensors
//        │     • Bumper Switches
//        │     • Limit Switches
//        └
//      QUIZZES
//        ⓘ 4.1 What Happens When You Hit Run       85%
//        ○ 4.2 The Five Competition Functions   Incomplete
//
//    Yesterday
//      ...
//
//  Topic taps push into the current (Home) tab's stack via
//  NavigationLink. Quiz taps cross-navigate to the Quizzes tab via
//  CrossTabRouter — see MainShellView for the handoff.
//

import SwiftUI

struct ActivityReportView: View {
    @State private var vm: ActivityReportViewModel
    @Environment(CrossTabRouter.self) private var crossTab

    init(env: AppEnvironment) {
        _vm = State(initialValue: ActivityReportViewModel(service: env.lessonService))
    }

    var body: some View {
        ZStack {
            Color.vexNavy.ignoresSafeArea()
            content
        }
        .navigationTitle("Activity Report")
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
        case .loaded(let days):
            if days.isEmpty {
                emptyState
            } else {
                list(days)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "flame")
                .font(.system(size: 44))
                .foregroundStyle(.white.opacity(0.4))
            Text("No activity in the last 7 days")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white.opacity(0.7))
            Text("Start reading to build your streak!")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.5))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func list(_ days: [DayActivity]) -> some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 18) {
                ForEach(days) { day in
                    daySection(day)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 32)
        }
        .refreshable { await vm.refresh() }
    }

    // MARK: - Day section

    @ViewBuilder
    private func daySection(_ day: DayActivity) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(ActivityDateLabel.label(for: day.dateKey))
                .font(.title3.weight(.bold))
                .foregroundStyle(Color.vexOrange)

            if !day.modules.isEmpty {
                sectionHeader(icon: "book.fill", label: "LESSONS")
                VStack(spacing: 8) {
                    ForEach(day.modules) { module in
                        moduleCard(module)
                    }
                }
            }

            if !day.quizzes.isEmpty {
                sectionHeader(icon: "questionmark.circle.fill", label: "QUIZZES")
                VStack(spacing: 8) {
                    ForEach(day.quizzes) { quiz in
                        quizRow(quiz)
                    }
                }
            }
        }
    }

    private func sectionHeader(icon: String, label: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption2)
            Text(label)
                .font(.caption.weight(.semibold))
                .tracking(0.5)
        }
        .foregroundStyle(.white.opacity(0.55))
        .padding(.top, 4)
    }

    // MARK: - Module → Lesson → Topic card

    private func moduleCard(_ module: ModuleActivity) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(module.moduleName)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(.white.opacity(0.9))

            ForEach(module.lessons) { lesson in
                lessonBlock(lesson)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(.white.opacity(0.1), lineWidth: 1)
        )
    }

    private func lessonBlock(_ lesson: LessonActivity) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(lesson.lessonTitle)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
                .padding(.leading, 8)
                .padding(.top, 2)

            ForEach(lesson.topics) { topic in
                topicRow(topic)
            }
        }
    }

    private func topicRow(_ topic: ActivityTopic) -> some View {
        NavigationLink(value: LessonRoute.topicViewer(topicId: topic.topicId)) {
            HStack(alignment: .top, spacing: 8) {
                Text("•")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(Color.vexCyan)
                Text(topic.topicTitle)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.85))
                    .multilineTextAlignment(.leading)
                Spacer()
            }
            .padding(.leading, 18)
            .padding(.vertical, 2)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Quiz row

    private func quizRow(_ quiz: ActivityQuiz) -> some View {
        Button {
            crossTab.pendingQuizDetail = quiz.quizId
        } label: {
            HStack(spacing: 10) {
                Image(systemName: quiz.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.body)
                    .foregroundStyle(quiz.isCompleted ? Color.vexGreen : .white.opacity(0.4))
                Text(quizDisplayTitle(quiz))
                    .font(.subheadline)
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                quizScoreLabel(quiz)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(.white.opacity(0.1), lineWidth: 1)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func quizDisplayTitle(_ quiz: ActivityQuiz) -> String {
        quiz.attemptCount > 1
            ? "\(quiz.quizTitle) (\(quiz.attemptCount)x)"
            : quiz.quizTitle
    }

    @ViewBuilder
    private func quizScoreLabel(_ quiz: ActivityQuiz) -> some View {
        if quiz.isCompleted, let score = quiz.bestScore {
            Text("\(Int(score.rounded()))%")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(.white)
                .monospacedDigit()
        } else {
            Text("Incomplete")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.5))
        }
    }
}
