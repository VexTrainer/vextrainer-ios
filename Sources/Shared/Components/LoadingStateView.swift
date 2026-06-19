//
//  LoadingStateView.swift
//  VexTrainer
//

import SwiftUI

struct LoadingStateView: View {
    var message: String? = nil

    var body: some View {
        VStack(spacing: 12) {
            ProgressView()
                .progressViewStyle(.circular)
                .tint(.white.opacity(0.6))
            if let message {
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.5))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
