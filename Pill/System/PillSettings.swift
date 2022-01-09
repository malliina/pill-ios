//
//  PillSettings.swift
//  Pill
//
//  Created by Michael Skogberg on 16.10.2021.
//

import Foundation

enum PillError: LocalizedError {
    case general(String)
    public var errorDescription: String? {
        switch self {
        case .general(let msg): return msg
        }
    }
}

class PillSettings {
    let log = LoggerFactory.shared.system(PillSettings.self)
    static let shared = PillSettings()
    
    let prefs = UserDefaults.standard
    
    let decoder = JSONDecoder()
    let encoder = JSONEncoder()
    
    private let remindersKey = "reminders"
    var reminders: [Reminder] {
        get {
            readKey(remindersKey, to: Reminders.self)?.reminders ?? []
        }
        set(rs) {
            write(Reminders(reminders: rs), toKey: remindersKey)
        }
    }
    
    func readKey<T: Decodable>(_ key: String, to: T.Type) -> T? {
        if let str = prefs.string(forKey: key) {
            do {
                return try read(to, data: str)
            } catch {
                log.error("Failed to read \(key). \(error)")
                return nil
            }
        } else {
            log.info("Nothing saved with key \(key).")
            return nil
        }
    }
    
    func read<T: Decodable>(_ t: T.Type, data: String) throws -> T {
        guard let asData = data.data(using: .utf8) else { throw PillError.general("Data is not utf8") }
        return try decoder.decode(t, from: asData)
    }
    
    func write<T: Encodable>(_ t: T, toKey: String) {
        do {
            let data = try encoder.encode(t)
            let str = String(data: data, encoding: .utf8)
            prefs.set(str, forKey: toKey)
            if let str = str {
                log.info("Saved \(str) to \(toKey)")
            } else {
                log.info("Saved nil to \(toKey)")
            }
        } catch let error {
            log.error("Failed to save key '\(toKey)'. \(error)")
        }
    }
}
