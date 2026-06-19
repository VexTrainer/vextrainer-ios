//
//  ComingSoonView.swift
//  VexTrainer
//
//  Centered icon + title + subtitle. Used by the Lessons and Quizzes tabs
//  while their feature implementations are still upcoming.
//

import SwiftUI

struct ComingSoonView: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        VStack(spacing: 18) {
            Image(systemName: icon)
                .font(.system(size: 56))
                .foregroundStyle(Color.vexCyan.opacity(0.7))

            VStack(spacing: 8) {
                Text(title)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.white)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 28)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
