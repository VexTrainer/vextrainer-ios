//
//  StreakBadge.swift
//  VexTrainer
//
//  Tappable badge on the Dashboard. Pushes the Activity Report onto
//  the Home tab's NavigationStack via LessonRoute.activityReport.
//  When streak is 0 the badge still renders (and stays tappable) so
//  the user can always reach their activity history.
//

import SwiftUI

struct StreakBadge: View {
    let days: Int

    var body: some View {
        NavigationLink(value: LessonRoute.activityReport) {
            content
        }
        .buttonStyle(.plain)
    }

    private var content: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color.vexOrange.opacity(0.15))
                    .frame(width: 56, height: 56)
                Image(systemName: "flame.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(Color.vexOrange)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("\(days)-day streak")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.white)
                Text(days == 0
                     ? "Read a topic today to start one"
                     : "Tap to see recent activity")
                    .font(.footnote)
                    .foregroundStyle(.white.opacity(0.6))
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white.opacity(0.4))
        }
        .padding(16)
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(.white.opacity(0.1), lineWidth: 1)
        )
        .contentShape(Rectangle())
    }
}
