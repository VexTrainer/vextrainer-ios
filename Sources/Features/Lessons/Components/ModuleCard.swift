//
//  ModuleCard.swift
//  VexTrainer
//

import SwiftUI

struct ModuleCard: View {
    let module: ModuleSummary

    private var progress: Double {
        guard module.lessonCount > 0 else { return 0 }
        return Double(module.completedLessons) / Double(module.lessonCount)
    }

    private var isComplete: Bool {
        module.lessonCount > 0 && module.completedLessons >= module.lessonCount
    }

    var body: some View {
        NavigationLink(
            value: LessonRoute.lessonList(
                moduleId: module.moduleId,
                moduleName: module.moduleName
            )
        ) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .firstTextBaseline) {
                    Text(module.moduleName)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)

                    Spacer()

                    if isComplete {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(Color.vexGreen)
                    } else {
                        Image(systemName: "chevron.right")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.3))
                    }
                }

                if let description = module.description, !description.isEmpty {
                    Text(description)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.5))
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }

                HStack(spacing: 8) {
                    GeometryReader { proxy in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 3, style: .continuous)
                                .fill(.white.opacity(0.08))
                            RoundedRectangle(cornerRadius: 3, style: .continuous)
                                .fill(isComplete ? Color.vexGreen : Color.vexCyan)
                                .frame(width: (proxy.size.width * progress).safeNonNegativeWidth)
                        }
                    }
                    .frame(height: 4)

                    Text("\(module.completedLessons) / \(module.lessonCount)")
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
