//
//  Settings.swift
//  Notchy
//
//  UserDefaults wrapper and app settings
//

import Foundation

@propertyWrapper
struct UserDefaultsBacked<T: Sendable>: Sendable {
    let key: String
    let defaultValue: T

    var wrappedValue: T {
        get { UserDefaults.standard.object(forKey: key) as? T ?? defaultValue }
        nonmutating set { UserDefaults.standard.set(newValue, forKey: key) }
    }
}

@MainActor
enum Settings {
    @UserDefaultsBacked(key: "selectedScreenId", defaultValue: nil)
    static var selectedScreenId: String?

    @UserDefaultsBacked(key: "notificationSound", defaultValue: "Pop")
    static var notificationSound: String

    @UserDefaultsBacked(key: "launchAtLogin", defaultValue: false)
    static var launchAtLogin: Bool
}
