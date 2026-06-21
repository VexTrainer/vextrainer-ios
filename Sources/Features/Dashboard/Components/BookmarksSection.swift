//
//  BookmarksSection.swift
//  VexTrainer
//
//  Vertical list of bookmarked topics. Tapping a row navigates to the Topic
//  Viewer (Phase 5+). Bookmark removal happens inside the viewer, not here —
//  keeping the dashboard read-only avoids the optimistic-revert dance and
//  matches the user's mental model (you remove a bookmark when you're
//  looking at the topic).
//

import SwiftUI

struct BookmarksSection: View {
    let bookmarks: [BookmarkItem]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(
                title: "Bookmarks",
                subtitle: bookmarks.isEmpty ? nil : "(\(bookmarks.count))"
            )

            if bookmarks.isEmpty {
                Text("Tap the bookmark icon while reading to save a topic.")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.5))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 24)
            } else {
                VStack(spacing: 10) {
                    ForEach(bookmarks) { bookmark in
                        BookmarkRow(bookmark: bookmark)
                    }
                }
            }
        }
    }
}

private struct BookmarkRow: View {
    let bookmark: BookmarkItem

    var body: some View {
        NavigationLink(value: LessonRoute.topicViewer(topicId: bookmark.topicId)) {
            HStack(spacing: 12) {
                Image(systemName: "bookmark.fill")
                    .font(.subheadline)
                    .foregroundStyle(Color.vexCyan)
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 2) {
                    Text(bookmark.topicTitle)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.white)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    Text("\(bookmark.moduleName) · \(bookmark.lessonTitle)")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.5))
                        .lineLimit(1)
                }

                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.3))
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
