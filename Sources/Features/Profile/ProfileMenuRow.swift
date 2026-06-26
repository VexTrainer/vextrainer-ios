//
//  ProfileMenuRow.swift
//  VexTrainer
//
//  Single row in the Profile menu. Icon + title on the left, optional
//  trailing label or icon, chevron-right on the right. Designed to be
//  wrapped by either NavigationLink (in-app push) or Button (external
//  browser open) at the call site.
//

import SwiftUI

struct ProfileMenuRow<Trailing: View>: View {

    let icon: String
    let title: String
    let iconTint: Color
    var destructive: Bool = false
    @ViewBuilder var trailing: () -> Trailing

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(iconTint)
                .frame(width: 28)
            Text(title)
                .font(.body)
                .foregroundStyle(destructive ? destructiveText : .white)
            Spacer(minLength: 8)
            trailing()
            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white.opacity(0.35))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(.white.opacity(0.1), lineWidth: 1)
        )
        .contentShape(Rectangle())
    }

    private var destructiveText: Color {
        Color(red: 1.0, green: 0.5, blue: 0.5)
    }
}

extension ProfileMenuRow where Trailing == EmptyView {
    init(icon: String, title: String, iconTint: Color, destructive: Bool = false) {
        self.init(
            icon: icon,
            title: title,
            iconTint: iconTint,
            destructive: destructive,
            trailing: { EmptyView() }
        )
    }
}
