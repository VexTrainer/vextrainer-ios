//
//  CategoryDisclosureCard.swift
//  VexTrainer
//
//  Inline-expanding card. Tap the header to toggle; expanded content shows
//  the subcategories as tap-to-navigate rows. Mirrors Android's down-arrow
//  expand pattern while using SwiftUI primitives (no DisclosureGroup —
//  custom for full control over the dark-navy styling).
//

import SwiftUI

struct CategoryDisclosureCard: View {
    let category: QuizCategory

    @State private var isExpanded: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            header
            if isExpanded {
                Divider().background(.white.opacity(0.1))
                subcategoryList
            }
        }
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(.white.opacity(0.1), lineWidth: 1)
        )
    }

    // MARK: - Header (the tappable row that toggles expansion)

    private var header: some View {
        Button {
            withAnimation(.easeOut(duration: 0.22)) {
                isExpanded.toggle()
            }
        } label: {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(category.categoryName)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    if category.subcategoryCount > 0 {
                        Text(quizCountLabel)
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.5))
                    }
                }
                Spacer()
                Image(systemName: "chevron.down")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.5))
                    .rotationEffect(.degrees(isExpanded ? 180 : 0))
            }
            .padding(14)
            // Without an explicit content shape, the Spacer's empty region
            // doesn't register taps — only the chevron + text would respond.
            // Rectangle makes the entire padded area hit-testable.
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var quizCountLabel: String {
        let n = category.subcategoryCount
        return n == 1 ? "1 quiz" : "\(n) quizzes"
    }

    // MARK: - Expanded list of subcategories

    private var subcategoryList: some View {
        VStack(spacing: 0) {
            let subs = (category.subcategories ?? [])
                .sorted { $0.displayOrder < $1.displayOrder }
            ForEach(Array(subs.enumerated()), id: \.element.id) { idx, sub in
                NavigationLink(
                    value: QuizRoute.quizList(
                        categoryId: sub.categoryId,
                        categoryName: sub.categoryName
                    )
                ) {
                    HStack(spacing: 10) {
                        Text(sub.categoryName)
                            .font(.footnote)
                            .foregroundStyle(.white.opacity(0.85))
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.3))
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 11)
                }
                .buttonStyle(.plain)

                if idx < subs.count - 1 {
                    Divider()
                        .background(.white.opacity(0.08))
                        .padding(.leading, 14)
                }
            }
        }
        .padding(.bottom, 4)
    }
}
