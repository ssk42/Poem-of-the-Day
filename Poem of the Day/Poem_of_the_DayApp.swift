//
//  Poem_of_the_DayApp.swift
//  Poem of the Day
//
//  Created by Stephen Reitz on 11/14/24.
//

import SwiftUI
import UIKit

// MARK: - Quick Action Types

enum QuickActionType: String {
    case newPoem    = "com.stevereitz.poemoftheday.newpoem"
    case favorites  = "com.stevereitz.poemoftheday.favorites"
    case vibePoem   = "com.stevereitz.poemoftheday.vibepoem"
}

// MARK: - App Delegate

final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        performActionFor shortcutItem: UIApplicationShortcutItem,
        completionHandler: @escaping (Bool) -> Void
    ) {
        NotificationCenter.default.post(
            name: .quickActionTriggered,
            object: shortcutItem.type
        )
        completionHandler(true)
    }
}

extension Notification.Name {
    static let quickActionTriggered = Notification.Name("QuickActionTriggered")
}

// MARK: - App Entry Point

@main
struct Poem_of_the_DayApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var dependencies = DependencyContainer.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(dependencies)
                .onAppear {
                    registerQuickActions()
                }
        }
    }

    private func registerQuickActions() {
        UIApplication.shared.shortcutItems = [
            UIApplicationShortcutItem(
                type: QuickActionType.newPoem.rawValue,
                localizedTitle: "New Poem",
                localizedSubtitle: nil,
                icon: UIApplicationShortcutIcon(systemImageName: "arrow.clockwise")
            ),
            UIApplicationShortcutItem(
                type: QuickActionType.favorites.rawValue,
                localizedTitle: "Favorites",
                localizedSubtitle: nil,
                icon: UIApplicationShortcutIcon(systemImageName: "heart.fill")
            ),
            UIApplicationShortcutItem(
                type: QuickActionType.vibePoem.rawValue,
                localizedTitle: "Vibe Poem",
                localizedSubtitle: "AI-powered verse",
                icon: UIApplicationShortcutIcon(systemImageName: "brain.head.profile")
            ),
        ]
    }
}
