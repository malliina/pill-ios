//
//  ReminderEdit.swift
//  Pill
//
//  Created by Michael Skogberg on 25.9.2021.
//

import SwiftUI

extension HaltInterval {
    var word: String {
        switch self {
        case .none: return "never"
        case .nthWeek: return "week"
        case .monthly: return "month"
        }
    }
    
    var turnOffWord: String {
        switch self {
        case .none: return "never"
        case .nthWeek: return "weekly"
        case .monthly: return "monthly"
        }
    }
}

extension Interval {
    var word: String {
        switch self {
        case .none: return "never"
        case .daily: return "daily"
        case .monthly: return "monthly"
        }
    }
}

struct ReminderEdit: View {
    @Environment(\.editMode) var editMode
    @State var reminder: MutableReminder
    
    let calendar = Calendar.current
    var start: Date { reminder.start }
    static let dateFormatter = Dates.current.formatter()
    
    func onTestNow() {
        Notifications.current.request()
        let date = calendar.date(byAdding: .second, value: 1, to: Date()) ?? Date()
        let when = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
        Notifications.current.scheduleOnce(title: "Test reminder", body: reminder.name, at: when)
    }
    var dateText: String { reminder.whenInterval == .none ? "Date" : "Starting" }
    
    var body: some View {
        List {
            Group {
                HStack {
                    Text("Name").bold()
                    Divider()
                    TextField("My reminder", text: $reminder.name)
                }
                DatePicker("Remind at", selection: $reminder.timeAsDate, displayedComponents: [.hourAndMinute])
                DatePicker(dateText, selection: $reminder.start, displayedComponents: [.date])
                Picker(selection: $reminder.whenInterval) {
                    ForEach(Interval.allCases) { i in
                        Text(i.word).tag(i)
                    }
                } label: {
                    Label("Repeat", systemImage: "repeat")
                }
                if reminder.whenInterval == .daily {
                    NavigationLink(destination: WeekDaysSelector(weekDays: $reminder.whenWeekDays)) {
                        Label("Select weekdays", systemImage: "calendar.badge.plus")
                    }
                }
                if reminder.whenInterval == .monthly {
                    NavigationLink(destination: DaysOfMonthSelector(monthDays: $reminder.whenDaysOfMonth)) {
                        Label("Select days of month", systemImage: "calendar.badge.plus")
                    }
                }
                if reminder.whenInterval != .none {
                    Picker(selection: $reminder.haltInterval) {
                        ForEach(HaltInterval.allCases) { i in
                            Text(i.turnOffWord).tag(i)
                        }
                    } label: {
                        Label("Turn off", systemImage: "bell.slash")
                    }
                }
                if reminder.haltInterval != .none && reminder.whenInterval != .none {
                    Stepper(value: $reminder.haltNth, in: 2...10) {
                        Text("Turn off every \(reminder.haltNth) \(reminder.haltInterval.word)s")
                    }
                }
            }
            Button(action: onTestNow) {
                Label("Send test reminder now", systemImage: "bell.and.waveform")
            }
            Toggle(isOn: $reminder.enabled) {
                Text("Enable").bold()
            }
            Spacer()
            Label("Upcoming reminders", systemImage: "calendar").font(.body.bold())
            ForEach(reminder.upcoming(from: reminder.start, limit: 10), id: \.self) { date in
                Text(ReminderEdit.dateFormatter.string(from: date))
            }
        }
    }
}

struct ReminderEdit_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ReminderEdit(reminder: Data().reminders[0].mutable)
        }
    }
}
