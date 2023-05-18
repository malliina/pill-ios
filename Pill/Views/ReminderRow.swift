import SwiftUI

struct ReminderRow: View {
    var reminder: Reminder
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(reminder.name).font(.title).foregroundColor(.primary)
                Text(describe(reminder.when)).font(.subheadline).foregroundColor(.secondary)
            }
            Spacer()
        }
    }
    
    func describe(_ when: When) -> String {
        switch when {
        case .once(let date):
            let formattedDate = Dates.current.formatter().string(from: date)
            return "\(formattedDate)"
        case .daily(_, let time):
            return "Daily at \(time.describe)"
        case .monthly(_):
            return "Monthly"
        case .daysOfMonth(let days, _):
            let str = days.map { i in
                "\(i)"
            }.joined(separator: ", ")
            let word = days.count > 1 ? "Days" : "Day"
            return "\(word) \(str) of month"
        }
    }

}

struct ReminderRow_Previews: PreviewProvider {
    static var reminders = RemindersStore.sampleReminders
    static var previews: some View {
        Group {
            ReminderRow(reminder: reminders[0])
            ReminderRow(reminder: reminders[1])
            ReminderRow(reminder: reminders[2])
        }.previewLayout(.fixed(width: 300, height: 70))
        
    }
}
