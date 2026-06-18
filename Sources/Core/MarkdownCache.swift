//
//  MarkdownCache.swift
//  VexTrainer
//
//  Tiny in-memory LRU cache for fetched topic markdown. Covers two real
//  usage patterns:
//
//   (a) Sequential reading inside a lesson — students sometimes flip
//       back a topic or two to re-read. Cache hits make those instant.
//   (b) Re-entering a lesson the user has already started — same.
//
//  Capacity is deliberately small (20 entries). Each markdown is
//  typically 5–50KB, so the upper bound is ~1MB. The cache is in-memory
//  only — wiped on app termination, which is fine because TopicViewer's
//  load-on-appear semantics handle the cold-start fetch naturally and
//  the dashboard load cycle already revalidates progress on login.
//
//  Thread safety: actor isolation, so any caller can `await` from any
//  context. LessonService (which is `@unchecked Sendable`) and any
//  future caller stay correct without manual locking.
//

import Foundation

actor MarkdownCache {

    /// Process-wide singleton. The cache's lifetime equals the app
    /// process, which is the intended LRU scope.
    static let shared = MarkdownCache(capacity: 20)

    private let capacity: Int
    private var storage: [String: String] = [:]
    /// Most-recently-used at the tail; oldest at the head. Tracked
    /// explicitly because Swift dictionaries aren't ordered.
    private var accessOrder: [String] = []

    init(capacity: Int) {
        self.capacity = max(1, capacity)
    }

    /// Returns the cached markdown for `key`, or nil if not present.
    /// As a side effect, marks the entry as most-recently-used.
    func get(_ key: String) -> String? {
        guard let value = storage[key] else { return nil }
        touch(key)
        return value
    }

    /// Stores `value` under `key`. If the cache is at capacity, evicts
    /// the least-recently-used entry to make room.
    func set(_ key: String, _ value: String) {
        if storage[key] != nil {
            // Existing key — just refresh access order and overwrite.
            touch(key)
            storage[key] = value
            return
        }
        storage[key] = value
        accessOrder.append(key)
        while accessOrder.count > capacity {
            let evicted = accessOrder.removeFirst()
            storage.removeValue(forKey: evicted)
        }
    }

    /// Drops every entry. Useful for sign-out flows so the next user
    /// can't see content the previous user fetched (though for public
    /// lesson content this is a minor concern).
    func clear() {
        storage.removeAll()
        accessOrder.removeAll()
    }

    private func touch(_ key: String) {
        accessOrder.removeAll { $0 == key }
        accessOrder.append(key)
    }
}
