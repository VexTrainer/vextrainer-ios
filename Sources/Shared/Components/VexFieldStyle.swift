//
//  VexFieldStyle.swift
//  VexTrainer
//
//  ViewModifier applied to TextField / SecureField for consistent dark-theme styling.
//

import SwiftUI

struct VexFieldStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(Color.white.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(.white.opacity(0.15), lineWidth: 1)
            )
            .foregroundStyle(.white)
            .tint(Color.vexOrange)
    }
}

extension View {
    func vexFieldStyle() -> some View { modifier(VexFieldStyle()) }
}
