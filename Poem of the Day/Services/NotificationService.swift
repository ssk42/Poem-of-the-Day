//
//  NotificationService.swift
//  Poem of the Day
//
//  Created by Claude on 2025-01-01.
//

import Foundation
import UserNotifications

// Wrapper to make UserDefaults sendable since it's thread-safe but not marked as such
private struct SendableUserDefaults: @unchecked Sendable {
    let defaults: UserDefaults
    
    init(_ defaults: UserDefaults) {
        self.defaults = defaults
    }
    
    func data(forKey defaultName: String) -> Data? {
        defaults.data(forKey: defaultName)
    }
    
    func set(_ value: Any?, forKey defaultName: String) {
        defaults.set(value, forKey: defaultName)
    }
}

// MARK: - Notification Configuration

struct NotificationSettings: Codable {
    var isEnabled: Bool
    var scheduledHour: Int
    var scheduledMinute: Int
    var includePreview: Bool
    var soundEnabled: Bool
    
    static let `default` = NotificationSettings(
        isEnabled: false,
        scheduledHour: 8,
        scheduledMinute: 0,
        includePreview: true,
        soundEnabled: true
    )
    
    var scheduledTimeString: String {
        let hour = scheduledHour % 12 == 0 ? 12 : scheduledHour % 12
        let period = scheduledHour < 12 ? "AM" : "PM"
        return String(format: "%d:%02d %@", hour, scheduledMinute, period)
    }
}

// MARK: - Notification Service Protocol

protocol NotificationServiceProtocol: Sendable {
    func requestAuthorization() async -> Bool
    func getAuthorizationStatus() async -> UNAuthorizationStatus
    func scheduleDailyNotification(settings: NotificationSettings, poem: Poem?) async
    func cancelAllNotifications() async
    func getSettings() -> NotificationSettings
    func saveSettings(_ settings: NotificationSettings)
}

// MARK: - Notification Service

actor NotificationService: NotificationServiceProtocol {
    
    // MARK: - Properties
    
    private let notificationCenter: UNUserNotificationCenter
    nonisolated private let userDefaults: SendableUserDefaults
    private let notificationIdentifier = "daily_poem_notification"
    
    // MARK: - Initialization
    
    init(userDefaults: UserDefaults = UserDefaults(suiteName: AppConfiguration.Storage.appGroupIdentifier) ?? .standard) {
        self.notificationCenter = UNUserNotificationCenter.current()
        self.userDefaults = SendableUserDefaults(userDefaults)
    }
    
    // MARK: - Authorization
    
    func requestAuthorization() async -> Bool {
        do {
            let options: UNAuthorizationOptions = [.alert, .sound, .badge]
            let granted = try await notificationCenter.requestAuthorization(options: options)
            
            if granted {
                logInfo("Notification authorization granted", category: .general)
            } else {
                logInfo("Notification authorization denied", category: .general)
            }
            
            return granted
        } catch {
            logError("Failed to request notification authorization: \(error)", category: .error)
            return false
        }
    }
    
    func getAuthorizationStatus() async -> UNAuthorizationStatus {
        let settings = await notificationCenter.notificationSettings()
        return settings.authorizationStatus
    }
    
    // MARK: - Scheduling
    
    func scheduleDailyNotification(settings: NotificationSettings, poem: Poem?) async {
        // Cancel existing notifications first
        await cancelAllNotifications()
        
        guard settings.isEnabled else {
            logInfo("Daily notifications disabled", category: .general)
            return
        }
        
        // Check authorization
        let status = await getAuthorizationStatus()
        guard status == .authorized else {
            logWarning("Cannot schedule notification - not authorized (status: \(status))", category: .general)
            return
        }
        
        // Create notification content
        let content = UNMutableNotificationContent()
        content.title = "🌅 Your Daily Poem Awaits"
        
        if settings.includePreview, let poem = poem {
            content.subtitle = poem.title
            let previewLines = poem.content.components(separatedBy: "\n").prefix(2).joined(separator: " ")
            content.body = previewLines + "..."
        } else {
            content.body = "Start your day with a moment of poetry and reflection."
        }
        
        if settings.soundEnabled {
            content.sound = .default
        }
        
        content.badge = 1
        content.categoryIdentifier = "DAILY_POEM"
        
        // Create trigger for daily notification
        var dateComponents = DateComponents()
        dateComponents.hour = settings.scheduledHour
        dateComponents.minute = settings.scheduledMinute
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        
        // Create request
        let request = UNNotificationRequest(
            identifier: notificationIdentifier,
            content: content,
            trigger: trigger
        )
        
        do {
            try await notificationCenter.add(request)
            logInfo("Scheduled daily notification for \(settings.scheduledTimeString)", category: .general)
        } catch {
            logError("Failed to schedule notification: \(error)", category: .error)
        }
    }
    
    func cancelAllNotifications() async {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [notificationIdentifier])
        notificationCenter.removeAllDeliveredNotifications()
        logInfo("Cancelled all poem notifications", category: .general)
    }
    
    // MARK: - Settings Persistence
    
    nonisolated func getSettings() -> NotificationSettings {
        guard let data = userDefaults.data(forKey: StorageKeys.notificationSettings),
              let settings = try? JSONDecoder().decode(NotificationSettings.self, from: data) else {
            return .default
        }
        return settings
    }
    
    nonisolated func saveSettings(_ settings: NotificationSettings) {
        guard let data = try? JSONEncoder().encode(settings) else { return }
        userDefaults.set(data, forKey: StorageKeys.notificationSettings)
    }
}

// MARK: - Notification Actions

extension NotificationService {
    
    /// Register notification categories and actions
    func registerNotificationCategories() {
        let viewAction = UNNotificationAction(
            identifier: "VIEW_POEM",
            title: "Read Poem",
            options: [.foreground]
        )
        
        let favoriteAction = UNNotificationAction(
            identifier: "FAVORITE_POEM",
            title: "❤️ Favorite",
            options: []
        )
        
        let remindLaterAction = UNNotificationAction(
            identifier: "REMIND_LATER",
            title: "Remind in 1 Hour",
            options: []
        )
        
        let category = UNNotificationCategory(
            identifier: "DAILY_POEM",
            actions: [viewAction, favoriteAction, remindLaterAction],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )
        
        notificationCenter.setNotificationCategories([category])
    }
    
    /// Schedule a reminder notification for later
    func scheduleReminderNotification(in timeInterval: TimeInterval) async {
        let content = UNMutableNotificationContent()
        content.title = "📖 Poem Reminder"
        content.body = "Your daily poem is still waiting for you!"
        content.sound = .default
        content.categoryIdentifier = "DAILY_POEM"
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: timeInterval, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: "poem_reminder_\(Date().timeIntervalSince1970)",
            content: content,
            trigger: trigger
        )
        
        do {
            try await notificationCenter.add(request)
            logInfo("Scheduled reminder notification for \(timeInterval/60) minutes from now", category: .general)
        } catch {
            logError("Failed to schedule reminder: \(error)", category: .error)
        }
    }
}

// MARK: - Mock Service for Testing

final class MockNotificationService: NotificationServiceProtocol, @unchecked Sendable {
    private var _settings = NotificationSettings.default
    private var _authorized = false
    
    func requestAuthorization() async -> Bool {
        _authorized = true
        return true
    }
    
    func getAuthorizationStatus() async -> UNAuthorizationStatus {
        return _authorized ? .authorized : .notDetermined
    }
    
    func scheduleDailyNotification(settings: NotificationSettings, poem: Poem?) async {
        _settings = settings
    }
    
    func cancelAllNotifications() async {
        // No-op for mock
    }
    
    func getSettings() -> NotificationSettings {
        return _settings
    }
    
    func saveSettings(_ settings: NotificationSettings) {
        _settings = settings
    }
}
