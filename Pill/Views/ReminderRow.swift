//
//  ReminderRow.swift
//  Pill
//
//  Created by Michael Skogberg on 25.9.2021.
//

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
        case .monthly(_, _):
            return "Monthly"
        }
    }

}

struct ReminderRow_Previews: PreviewProvider {
    static var reminders = Data().reminders
    static var previews: some View {
        Group {
            ReminderRow(reminder: reminders[0])
            ReminderRow(reminder: reminders[1])
            ReminderRow(reminder: reminders[2])
        }.previewLayout(.fixed(width: 300, height: 70))
        
    }
}
