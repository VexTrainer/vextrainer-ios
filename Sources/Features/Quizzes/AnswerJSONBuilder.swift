//
//  AnswerJSONBuilder.swift
//  VexTrainer
//
//  Builds the `answerJson` string used in POST /Quiz/attempts/{id}/answer.
//  Format is question-type dependent. Centralized so we never build it
//  inline in the view model.
//

import Foundation

enum AnswerJSONBuilder {

    /// Single answer (typeId 1) or true/false (typeId 4 without matchSide).
    ///
    /// Format per sp_SubmitAnswer (type 1/4):
    ///   {"answer_id": N}
    /// SP reads via JSON_VALUE(@user_answer_json, '$.answer_id') — snake_case
    /// path, so the key must be snake_case (the .NET layer passes the JSON
    /// string through as-is to the SP, no key transformation).
    static func single(answerId: Int) -> String {
        encode(["answer_id": answerId])
    }

    /// Multiple answer (typeId 2). Sorted for stable equality.
    ///
    /// Format per sp_SubmitAnswer (type 2):
    ///   {"answer_ids": [N, M, ...]}
    /// SP reads via OPENJSON(@user_answer_json, '$.answer_ids').
    static func multiple(answerIds: [Int]) -> String {
        encode(["answer_ids": answerIds.sorted()])
    }

    /// Fill-in-blank (typeId 3). Trims surrounding whitespace.
    static func fillInBlank(text: String) -> String {
        encode(["text": text.trimmingCharacters(in: .whitespacesAndNewlines)])
    }

    /// Matching question (any typeId, has matchSide on answers).
    ///
    /// Format per sp_SubmitAnswer (type 5):
    ///   {"matches":[{"left":N,"right":M}, ...]}
    /// Outer key is `matches` (not `pairs`). Inner keys are `left`/`right`
    /// (not `leftId`/`rightId`). The SP reads via:
    ///   OPENJSON(@user_answer_json, '$.matches')
    ///     WITH (left_id INT '$.left', right_id INT '$.right')
    static func matching(pairs: [(leftId: Int, rightId: Int)]) -> String {
        let pairDicts = pairs.map { ["left": $0.leftId, "right": $0.rightId] }
        return encode(["matches": pairDicts])
    }

    // MARK: - Private

    private static func encode(_ object: Any) -> String {
        guard let data = try? JSONSerialization.data(withJSONObject: object, options: [.sortedKeys]),
              let str = String(data: data, encoding: .utf8) else {
            return "{}"
        }
        return str
    }
}
