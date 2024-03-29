import SwiftUI

extension HaltInterval {
  var word: String {
    return switch self {
    case .none: "never"
    case .nthWeek: "week"
    case .nthMonth: "month"
    //        case .monthly: return "month"
    }
  }

  var turnOffWord: String {
    return switch self {
    case .none: "never"
    case .nthWeek: "weekly"
    case .nthMonth: "monthly"
    //        case .monthly: return "monthly"
    }
  }
}

extension Interval {
  var word: String {
    return switch self {
    case .none: "never"
    case .daily: "daily or weekly"
    case .monthly: "monthly"
    case .daysOfMonth: "days of month"
    case .lastDayOfMonth: "last day of month"
    }
  }
}

extension MutableReminder {
  var describeWeekDays: String {
    let selected = selectedWeekDays
    if selected.isEmpty {
      return "Select weekdays"
    } else if selected == WeekDay.allCases {
      return "Every day"
    } else {
      return selected.map { $0.short }.joined(separator: ", ")
    }
  }
  var describeDaysOfMonth: String {
    let selected = selectedDaysOfMonth
    if selected.isEmpty {
      return "Select days of month"
    } else if selected.count == 31 {
      return "All days"
    } else if selected.count < 7 {
      let daysDescribed = selected.map { "\($0)" }.joined(separator: ", ")
      let prefix = selected.count == 1 ? "Day" : "Days"
      return "\(prefix) \(daysDescribed) of month"
    } else {
      return "\(selected.count) days of month"
    }
  }
}

struct ReminderEdit: View {
  let log = LoggerFactory.shared.system(ReminderEdit.self)
  @Environment(\.editMode) var editMode
  @Environment(\.dismiss) var dismiss

  @State var reminder: MutableReminder = MutableReminder.create()

  let isNew: Bool
  let onSave: (Reminder) -> Void
  let delete: (Reminder) -> Void

  let calendar = Calendar.current
  var start: Date { reminder.start }
  static let dateFormatter = Dates.current.formatter()
  var notifications: Notifications { Notifications.current }

  func onTestNow() async {
    if await notifications.request() {
      log.info("Scheduling notification in 1 second.")
      let now = Date.now
      let date = calendar.date(byAdding: .second, value: 1, to: now) ?? now
      await notifications.scheduleOnce(title: reminder.name, body: "", at: date.components)
    } else {
      log.info("Notification permission not granted, not testing.")
    }
  }
  var dateText: String { reminder.whenInterval == .none ? "Date" : "Starting" }
  var upcoming: [Date] { reminder.upcoming(from: reminder.start, now: Date.now, limit: 10) }
  
  var body: some View {
    List {
      Group {
        HStack {
          Text("Name").bold()
          Divider()
          TextField("My reminder", text: $reminder.name)
        }
        DatePicker(selection: $reminder.timeAsDate, displayedComponents: [.hourAndMinute]) {
          Label("Remind at", systemImage: "clock")
        }
        DatePicker(selection: $reminder.start, displayedComponents: [.date]) {
          Label(dateText, systemImage: "play")
        }
        Picker(selection: $reminder.whenInterval) {
          ForEach(Interval.allCases) { i in
            Text(i.word).tag(i)
          }
        } label: {
          Label("Repeat", systemImage: "repeat")
        }
        if reminder.whenInterval == .daily {
          NavigationLink(destination: WeekDaysSelector(weekDays: $reminder.whenWeekDays)) {
            Label(reminder.describeWeekDays, systemImage: "calendar.badge.plus")
          }.navigationViewStyle(.stack)
        }
        if reminder.whenInterval == .daysOfMonth {
          NavigationLink(destination: DaysOfMonthSelector(monthDays: $reminder.whenDaysOfMonth)) {
            Label(reminder.describeDaysOfMonth, systemImage: "calendar.badge.plus")
          }
        }
        if reminder.whenInterval != .none && reminder.whenInterval != .lastDayOfMonth {
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
      Button {
        Task { await onTestNow() }
      } label: {
        Label("Send test reminder now", systemImage: "bell.and.waveform")
      }.disabled(reminder.name.isEmpty)
      Toggle(isOn: $reminder.enabled) {
        Text("Enable").bold()
      }
      if !isNew {
        Spacer()
        Button(role: .destructive) {
          delete(reminder.immutable)
        } label: {
          Label("Delete", systemImage: "trash")
        }
      }
      Spacer()
      Label("Upcoming reminders", systemImage: "calendar")
        .font(.body.bold())
      ForEach(upcoming, id: \.self) { date in
        Text(ReminderEdit.dateFormatter.string(from: date))
      }
      if upcoming.isEmpty {
        Label("No upcoming reminders", systemImage: "nosign")
      }
    }
    .navigationTitle("Edit")
    .toolbar {
      ToolbarItem(placement: .confirmationAction) {
        Button("Save") {
          Task {
            let _ = await Notifications.current.request()
            onSave(reminder.immutable)
            dismiss()
          }
        }.disabled(reminder.name.isEmpty)
      }
    }
  }
}

struct ReminderEditPreviews: PreviewProvider {
  static var previews: some View {
    Group {
      ReminderEdit(reminder: RemindersStore.sampleReminders[4].mutable, isNew: true) { _ in

      } delete: { r in
        ()
      }
    }
  }
}
