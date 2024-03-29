import SwiftUI

@main
struct PillApp: App {
  static let log = LoggerFactory.shared.system(PillApp.self)

  @StateObject private var store = RemindersStore()

  func reload() async {
    let cal = Calendar.current
    if let date = PillSettings.shared.lastScheduling?.asDate,
      let threshold = cal.date(byAdding: .day, value: 3, to: date),
      threshold > Date.now
    {
      PillApp.log.info("Scheduling is recent enough, will not schedule for now.")
    } else {
      await store.resetAllNow()
    }
  }

  var body: some Scene {
    WindowGroup {
      ReminderList()
        .environmentObject(store)
        .task {
          await reload()
        }
    }
  }
}
