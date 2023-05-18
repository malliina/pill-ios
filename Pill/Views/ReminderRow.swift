import SwiftUI

struct ReminderRow: View {
    var reminder: Reminder
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(reminder.name)
                    .font(.title)
                    .foregroundColor(.primary)
                Text(reminder.when.describe)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            Spacer()
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
