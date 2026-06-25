//
//  TopicRow.swift
//  VexTrainer
//
//  One row in the topic list. headingLevel 3 = main topic, 4 = sub-topic
//  (indented). isRead shows a green check.
//

import SwiftUI

struct TopicRow: View {
    let topic: TopicSummary

    private var isSubTopic: Bool { topic.headingLevel >= 4 }

    var body: some View {
        NavigationLink(value: LessonRoute.topicViewer(topicId: topic.topicId)) {
            HStack(spacing: 12) {
                // Read/unread bullet
                ZStack {
                    Circle()
                        .strokeBorder(.white.opacity(0.25), lineWidth: 1.5)
                        .frame(width: 18, height: 18)
                    if topic.isRead {
                        Image(systemName: "checkmark")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(Color.vexGreen)
                    }
                }

                Text(topic.topicTitle)
                    .font(isSubTopic ? .subheadline : .subheadline.weight(.semibold))
                    .foregroundStyle(.white.opacity(isSubTopic ? 0.8 : 1.0))
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.3))
            }
            .padding(.leading, isSubTopic ? 28 : 0)
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
