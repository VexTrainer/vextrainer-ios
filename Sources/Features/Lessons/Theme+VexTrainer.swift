//
//  Theme+VexTrainer.swift
//  VexTrainer
//
//  swift-markdown-ui Theme tuned for the dark navy background. All foreground
//  colors are white or near-white; accents pull from the brand palette.
//

import SwiftUI
import MarkdownUI

extension Theme {

    static let vexTrainer = Theme()

        // MARK: - Base text

        .text {
            ForegroundColor(.white.opacity(0.92))
            FontSize(.em(1.0))
        }

        // MARK: - Inline styles

        .strong {
            FontWeight(.semibold)
            ForegroundColor(.white)
        }
        .emphasis {
            FontStyle(.italic)
        }
        .link {
            ForegroundColor(Color.vexCyan)
            UnderlineStyle(.single)
        }
        .code {
            FontFamilyVariant(.monospaced)
            FontSize(.em(0.88))
            BackgroundColor(.white.opacity(0.10))
            ForegroundColor(Color.vexGreen)
        }

        // MARK: - Headings

        .heading1 { configuration in
            VStack(alignment: .leading, spacing: 8) {
                configuration.label
                    .markdownTextStyle {
                        FontWeight(.bold)
                        FontSize(.em(1.5))
                        ForegroundColor(.white)
                    }
                Divider().background(.white.opacity(0.15))
            }
            .padding(.top, 24)
            .padding(.bottom, 4)
        }
        .heading2 { configuration in
            configuration.label
                .markdownTextStyle {
                    FontWeight(.semibold)
                    FontSize(.em(1.3))
                    ForegroundColor(.white)
                }
                .padding(.top, 18)
                .padding(.bottom, 2)
        }
        .heading3 { configuration in
            configuration.label
                .markdownTextStyle {
                    FontWeight(.semibold)
                    FontSize(.em(1.15))
                    ForegroundColor(.white)
                }
                .padding(.top, 14)
        }
        .heading4 { configuration in
            configuration.label
                .markdownTextStyle {
                    FontWeight(.semibold)
                    FontSize(.em(1.0))
                    ForegroundColor(.white.opacity(0.95))
                }
                .padding(.top, 10)
        }

        // MARK: - Paragraph + lists

        .paragraph { configuration in
            configuration.label
                .relativeLineSpacing(.em(0.22))
                .padding(.bottom, 8)
        }
        .listItem { configuration in
            configuration.label
                .markdownMargin(top: 5, bottom: 5)
        }
        .bulletedListMarker(.disc)
        .numberedListMarker(.decimal)

        // MARK: - Blockquote

        .blockquote { configuration in
            configuration.label
                .padding(.leading, 12)
                .padding(.vertical, 6)
                .overlay(alignment: .leading) {
                    Rectangle()
                        .fill(Color.vexCyan.opacity(0.6))
                        .frame(width: 3)
                }
                .markdownTextStyle {
                    ForegroundColor(.white.opacity(0.75))
                    FontStyle(.italic)
                }
        }

        // MARK: - Code block

        .codeBlock { configuration in
            ScrollView(.horizontal, showsIndicators: false) {
                configuration.label
                    .relativeLineSpacing(.em(0.22))
                    .markdownTextStyle {
                        FontFamilyVariant(.monospaced)
                        FontSize(.em(0.85))
                    }
                    .padding(14)
            }
            .background(Color.black.opacity(0.35))
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .strokeBorder(.white.opacity(0.08), lineWidth: 1)
            )
            .markdownMargin(top: 12, bottom: 12)
        }

        // MARK: - Table

        .table { configuration in
            configuration.label
                .markdownMargin(top: 12, bottom: 12)
        }
        .tableCell { configuration in
            configuration.label
                .markdownTextStyle {
                    ForegroundColor(.white.opacity(0.9))
                }
                .padding(.vertical, 6)
                .padding(.horizontal, 10)
                .frame(maxWidth: .infinity, alignment: .leading)
        }

        // MARK: - Image

        .image { configuration in
            configuration.label
                .markdownMargin(top: 12, bottom: 12)
        }
}
