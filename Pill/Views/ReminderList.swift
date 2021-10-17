//
//  ContentView.swift
//  Pill
//
//  Created by Michael Skogberg on 25.9.2021.
//

import SwiftUI

struct ReminderList: View {
    @EnvironmentObject var data: Data
    @State private var showingProfile = false
    
    var body: some View {
        NavigationView {
            List {
                NavigationLink(destination: ReminderEdit(reminder: MutableReminder.create())) {
                    Label("Add Reminder", systemImage: "calendar.badge.plus")
                }
                ForEach(data.reminders) { reminder in
                    NavigationLink(destination: ReminderEdit(reminder: reminder.mutable)) {
                        ReminderRow(reminder: reminder)
                    }
                }
            }.navigationTitle("The Pill")
        }.navigationViewStyle(.stack)
    }
}

struct ReminderList_Previews: PreviewProvider {
    static var previews: some View {
        ForEach(["iPhone 12 mini", "iPad Pro (11-inch) (3rd generation)"], id: \.self) { deviceName in
            ReminderList()
                .previewDevice(PreviewDevice(rawValue: deviceName))
                .previewDisplayName(deviceName)
                .environmentObject(Data())
        }
    }
}
