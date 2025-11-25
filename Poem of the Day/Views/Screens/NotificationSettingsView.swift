//
//  NotificationSettingsView.swift
//  Poem of the Day
//
//  Created by Claude on 2025-01-01.
//

import SwiftUI
import UserNotifications

struct NotificationSettingsView: View {
    @StateObject private var viewModel = NotificationSettingsViewModel()
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                backgroundGradient
                    .ignoresSafeArea()
                
                Form {
                    mainToggleSection
                    
                    if viewModel.settings.isEnabled {
                        timeSection
                        optionsSection
                    }
                    
                    aboutSection
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Notifications")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .alert("Enable Notifications", isPresented: $viewModel.showPermissionAlert) {
                Button("Open Settings") {
                    viewModel.openSettings()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Please enable notifications in Settings to receive your daily poem reminder.")
            }
        }
        .task {
            await viewModel.checkAuthorizationStatus()
        }
    }
    
    // MARK: - Background
    
    private var backgroundGradient: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                colorScheme == .dark ? Color(red: 0.1, green: 0.1, blue: 0.2) : Color(red: 0.9, green: 0.95, blue: 1.0),
                colorScheme == .dark ? Color(red: 0.2, green: 0.2, blue: 0.3) : Color(red: 0.8, green: 0.9, blue: 1.0)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    // MARK: - Sections
    
    private var mainToggleSection: some View {
        Section {
            Toggle(isOn: $viewModel.settings.isEnabled) {
                HStack(spacing: 12) {
                    Image(systemName: "bell.badge")
                        .font(.title2)
                        .foregroundColor(.blue)
                        .frame(width: 32)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Daily Poem Reminder")
                            .font(.headline)
                        Text("Get notified when your daily poem is ready")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .onChange(of: viewModel.settings.isEnabled) { _, newValue in
                Task {
                    await viewModel.handleToggleChange(newValue)
                }
            }
            .accessibilityIdentifier("notification_toggle")
        } header: {
            Text("Daily Notifications")
        } footer: {
            if viewModel.authorizationStatus == .denied {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    Text("Notifications are disabled in system settings.")
                        .foregroundColor(.orange)
                }
            }
        }
        .listRowBackground(colorScheme == .dark ? Color(red: 0.2, green: 0.2, blue: 0.3) : Color.white)
    }
    
    private var timeSection: some View {
        Section {
            DatePicker(
                "Notification Time",
                selection: Binding(
                    get: { viewModel.scheduledTime },
                    set: { viewModel.updateScheduledTime($0) }
                ),
                displayedComponents: .hourAndMinute
            )
            .accessibilityIdentifier("notification_time_picker")
        } header: {
            Text("Schedule")
        } footer: {
            Text("You'll receive a notification at this time every day.")
        }
        .listRowBackground(colorScheme == .dark ? Color(red: 0.2, green: 0.2, blue: 0.3) : Color.white)
    }
    
    private var optionsSection: some View {
        Section {
            Toggle(isOn: $viewModel.settings.includePreview) {
                HStack(spacing: 12) {
                    Image(systemName: "text.quote")
                        .foregroundColor(.purple)
                        .frame(width: 24)
                    Text("Include Poem Preview")
                }
            }
            .onChange(of: viewModel.settings.includePreview) { _, _ in
                viewModel.saveSettings()
            }
            .accessibilityIdentifier("include_preview_toggle")
            
            Toggle(isOn: $viewModel.settings.soundEnabled) {
                HStack(spacing: 12) {
                    Image(systemName: "speaker.wave.2")
                        .foregroundColor(.green)
                        .frame(width: 24)
                    Text("Notification Sound")
                }
            }
            .onChange(of: viewModel.settings.soundEnabled) { _, _ in
                viewModel.saveSettings()
            }
            .accessibilityIdentifier("sound_toggle")
        } header: {
            Text("Options")
        }
        .listRowBackground(colorScheme == .dark ? Color(red: 0.2, green: 0.2, blue: 0.3) : Color.white)
    }
    
    private var aboutSection: some View {
        Section {
            HStack {
                Image(systemName: "info.circle")
                    .foregroundColor(.blue)
                VStack(alignment: .leading, spacing: 4) {
                    Text("About Daily Notifications")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Text("Notifications help you maintain a daily poetry habit. Each day, you'll receive a gentle reminder to read your poem of the day.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.vertical, 4)
        }
        .listRowBackground(colorScheme == .dark ? Color(red: 0.2, green: 0.2, blue: 0.3) : Color.white)
    }
}

// MARK: - View Model

@MainActor
class NotificationSettingsViewModel: ObservableObject {
    @Published var settings: NotificationSettings
    @Published var authorizationStatus: UNAuthorizationStatus = .notDetermined
    @Published var showPermissionAlert = false
    
    private let notificationService: NotificationService
    
    var scheduledTime: Date {
        var components = DateComponents()
        components.hour = settings.scheduledHour
        components.minute = settings.scheduledMinute
        return Calendar.current.date(from: components) ?? Date()
    }
    
    init() {
        self.notificationService = NotificationService()
        self.settings = notificationService.getSettings()
    }
    
    func checkAuthorizationStatus() async {
        authorizationStatus = await notificationService.getAuthorizationStatus()
        
        // If previously enabled but now denied, update settings
        if authorizationStatus == .denied && settings.isEnabled {
            settings.isEnabled = false
            saveSettings()
        }
    }
    
    func handleToggleChange(_ enabled: Bool) async {
        if enabled {
            // Request permission if needed
            if authorizationStatus == .notDetermined {
                let granted = await notificationService.requestAuthorization()
                authorizationStatus = granted ? .authorized : .denied
                
                if !granted {
                    settings.isEnabled = false
                    return
                }
            } else if authorizationStatus == .denied {
                settings.isEnabled = false
                showPermissionAlert = true
                return
            }
            
            // Schedule notification
            await notificationService.scheduleDailyNotification(settings: settings, poem: nil)
        } else {
            await notificationService.cancelAllNotifications()
        }
        
        saveSettings()
    }
    
    func updateScheduledTime(_ date: Date) {
        let components = Calendar.current.dateComponents([.hour, .minute], from: date)
        settings.scheduledHour = components.hour ?? 8
        settings.scheduledMinute = components.minute ?? 0
        saveSettings()
        
        Task {
            await notificationService.scheduleDailyNotification(settings: settings, poem: nil)
        }
    }
    
    func saveSettings() {
        notificationService.saveSettings(settings)
    }
    
    func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - Preview

#if DEBUG
struct NotificationSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        NotificationSettingsView()
            .preferredColorScheme(.light)
        
        NotificationSettingsView()
            .preferredColorScheme(.dark)
    }
}
#endif
