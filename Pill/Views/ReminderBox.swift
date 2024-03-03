import SwiftUI

extension Date {
  var describe: String { Dates.current.dateOnly().string(from: self) }
}

struct ReminderBox: View {
  let reminder: Reminder

  var showStart: Bool {
    return switch reminder.when {
    case .once(_):
      false
    case .daily(_, _):
      reminder.start > Date.now
    case .monthly(_):
      true
    case .daysOfMonth(_, _):
      reminder.start > Date.now
    case .lastDayOfMonth(_):
      reminder.start > Date.now
    }
  }

  var body: some View {
    HStack {
      VStack(alignment: .leading) {
        Text(reminder.name)
          .font(.title)
          .foregroundColor(.primary)
        Text(reminder.describe)
          .font(.subheadline)
          .foregroundColor(.secondary)
        if showStart {
          Text("Starting \(reminder.start.describe)")
            .font(.subheadline)
            .foregroundColor(.secondary)
        }
        if let halt = reminder.halt {
          Text("Halted \(halt.describe)")
            .font(.subheadline)
            .foregroundColor(.secondary)
        }
      }
      Spacer()
    }
  }
}

struct ReminderBoxPreviews: PreviewProvider {
  static var reminders = RemindersStore.sampleReminders
  static var previews: some View {
    Group {
      ReminderBox(reminder: reminders[0])
      ReminderBox(reminder: reminders[1])
      ReminderBox(reminder: reminders[2])
    }.previewLayout(.fixed(width: 300, height: 70))

  }
}
