//
//  CorrectAnswerParser.swift
//  VexTrainer
//
//  The server returns correctAnswerJson as a snake_case string like:
//    {"answer_id":4306}                    (single)
//    [{"answer_id":4300},{"answer_id":4301}] (multi / match)
//    {"text":"fiasco"}                     (fill-in-blank — no IDs)
//
//  Rather than maintaining a snake_case Decoder just for this, we regex-extract
//  every answer_id (or answerId) integer. Matches Android's parseCorrectMatchIds
//  approach.
//

import Foundation

enum CorrectAnswerParser {
    /// Returns every answer ID found in the JSON, in encounter order.
    /// Empty array for fill-in-blank or null input.
    static func extractAnswerIds(from json: String?) -> [Int] {
        guard let json, !json.isEmpty else { return [] }
        let pattern = #""(?:answer_id|answerId)"\s*:\s*(\d+)"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }
        let nsRange = NSRange(json.startIndex..<json.endIndex, in: json)
        let matches = regex.matches(in: json, range: nsRange)
        return matches.compactMap { match -> Int? in
            guard match.numberOfRanges >= 2,
                  let range = Range(match.range(at: 1), in: json),
                  let value = Int(json[range]) else { return nil }
            return value
        }
    }
}
