//
//  KeychainStore.swift
//  VexTrainer
//
//  Thin wrapper over the KeychainAccess SPM library. Everything that holds a token
//  or other sensitive credential reads/writes through here — never KeychainAccess
//  directly — so we can swap implementations later (e.g. mock for unit tests).
//
//  Keychain access is synchronous and thread-safe in the OS, so this type is a
//  simple Sendable class with no state of its own.
//

import Foundation
import KeychainAccess

protocol KeychainStoring: Sendable {
    func string(forKey key: String) -> String?
    func setString(_ value: String, forKey key: String) throws
    func remove(forKey key: String) throws
    func removeAll() throws
}

final class KeychainStore: KeychainStoring, @unchecked Sendable {

    private let keychain: Keychain

    init(service: String = "com.vextrainer.ios") {
        // Default `accessibility` for KeychainAccess is `.whenUnlocked`, which is right
        // for tokens — they should survive reboots once the device has been unlocked once.
        self.keychain = Keychain(service: service)
    }

    func string(forKey key: String) -> String? {
        try? keychain.get(key)
    }

    func setString(_ value: String, forKey key: String) throws {
        try keychain.set(value, key: key)
    }

    func remove(forKey key: String) throws {
        try keychain.remove(key)
    }

    func removeAll() throws {
        try keychain.removeAll()
    }
}
