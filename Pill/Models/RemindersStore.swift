//
//  ModelData.swift
//  Pill
//
//  Created by Michael Skogberg on 25.9.2021.
//

import Foundation

class RemindersStore: ObservableObject {
    let log = LoggerFactory.shared.system(RemindersStore.self)
    static let current = RemindersStore()
    
    @Published var reminders: [Reminder] = []
    var settings: PillSettings { PillSettings.shared }
    
    func load() async -> [Reminder] {
        await withCheckedContinuation { continuation in
            continuation.resume(returning: settings.reminders)
        }
    }
    
    func save(_ newReminders: [Reminder]) async {
        settings.reminders = newReminders
        log.info("Saved \(newReminders.count) reminders.")
        await RemindersNotifications.current.resetAllNow()
    }
    
    static let sampleReminders: [Reminder] = [
        Reminder(id: "1", enabled: true, name: "My daily reminder", when: When.daily(WeekDay.allCases, Time(hour: 15, minute: 48)), halt: Halt.nthWeek(NthSpec(start: Date(), nth: 2)), start: Date()),
        Reminder(id: "2", enabled: true, name: "Second, weekly reminder", when: When.daily([], Time(hour: 08, minute: 10)), halt: nil, start: Date()),
        Reminder(id: "3", enabled: true, name: "Monthly", when: When.monthly(Time(hour: 3, minute: 5)), halt: nil, start: Date()),
        Reminder(id: "4", enabled: true, name: "Days of month", when: When.daysOfMonth([3, 14], Time(hour: 3, minute: 5)), halt: nil, start: Date()),
        Reminder(id: "5", enabled: true, name: "One shot", when: When.once(Date.now), halt: nil, start: Date.now)
    ]
}
