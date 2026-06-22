//
//  QuizProgressBar.swift
//  VexTrainer
//

import SwiftUI

struct QuizProgressBar: View {
    let current: Int
    let total: Int

    private var progress: Double {
        guard total > 0 else { return 0 }
        return Double(current) / Double(total)
    }

    var body: some View {
        VStack(spacing: 6) {
            HStack {
                Text("Question \(current) of \(total)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.7))
                Spacer()
                Text("\(Int(progress * 100))%")
                    .font(.caption.weight(.semibold).monospacedDigit())
                    .foregroundStyle(.white.opacity(0.5))
            }
            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                        .fill(.white.opacity(0.08))
                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                        .fill(Color.vexCyan)
                        .frame(width: (proxy.size.width * progress).safeNonNegativeWidth)
                }
            }
            .frame(height: 5)
        }
    }
}
