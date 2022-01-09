//
//  ModelData.swift
//  Pill
//
//  Created by Michael Skogberg on 25.9.2021.
//

import Foundation

final class RemindersStore: ObservableObject {
    static let log = LoggerFactory.shared.system(RemindersStore.self)
    
    @Published var reminders: [Reminder] = []
    
    static func load(completion: ([Reminder]) -> Void) {
        completion(Pill.PillSettings.shared.reminders)
    }
    
    static func save(_ newReminders: [Reminder]) {
        Pill.PillSettings.shared.reminders = newReminders
        log.info("Saved \(newReminders.count) reminders.")
    }
    
    static let sampleReminders: [Reminder] = [
        Reminder(id: "1", enabled: true, name: "My daily reminder", when: When.daily(WeekDay.allCases, Time(hour: 15, minute: 48)), halt: Halt.nthWeek(NthSpec(start: Date(), nth: 2)), start: Date()),
        Reminder(id: "2", enabled: true, name: "Second, weekly reminder", when: When.daily([], Time(hour: 08, minute: 10)), halt: nil, start: Date()),
        Reminder(id: "3", enabled: true, name: "Monthly", when: When.monthly([3, 14], Time(hour: 3, minute: 5)), halt: nil, start: Date())
    ]
}

//class UpcomingItemsSource: ObservableObject {
//    @Published var items: [Date] = []
//    private var currentPage = 1
//    
//    let reminder: MutableReminder
//    
//    init(reminder: MutableReminder) {
//        self.reminder = reminder
//    }
//    
//    func loadMore(
//}
