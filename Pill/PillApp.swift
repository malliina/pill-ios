//
//  PillApp.swift
//  Pill
//
//  Created by Michael Skogberg on 25.9.2021.
//

import SwiftUI

@main
struct PillApp: App {
    @StateObject private var store = RemindersStore()
    
    var body: some Scene {
        WindowGroup {
            ReminderList().environmentObject(store)
        }
    }
}
