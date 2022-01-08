//
//  ContentView.swift
//  Pill
//
//  Created by Michael Skogberg on 25.9.2021.
//

import SwiftUI

struct ReminderList: View {
    let log = LoggerFactory.shared.system(ReminderList.self)
    @EnvironmentObject var data: RemindersStore
    @State private var showingProfile = false
    @State private var isAddingNewView = false
    @Environment(\.scenePhase) private var scenePhase
    
    func onAddNew() {
        isAddingNewView = true
    }
    
    var body: some View {
        NavigationView {
            List {
                Button(action: onAddNew) {
                    Label("Add Reminder", systemImage: "calendar.badge.plus")
                }
                ForEach(data.reminders) { reminder in
                    NavigationLink(destination: ReminderEdit(reminder: reminder.mutable, isNew: false) { r in
                        log.info("Save edited \(r.name).")
                        let idx = data.reminders.firstIndex { rem in
                            rem.id == r.id
                        }
                        if let idx = idx {
                            data.reminders[idx] = r
                        }
                        RemindersStore.save(data.reminders)
                    }) {
                        ReminderRow(reminder: reminder)
                    }
                }
            }.navigationTitle("The Pill")
        }
        .navigationViewStyle(.stack)
        .sheet(isPresented: $isAddingNewView) {
            NavigationView {
                ReminderEdit(reminder: MutableReminder.create(), isNew: true) { r in
                    log.info("Save new \(r.name)")
                    data.reminders.append(r)
                    RemindersStore.save(data.reminders)
                }
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Dismiss") {
                            onDoneAdding()
                        }
                    }
                }
            }
        }
        .onAppear {
            RemindersStore.load { reminders in
                self.log.info("Loaded \(reminders.count) reminders.")
                data.reminders = reminders
            }
        }
        .onChange(of: scenePhase) { phase in
            log.info("Phase \(phase)")
            if phase == .inactive {
                // fix: when resuming app, this saves because the resume scenes are:
                // background -> inactive -> active
//                log.info("Saving due to inactive scene phase...")
//                RemindersStore.save(data.reminders)
            }
        }
    }
    
    func onDoneAdding() {
        isAddingNewView = false
    }
}

struct ReminderList_Previews: PreviewProvider {
    static var previews: some View {
        ForEach(["iPhone 12 mini", "iPad Pro (11-inch) (3rd generation)"], id: \.self) { deviceName in
            ReminderList()
                .previewDevice(PreviewDevice(rawValue: deviceName))
                .previewDisplayName(deviceName)
                .environmentObject(RemindersStore())
        }
    }
}
