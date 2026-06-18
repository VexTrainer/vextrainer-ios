//
//  DeviceInfo.swift
//  VexTrainer
//
//  Read-only helper that surfaces the basics the support team needs
//  to triage a Contact Us submission: app version, device model,
//  iOS version, and locale.
//
//  Output formatting deliberately keeps it to a single trailing line
//  so it doesn't visually swamp the user's actual message. The model
//  identifier is sent as the raw `iPhoneXX,YY` string — friendly
//  device names go stale every September, so leave the lookup to the
//  support side.
//

import Foundation
import UIKit

enum DeviceInfo {

    /// Raw machine identifier (e.g., "iPhone15,2", "iPad13,1", "x86_64"
    /// on Simulator). Looked up via uname(2). For a friendly name, the
    /// support team can map against any of the public databases.
    static var modelIdentifier: String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let mirror = Mirror(reflecting: systemInfo.machine)
        let raw = mirror.children.compactMap { element -> String? in
            guard let scalar = element.value as? Int8, scalar != 0 else { return nil }
            return String(UnicodeScalar(UInt8(scalar)))
        }.joined()
        return raw.isEmpty ? "unknown" : raw
    }

    /// Marketing version + build number, e.g., "v0.7.0 (1)".
    static var appVersion: String {
        let info = Bundle.main.infoDictionary
        let short = (info?["CFBundleShortVersionString"] as? String) ?? "?"
        let build = (info?["CFBundleVersion"] as? String) ?? "?"
        if build == short || build.isEmpty {
            return "v\(short)"
        }
        return "v\(short) (\(build))"
    }

    /// iOS version, e.g., "17.4".
    static var systemVersion: String {
        UIDevice.current.systemVersion
    }

    /// "iPhone" / "iPad" / "iPod touch".
    static var deviceClass: String {
        UIDevice.current.model
    }

    /// Current locale identifier, e.g., "en_US".
    static var localeIdentifier: String {
        Locale.current.identifier
    }

    /// Single-line footer suitable to append to a Contact Us message
    /// body. Example:
    ///
    ///   ---
    ///   VexTrainer iOS v0.7.0 (1) · iPhone15,2 (iPhone) · iOS 17.4 · en_US
    ///
    /// The leading `---` is a markdown horizontal rule, which renders
    /// as a visual separator if the support team views the message in
    /// any markdown-aware viewer. Falls back to harmless dashes
    /// otherwise.
    static var contactFooter: String {
        "---\nVexTrainer iOS \(appVersion) · \(modelIdentifier) (\(deviceClass)) · iOS \(systemVersion) · \(localeIdentifier)"
    }
}
