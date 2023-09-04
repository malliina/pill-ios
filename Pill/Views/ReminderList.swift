import SwiftUI

struct ReminderList: View {
    let log = LoggerFactory.shared.system(ReminderList.self)
    @EnvironmentObject var data: RemindersStore
    @State private var notificationsDenied: Bool = false
    @State private var showingProfile = false
    @State private var isAddingNewView = false
    @Environment(\.scenePhase) private var scenePhase
    
    func onAddNew() {
        isAddingNewView = true
    }
    
    func onDelete(_ r: Reminder) async {
        data.reminders.removeAll { elem in
            elem.id == r.id
        }
        await data.save(data.reminders)
    }
    
    func versions() -> String? {
        guard let bundleMeta = Bundle.main.infoDictionary,
              let appVersion = bundleMeta["CFBundleShortVersionString"] as? String,
              let buildId = bundleMeta["CFBundleVersion"] as? String else { return nil }
        return "Version \(appVersion) build \(buildId)"
    }
    
    var body: some View {
        NavigationView {
            VStack {
                List {
                    Section {
                        Button(action: onAddNew) {
                            Label("Add Reminder", systemImage: "calendar.badge.plus")
                                .font(.title3.bold())
                                .padding(.vertical)
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
                                Task {
                                    await data.save(data.reminders)
                                }
                            } delete: { r in Task { await onDelete(r) } }) {
                                ReminderRow(reminder: reminder)
                            }.swipeActions {
                                Button(role: .destructive) { Task { await onDelete(reminder) } } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }.listRowBackground(Color(uiColor: .systemBackground))
                    Section {
                        Label(data.upcomings.isEmpty ? "No upcoming reminders" : "Upcoming reminders", systemImage: "calendar")
                            .font(.title3.bold())
                            .padding(.top, 24)
                            .padding(.bottom, 8)
                        ForEach(data.upcomings) { upcoming in
                            Text("\(upcoming.title) at \(upcoming.nextFormatted())")
                        }
                    }
                    .listRowBackground(Color(uiColor: .secondarySystemBackground))
                }.listStyle(.plain)
                if notificationsDenied {
                    Button("Notifications are denied. Please enable notifications for this app in system settings.") {
                        UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
                    }.padding()
                }
                if let versionText = versions() {
                    Text(versionText).font(Font.system(size: 14))
                }
            }.navigationTitle("PillAlarm")
        }
        .navigationViewStyle(.stack)
        .sheet(isPresented: $isAddingNewView) {
            NavigationView {
                ReminderEdit(reminder: MutableReminder.create(), isNew: true) { r in
                    log.info("Save new \(r.name)")
                    data.reminders.append(r)
                    Task {
                        await data.save(data.reminders)
                    }
                } delete: { r in log.info("Unused") }
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Dismiss") {
                            onDoneAdding()
                        }
                    }
                }
            }
        }
        .onChange(of: scenePhase) { phase in
            log.info("Phase \(phase)")
            if phase == .inactive {
                // when resuming app, the resume scenes are:
                // background -> inactive -> active
            }
            if phase == .active {
                Task {
                    await data.refresh()
                    notificationsDenied = (await Notifications.current.settings().authorizationStatus) == .denied
                }
            }
        }
    }
    
    func onDoneAdding() {
        isAddingNewView = false
    }
}

struct ReminderListPreviews: PreviewProvider {
    static var previews: some View {
        ForEach(["iPhone 13 mini", "iPad Pro (11-inch) (4th generation)"], id: \.self) { deviceName in
            ReminderList()
                .previewDevice(PreviewDevice(rawValue: deviceName))
                .previewDisplayName(deviceName)
                .environmentObject(RemindersStore())
        }
    }
}
