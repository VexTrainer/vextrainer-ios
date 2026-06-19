//
//  CGFloat+SafeWidth.swift
//  VexTrainer
//
//  Defensive helper for the common pattern:
//
//     GeometryReader { proxy in
//         RoundedRectangle(...)
//             .frame(width: proxy.size.width * progress)
//     }
//
//  SwiftUI's GeometryReader can transiently report a NaN width during
//  layout transitions — most commonly during NavigationStack pushes
//  where the source view contains progress bars and the destination
//  hasn't fully sized itself yet. Multiplying NaN by anything yields
//  NaN, and when CoreGraphics gets NaN it logs:
//
//     Error: this application, or a library it uses, has passed an
//     invalid numeric value (NaN, or not-a-number) to CoreGraphics
//     API and this value is being ignored.
//
//  The drawing is silently dropped, so visually the app is fine, but
//  the console fills with warnings — noisy at best, and Apple's App
//  Review process flags these as a quality issue.
//
//  Using `.frame(width: x.safeNonNegativeWidth)` at every site that
//  computes a frame width from a GeometryReader proxy guards against
//  this. NaN → 0; negative → 0; finite positive → unchanged.
//

import CoreGraphics

extension CGFloat {
    /// Returns `self` if it's finite and non-negative; otherwise 0.
    /// Used to sanitize geometry-derived widths before passing them to
    /// `.frame(width:)`.
    var safeNonNegativeWidth: CGFloat {
        isFinite ? Swift.max(0, self) : 0
    }
}
