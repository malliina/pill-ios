//
//  Notifications.swift
//  Pill
//
//  Created by Michael Skogberg on 15.10.2021.
//

import Foundation
import UserNotifications
import os.log

class Notifications: NSObject, UNUserNotificationCenterDelegate {
    static let current = Notifications()
    
    let log = LoggerFactory.shared.system(Notifications.self)
    let center = UNUserNotificationCenter.current()
    
    override init() {
        // .delegate is weak, so we must use .current here and not just instantiate a class
        center.delegate = NotificationsDelegate.current
    }
    
    func request(onAuthorized: @escaping () -> Void) {
        center.getNotificationSettings { settings in
            switch settings.authorizationStatus {
            case .denied: ()
            case .notDetermined:
                self.center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
                    let log = self.log
                    if let error = error {
                        log.error("Failed to request authorization to send notifications. \(error)")
                    }
                    if granted {
                        log.info("Authorization to send notifications granted.")
                        onAuthorized()
                    } else {
                        log.info("Authorization to send notifications denied.")
                    }
                }
            default: onAuthorized()
            }
        }
        
    }
    
    func scheduleOnce(title: String, body: String, at date: DateComponents) {
        let trigger = UNCalendarNotificationTrigger(dateMatching: date, repeats: false)
        let uuidString = UUID().uuidString
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        let request = UNNotificationRequest(identifier: uuidString, content: content, trigger: trigger)
        center.add(request) { error in
            if let error = error {
                self.log.error("Failed to add notification request at \(date). \(error)")
            } else {
                self.log.info("Scheduled \(content.title) notification at \(date).")
            }
        }
    }
}

class NotificationsDelegate: NSObject, UNUserNotificationCenterDelegate {
    let log = LoggerFactory.shared.system(NotificationsDelegate.self)
    
    static let current = NotificationsDelegate()
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        let content = notification.request.content
        log.info("Handling notification \(content.title) with body \(content.body)...")
        return [.banner, .sound, .badge, .list]
    }
}
