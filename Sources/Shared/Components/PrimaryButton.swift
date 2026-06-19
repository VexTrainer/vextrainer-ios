//
//  PrimaryButton.swift
//  VexTrainer
//
//  Big orange CTA button. Two visual styles — filled is the standard primary
//  action; outlined is used when the button is one of several equal-weight
//  options on screen (e.g. Login step 1 where it sits alongside Forgot
//  Password and Sign Up links). The two styles share the same shape and size,
//  so toggling between them animates cleanly.
//

import SwiftUI

enum PrimaryButtonStyle {
    case filled
    case outlined
}

struct PrimaryButton: View {
    let title: String
    let isLoading: Bool
    let isEnabled: Bool
    let style: PrimaryButtonStyle
    let action: () -> Void

    init(
        _ title: String,
        isLoading: Bool = false,
        isEnabled: Bool = true,
        style: PrimaryButtonStyle = .filled,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.isLoading = isLoading
        self.isEnabled = isEnabled
        self.style = style
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            ZStack {
                Text(title)
                    .opacity(isLoading ? 0 : 1)
                if isLoading {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(style == .filled ? .white : Color.vexOrange)
                }
            }
            .font(.body.weight(.semibold))
            .frame(maxWidth: .infinity, minHeight: 50)
            .background(backgroundColor)
            .foregroundStyle(foregroundColor)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(borderColor, lineWidth: 1.5)
            )
        }
        .disabled(!isEnabled || isLoading)
        .animation(.easeInOut(duration: 0.25), value: isLoading)
        .animation(.easeInOut(duration: 0.25), value: isEnabled)
        .animation(.easeInOut(duration: 0.25), value: style)
    }

    // MARK: - Style resolution

    private var backgroundColor: Color {
        switch style {
        case .filled:   return isEnabled ? Color.vexOrange : Color.white.opacity(0.12)
        case .outlined: return .clear
        }
    }

    private var foregroundColor: Color {
        switch style {
        case .filled:   return .white
        case .outlined: return isEnabled ? Color.vexOrange : Color.white.opacity(0.3)
        }
    }

    private var borderColor: Color {
        switch style {
        case .filled:   return .clear
        case .outlined: return isEnabled ? Color.vexOrange : Color.white.opacity(0.2)
        }
    }
}
