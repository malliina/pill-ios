//
//  RemindersNotifications.swift
//  Pill
//
//  Created by Michael Skogberg on 29.4.2022.
//

import Foundation

struct DatedReminder {
    let date: Date
    let reminder: Reminder
}

class RemindersNotifications {
    let log = LoggerFactory.shared.system(RemindersNotifications.self)
    static let current = RemindersNotifications(reminders: RemindersStore.current, notifications: Notifications.current)
    
    let remindersStore: RemindersStore
    let notifications: Notifications
    
    init(reminders: RemindersStore, notifications: Notifications) {
        self.remindersStore = reminders
        self.notifications = notifications
    }
    
    func resetAllNow() async {
        await reset(reminders: await remindersStore.load(), from: Date.now)
    }
    
    func reset(reminders: [Reminder], from: Date) async {
        notifications.center.removeAllPendingNotificationRequests()
        await schedule(reminders: reminders, from: from)
    }
    
    private func schedule(reminders: [Reminder], from: Date, limit: Int = 64) async {
        let sorted = reminders.flatMap { reminder in
            return reminder.upcoming(from: from, limit: limit).map { date in
                return DatedReminder(date: date, reminder: reminder)
            }
        }.sorted { dr1, dr2 in
            dr1.date < dr2.date
        }.prefix(limit)
        for dr in sorted {
            let reminder = dr.reminder
            await notifications.scheduleOnce(title: reminder.name, body: "", at: dr.date.components)
        }
//        sorted.forEach { dr in
//            let reminder = dr.reminder
//            await notifications.scheduleOnce(title: reminder.name, body: "", at: dr.date.components)
//        }
        log.info("Scheduled \(sorted.count) reminders.")
    }
}
