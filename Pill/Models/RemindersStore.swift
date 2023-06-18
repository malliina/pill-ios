import Foundation
import UserNotifications

class RemindersStore: ObservableObject {
    let log = LoggerFactory.shared.system(RemindersStore.self)
    
    @Published var reminders: [Reminder] = []
    @Published var upcomings: [Upcoming] = []
    
    var notifications: Notifications { Notifications.current }
    var settings: PillSettings { PillSettings.shared }
    
    func load() async -> [Reminder] {
        await withCheckedContinuation { continuation in
            continuation.resume(returning: settings.reminders)
        }
    }
    
    @MainActor
    func refresh() async {
        reminders = await load()
        await refreshUpcomings()
    }
    
    @MainActor
    private func refreshUpcomings() async {
        let slice = await list().prefix(10)
        upcomings = Array(slice)
        log.info("Refreshed upcomings, now got \(upcomings.count) upcoming alarms: \(upcomings.map({ $0.title }))")
    }
    
    func save(_ newReminders: [Reminder]) async {
        settings.reminders = newReminders
        log.info("Saved \(newReminders.count) reminders.")
        await resetAllNow()
        await refreshUpcomings()
    }
    
    func resetAllNow() async {
        await reset(reminders: await load(), from: Date.now)
    }
    
    func list() async -> [Upcoming] {
        let reqs = await notifications.center.pendingNotificationRequests()
        return reqs.compactMap { req in
            if let trigger = req.trigger as? UNCalendarNotificationTrigger,
                let next = trigger.nextTriggerDate() {
                let fmt = ReminderEdit.dateFormatter.string(from: next)
                return Upcoming(id: "\(req.identifier)-\(req.content.title)-\(fmt)", title: req.content.title, next: next)
            } else {
                return nil
            }
        }.sorted { a, b in
            a.next < b.next
        }
    }
    
    private func reset(reminders: [Reminder], from: Date) async {
        notifications.center.removeAllPendingNotificationRequests()
        await schedule(reminders: reminders, from: from)
        PillSettings.shared.updateScheduling(when: from)
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
        log.info("Scheduled \(sorted.count) reminders.")
    }
    
    static let sampleReminders: [Reminder] = [
        Reminder(id: "1", enabled: true, name: "My daily reminder", when: When.daily(WeekDay.allCases, Time(hour: 15, minute: 48)), halt: Halt.nthWeek(NthSpec(start: Date(), nth: 2)), start: Date()),
        Reminder(id: "2", enabled: true, name: "Second, weekly reminder", when: When.daily([], Time(hour: 08, minute: 10)), halt: nil, start: Date()),
        Reminder(id: "3", enabled: true, name: "Monthly", when: When.monthly(Time(hour: 3, minute: 5)), halt: nil, start: Date()),
        Reminder(id: "4", enabled: true, name: "Days of month", when: When.daysOfMonth([3, 14], Time(hour: 3, minute: 5)), halt: nil, start: Date()),
        Reminder(id: "5", enabled: true, name: "One shot", when: When.once(Date.now), halt: nil, start: Date.now)
    ]
}
