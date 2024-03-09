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

  func request() async -> Bool {
    let settings = await center.notificationSettings()
    switch settings.authorizationStatus {
    case .denied: return false
    case .notDetermined:
      do {
        let granted = try await self.center.requestAuthorization(options: [.alert, .sound, .badge])
        if granted {
          log.info("Authorization to send notifications granted.")
        } else {
          log.info("Authorization to send notifications denied.")
        }
        return granted
      } catch {
        log.error("Failed to request authorization to send notifications. \(error)")
        return false
      }
    case .authorized:
      return true
    case .provisional:
      return true
    case .ephemeral:
      return true
    default:
      return false
    }
  }

  func settings() async -> UNNotificationSettings {
    await center.notificationSettings()
  }

  func scheduleOnce(title: String, body: String, at date: DateComponents) async {
    let trigger = UNCalendarNotificationTrigger(dateMatching: date, repeats: false)
    let uuidString = UUID().uuidString
    let content = UNMutableNotificationContent()
    content.title = title
    content.body = body
    content.sound = .default
    let request = UNNotificationRequest(identifier: uuidString, content: content, trigger: trigger)
    do {
      try await center.add(request)
      log.info("Scheduled \(content.title) notification at \(date).")
    } catch {
      log.error("Failed to add notification request at \(date). \(error)")
    }
  }
}

class NotificationsDelegate: NSObject, UNUserNotificationCenterDelegate {
  let log = LoggerFactory.shared.system(NotificationsDelegate.self)

  static let current = NotificationsDelegate()

  func userNotificationCenter(
    _ center: UNUserNotificationCenter, willPresent notification: UNNotification
  ) async -> UNNotificationPresentationOptions {
    let content = notification.request.content
    log.info("Handling notification \(content.title) with body \(content.body)...")
    return [.banner, .sound, .badge, .list]
  }
}
