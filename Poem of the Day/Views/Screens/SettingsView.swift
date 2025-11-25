//
//  SettingsView.swift
//  Poem of the Day
//
//  Created by Claude on 2025-01-01.
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss
    @State private var showNotificationSettings = false
    @State private var showAbout = false
    @State private var showTelemetryDebug = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                backgroundGradient
                    .ignoresSafeArea()
                
                List {
                    notificationsSection
                    dataSection
                    aboutSection
                    
                    #if DEBUG
                    developerSection
                    #endif
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showNotificationSettings) {
                NotificationSettingsView()
            }
            .sheet(isPresented: $showTelemetryDebug) {
                TelemetryDebugView()
            }
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
    
    private var notificationsSection: some View {
        Section {
            Button {
                showNotificationSettings = true
            } label: {
                HStack {
                    Image(systemName: "bell.badge")
                        .foregroundColor(.blue)
                        .frame(width: 28)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Daily Notifications")
                            .foregroundColor(colorScheme == .dark ? .white : .black)
                        Text("Get reminded about your daily poem")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .accessibilityIdentifier("notification_settings_button")
        } header: {
            Text("Notifications")
        }
        .listRowBackground(colorScheme == .dark ? Color(red: 0.2, green: 0.2, blue: 0.3) : Color.white)
    }
    
    private var dataSection: some View {
        Section {
            HStack {
                Image(systemName: "icloud")
                    .foregroundColor(.blue)
                    .frame(width: 28)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Data Sync")
                        .foregroundColor(colorScheme == .dark ? .white : .black)
                    Text("Poems sync via App Group")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
            }
            
            HStack {
                Image(systemName: "square.and.arrow.up")
                    .foregroundColor(.orange)
                    .frame(width: 28)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Widget")
                        .foregroundColor(colorScheme == .dark ? .white : .black)
                    Text("Add widget from home screen")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        } header: {
            Text("Data & Widget")
        }
        .listRowBackground(colorScheme == .dark ? Color(red: 0.2, green: 0.2, blue: 0.3) : Color.white)
    }
    
    private var aboutSection: some View {
        Section {
            HStack {
                Image(systemName: "info.circle")
                    .foregroundColor(.purple)
                    .frame(width: 28)
                
                Text("Version")
                    .foregroundColor(colorScheme == .dark ? .white : .black)
                
                Spacer()
                
                Text("\(AppConfiguration.appVersion) (\(AppConfiguration.buildNumber))")
                    .foregroundColor(.secondary)
            }
            
            Link(destination: URL(string: "https://poetrydb.org")!) {
                HStack {
                    Image(systemName: "book")
                        .foregroundColor(.green)
                        .frame(width: 28)
                    
                    Text("Poetry Database")
                        .foregroundColor(colorScheme == .dark ? .white : .black)
                    
                    Spacer()
                    
                    Image(systemName: "arrow.up.right.square")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            HStack {
                Image(systemName: "cpu")
                    .foregroundColor(.mint)
                    .frame(width: 28)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("AI Generation")
                        .foregroundColor(colorScheme == .dark ? .white : .black)
                    
                    if #available(iOS 26, *) {
                        Text("Available (iOS 26+)")
                            .font(.caption)
                            .foregroundColor(.green)
                    } else {
                        Text("Requires iOS 26+")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        } header: {
            Text("About")
        }
        .listRowBackground(colorScheme == .dark ? Color(red: 0.2, green: 0.2, blue: 0.3) : Color.white)
    }
    
    #if DEBUG
    private var developerSection: some View {
        Section {
            Button {
                showTelemetryDebug = true
            } label: {
                HStack {
                    Image(systemName: "chart.bar")
                        .foregroundColor(.orange)
                        .frame(width: 28)
                    
                    Text("Telemetry Debug")
                        .foregroundColor(colorScheme == .dark ? .white : .black)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        } header: {
            Text("Developer")
        }
        .listRowBackground(colorScheme == .dark ? Color(red: 0.2, green: 0.2, blue: 0.3) : Color.white)
    }
    #endif
}

// MARK: - Preview

#if DEBUG
struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
            .preferredColorScheme(.light)
        
        SettingsView()
            .preferredColorScheme(.dark)
    }
}
#endif
