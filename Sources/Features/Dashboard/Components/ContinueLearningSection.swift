//
//  ContinueLearningSection.swift
//  VexTrainer
//
//  Vertical list of in-progress lessons. Each card navigates straight into
//  the next-up topic for that lesson.
//

import SwiftUI

struct ContinueLearningSection: View {
    let items: [ContinueLearningItem]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Continue learning")

            if items.isEmpty {
                emptyState
            } else {
                VStack(spacing: 10) {
                    ForEach(items) { item in
                        ContinueLearningCard(item: item)
                    }
                }
            }
        }
    }

    private var emptyState: some View {
        Text("Start a lesson to see it here.")
            .font(.subheadline)
            .foregroundStyle(.white.opacity(0.5))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 24)
    }
}

private struct ContinueLearningCard: View {
    let item: ContinueLearningItem

    private var progress: Double {
        guard item.totalTopics > 0 else { return 0 }
        return Double(item.topicsRead) / Double(item.totalTopics)
    }

    var body: some View {
        NavigationLink(value: LessonRoute.topicViewer(topicId: item.nextTopicId)) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.lessonTitle)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.white)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                        Text(item.moduleName)
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.5))
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.3))
                }

                Text("Next: \(item.nextTopicTitle)")
                    .font(.footnote)
                    .foregroundStyle(Color.vexCyan)
                    .lineLimit(1)
                    .multilineTextAlignment(.leading)

                HStack(spacing: 8) {
                    GeometryReader { proxy in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 3, style: .continuous)
                                .fill(.white.opacity(0.08))
                            RoundedRectangle(cornerRadius: 3, style: .continuous)
                                .fill(Color.vexGreen)
                                .frame(width: (proxy.size.width * progress).safeNonNegativeWidth)
                        }
                    }
                    .frame(height: 4)

                    Text("\(item.topicsRead) / \(item.totalTopics)")
                        .font(.caption2.monospacedDigit())
                        .foregroundStyle(.white.opacity(0.5))
                }
            }
            .padding(14)
            .background(Color.white.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(.white.opacity(0.1), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}
