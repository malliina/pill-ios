import SwiftUI

extension Date {
    var describe: String { Dates.current.formatter().string(from: self) }
}

struct ReminderBox: View {
    let reminder: Reminder
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(reminder.name)
                    .font(.title)
                    .foregroundColor(.primary)
                Text(reminder.when.describe)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text("Starting \(reminder.start.describe)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
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

struct ReminderBox_Previews: PreviewProvider {
    static var reminders = RemindersStore.sampleReminders
    static var previews: some View {
        Group {
            ReminderBox(reminder: reminders[0])
            ReminderBox(reminder: reminders[1])
            ReminderBox(reminder: reminders[2])
        }.previewLayout(.fixed(width: 300, height: 70))
        
    }
}
