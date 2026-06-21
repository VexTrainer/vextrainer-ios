//
//  ProgressStatsCard.swift
//  VexTrainer
//
//  Card with three progress bars — Topics, Lessons, Modules — plus two
//  numeric stats at the bottom (quizzes completed, best score).
//

import SwiftUI

struct ProgressStatsCard: View {
    let stats: DashboardStats

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Your progress")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white.opacity(0.7))

            progressRow(
                label: "Topics",
                done: stats.topicsRead,
                total: stats.totalTopics,
                percent: stats.topicsProgressPercent,
                tint: Color.vexGreen
            )
            progressRow(
                label: "Lessons",
                done: stats.completedLessons,
                total: stats.totalLessons,
                percent: stats.lessonsProgressPercent,
                tint: Color.vexCyan
            )
            progressRow(
                label: "Modules",
                done: stats.completedModules,
                total: stats.totalModules,
                percent: stats.modulesProgressPercent,
                tint: Color.vexOrange
            )

            Divider().background(.white.opacity(0.1))

            HStack(spacing: 0) {
                quizMetric(
                    label: "Quizzes",
                    value: "\(stats.quizzesCompleted) of \(stats.quizzesAttempted)"
                )
                Divider().frame(height: 30).background(.white.opacity(0.1))
                quizMetric(
                    label: "Best score",
                    value: stats.bestQuizScore > 0
                        ? "\(Int(stats.bestQuizScore.rounded()))%"
                        : "—"
                )
            }
        }
        .padding(18)
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(.white.opacity(0.1), lineWidth: 1)
        )
    }

    // MARK: - Components

    private func progressRow(label: String, done: Int, total: Int, percent: Double, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                Text(label)
                    .font(.subheadline)
                    .foregroundStyle(.white)
                Spacer()
                Text("\(done) / \(total)")
                    .font(.footnote.monospacedDigit())
                    .foregroundStyle(.white.opacity(0.6))
            }
            GeometryReader { proxy in
                let clampedPercent = max(0, min(100, percent)) / 100.0
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(.white.opacity(0.08))
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(tint)
                        .frame(width: (proxy.size.width * clampedPercent).safeNonNegativeWidth)
                }
            }
            .frame(height: 6)
        }
    }

    private func quizMetric(label: String, value: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.body.weight(.semibold))
                .foregroundStyle(.white)
            Text(label)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.5))
        }
        .frame(maxWidth: .infinity)
    }
}
