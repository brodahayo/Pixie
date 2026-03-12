//
//  Settings.swift
//  Notchy
//
//  UserDefaults wrapper and app settings
//

import Foundation

enum Settings {
    static var selectedScreenId: String? {
        get { UserDefaults.standard.string(forKey: "selectedScreenId") }
        set { UserDefaults.standard.set(newValue, forKey: "selectedScreenId") }
    }

    static var notificationSound: String {
        get { UserDefaults.standard.string(forKey: "notificationSound") ?? "Pop" }
        set { UserDefaults.standard.set(newValue, forKey: "notificationSound") }
    }

    static var launchAtLogin: Bool {
        get { UserDefaults.standard.bool(forKey: "launchAtLogin") }
        set { UserDefaults.standard.set(newValue, forKey: "launchAtLogin") }
    }
}
