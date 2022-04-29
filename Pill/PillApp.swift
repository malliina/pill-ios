//
//  PillApp.swift
//  Pill
//
//  Created by Michael Skogberg on 25.9.2021.
//

import SwiftUI

@main
struct PillApp: App {
    let log = LoggerFactory.shared.system(PillApp.self)
    
    @StateObject private var store = RemindersStore()
    
    init() {
        let scheduling = Task {
            await RemindersNotifications.current.resetAllNow()
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ReminderList().environmentObject(store)
        }
    }
}
