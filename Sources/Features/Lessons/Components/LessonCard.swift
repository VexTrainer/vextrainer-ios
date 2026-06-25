//
//  LessonCard.swift
//  VexTrainer
//

import SwiftUI

struct LessonCard: View {
    let lesson: LessonSummary

    private var progress: Double {
        guard lesson.topicCount > 0 else { return 0 }
        return Double(lesson.completedTopics) / Double(lesson.topicCount)
    }

    var body: some View {
        NavigationLink(
            value: LessonRoute.topicList(
                lessonId: lesson.lessonId,
                lessonTitle: lesson.lessonTitle
            )
        ) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .firstTextBaseline) {
                    Text(lesson.lessonTitle)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)

                    Spacer()

                    if lesson.isCompleted {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(Color.vexGreen)
                    } else {
                        Image(systemName: "chevron.right")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.3))
                    }
                }

                HStack(spacing: 8) {
                    GeometryReader { proxy in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 3, style: .continuous)
                                .fill(.white.opacity(0.08))
                            RoundedRectangle(cornerRadius: 3, style: .continuous)
                                .fill(lesson.isCompleted ? Color.vexGreen : Color.vexCyan)
                                .frame(width: (proxy.size.width * progress).safeNonNegativeWidth)
                        }
                    }
                    .frame(height: 4)

                    Text("\(lesson.completedTopics) / \(lesson.topicCount)")
                        .font(.caption2.monospacedDigit())
                        .foregroundStyle(.white.opacity(0.5))
                }
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
        .buttonStyle(.plain)
    }
}
