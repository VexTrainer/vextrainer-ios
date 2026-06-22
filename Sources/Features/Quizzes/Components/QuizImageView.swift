//
//  QuizImageView.swift
//  VexTrainer
//
//  AsyncImage wrapper used by question and answer rendering. Loads
//  from absolute URLs the server returns in questionImagePath /
//  answerImagePath. Shows a small spinner while loading, a muted
//  photo placeholder on failure, and an aspect-fit image when ready.
//

import SwiftUI

struct QuizImageView: View {
    let urlString: String?
    let maxHeight: CGFloat

    var body: some View {
        if let urlString,
           !urlString.isEmpty,
           let url = URL(string: urlString) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .empty:
                    placeholder(showSpinner: true)
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: .infinity)
                        .frame(maxHeight: maxHeight)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                case .failure:
                    placeholder(showSpinner: false)
                @unknown default:
                    placeholder(showSpinner: false)
                }
            }
        }
    }

    private func placeholder(showSpinner: Bool) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color.white.opacity(0.04))
                .frame(maxWidth: .infinity)
                .frame(height: 80)
            if showSpinner {
                ProgressView()
                    .progressViewStyle(.circular)
                    .tint(.white.opacity(0.4))
            } else {
                Image(systemName: "photo")
                    .font(.title3)
                    .foregroundStyle(.white.opacity(0.25))
            }
        }
    }
}
