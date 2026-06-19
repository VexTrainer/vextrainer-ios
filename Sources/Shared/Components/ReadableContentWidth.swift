//
//  ReadableContentWidth.swift
//  VexTrainer
//
//  View modifier that centers content within a sensible maximum
//  width on iPad's regular horizontal size class. iPhone (compact)
//  passes through unchanged so nothing changes on the device the
//  vast majority of students use.
//
//  Two defaults are exposed because reading and UI surfaces want
//  different widths:
//
//    .reading  (760pt) — long-form markdown, articles. Roughly 60–75
//                       characters per line at our default text size,
//                       the classic typography sweet spot. Used by
//                       TopicViewer, About, Privacy.
//
//    .ui       (900pt) — lists, cards, forms. Roomier so cards don't
//                       look cramped, but still narrow enough that
//                       multi-column iPad layouts work in split view.
//                       Used by Dashboard, lesson/topic lists,
//                       quiz screens, Profile.
//
//  Implementation uses an HStack with flexible spacers rather than
//  .frame(maxWidth:) alone, because frame doesn't reliably center
//  inside a ScrollView's VStack on all SwiftUI versions. The spacer
//  pattern is bullet-proof and the cost is one extra layout pass.
//

import SwiftUI
import UIKit

enum ReadableWidth: CGFloat {
    case reading = 760
    case ui = 900
}

extension View {
    /// Centers and clamps content width on iPad. No-op on iPhone.
    func readableContentWidth(_ width: ReadableWidth = .ui) -> some View {
        modifier(ReadableContentWidthModifier(maxWidth: width.rawValue))
    }

    /// Variant for callers that want a custom width number.
    func readableContentWidth(maxWidth: CGFloat) -> some View {
        modifier(ReadableContentWidthModifier(maxWidth: maxWidth))
    }
}

private struct ReadableContentWidthModifier: ViewModifier {
    let maxWidth: CGFloat

    /// We check UIDevice.userInterfaceIdiom rather than
    /// @Environment(\.horizontalSizeClass) because iPadOS 18+/26 reports
    /// horizontalSizeClass == .compact to views nested inside a TabView
    /// even on a full-screen iPad. When the iPad is in slide-over or a
    /// narrow split-screen, the content's natural width is already
    /// smaller than `maxWidth`, so the clamp is a no-op visually —
    /// hence no special handling needed for that case.
    private var isIPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }

    func body(content: Content) -> some View {
        if isIPad {
            HStack(spacing: 0) {
                Spacer(minLength: 0)
                content
                    .frame(maxWidth: maxWidth)
                Spacer(minLength: 0)
            }
        } else {
            content
        }
    }
}
