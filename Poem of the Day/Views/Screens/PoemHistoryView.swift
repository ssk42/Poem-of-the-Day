//
//  PoemHistoryView.swift
//  Poem of the Day
//
//  Created by Claude on 2025-01-01.
//

import SwiftUI

struct PoemHistoryView: View {
    @StateObject private var viewModel = PoemHistoryViewModel()
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                backgroundGradient
                    .ignoresSafeArea()
                
                if viewModel.isLoading {
                    loadingView
                } else if viewModel.groupedHistory.isEmpty {
                    emptyStateView
                } else {
                    historyListView
                }
            }
            .navigationTitle("Poem History")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                #if os(visionOS)
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
                #elseif os(iOS)
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
                #endif
                
                #if os(iOS)
                ToolbarItem(placement: .navigationBarLeading) {
                    Menu {
                        Button(role: .destructive) {
                            viewModel.showClearConfirmation = true
                        } label: {
                            Label("Clear History", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                    .disabled(viewModel.groupedHistory.isEmpty)
                    .accessibilityIdentifier("history_menu_button")
                }
                #endif
            }
            .alert("Clear History", isPresented: $viewModel.showClearConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Clear All", role: .destructive) {
                    Task {
                        await viewModel.clearHistory()
                    }
                }
            } message: {
                Text("This will permanently delete all poem history. This action cannot be undone.")
            }
        }
        .task {
            await viewModel.loadHistory()
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
    
    // MARK: - Loading View
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
            #if !os(macOS)
                .scaleEffect(1.2)
            #endif
            Text("Loading history...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 70))
                .foregroundColor(.gray)
            
            VStack(spacing: 8) {
                Text("No Poem History Yet")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Poems you view will appear here so you can revisit them anytime.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            Button("Done") {
                dismiss()
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(Capsule().fill(Color.blue))
            .foregroundColor(.white)
            .padding(.top, 8)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("No poem history yet. Poems you view will appear here.")
    }
    
    // MARK: - History List
    
    private var historyListView: some View {
        VStack(spacing: 0) {
            // Stats header
            if let streak = viewModel.streakInfo {
                streakHeader(streak)
            }
            
            List {
                ForEach(viewModel.groupedHistory, id: \.date) { group in
                    Section {
                        ForEach(group.entries) { entry in
                            NavigationLink(destination: HistoryPoemDetailView(entry: entry)) {
                                HistoryEntryRow(entry: entry)
                            }
                            .listRowBackground(
                                colorScheme == .dark ? Color(red: 0.2, green: 0.2, blue: 0.3) : Color.white
                            )
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    Task {
                                        await viewModel.deleteEntry(entry)
                                    }
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    } header: {
                        Text(sectionHeader(for: group.date))
                            .font(.headline)
                            .foregroundColor(colorScheme == .dark ? .white : .black)
                    }
                }
            }
            #if os(iOS)
            .listStyle(InsetGroupedListStyle())
            #endif
            .scrollContentBackground(.hidden)
        }
    }
    
    // MARK: - Streak Header
    
    private func streakHeader(_ streak: StreakInfo) -> some View {
        HStack(spacing: 20) {
            streakStat(
                value: "\(streak.currentStreak)",
                label: "Current Streak",
                icon: "flame.fill",
                color: streak.currentStreak > 0 ? .orange : .gray
            )
            
            Divider()
                .frame(height: 40)
            
            streakStat(
                value: "\(streak.longestStreak)",
                label: "Longest Streak",
                icon: "trophy.fill",
                color: .yellow
            )
            
            Divider()
                .frame(height: 40)
            
            streakStat(
                value: "\(streak.totalDaysWithPoems)",
                label: "Total Days",
                icon: "calendar",
                color: .blue
            )
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(colorScheme == .dark ? Color(red: 0.2, green: 0.2, blue: 0.3) : Color.white)
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        )
        .padding()
    }
    
    private func streakStat(value: String, label: String, icon: String, color: Color) -> some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                .foregroundColor(color)
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
            }
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }
    
    // MARK: - Helpers
    
    private func sectionHeader(for date: Date) -> String {
        if Calendar.current.isDateInToday(date) {
            return "Today"
        } else if Calendar.current.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            return formatter.string(from: date)
        }
    }
}

// MARK: - History Entry Row

struct HistoryEntryRow: View {
    let entry: PoemHistoryEntry
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        HStack(spacing: 12) {
            // Vibe indicator or source icon
            ZStack {
                Circle()
                    .fill(vibeColor.opacity(0.2))
                    .frame(width: 44, height: 44)
                
                if let vibe = entry.vibeAtTime {
                    Text(vibe.emoji)
                        .font(.title3)
                } else {
                    Image(systemName: entry.source.icon)
                        .foregroundColor(vibeColor)
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(entry.poem.title)
                    .font(.headline)
                    .lineLimit(1)
                
                HStack(spacing: 8) {
                    if let author = entry.poem.author {
                        Text(author)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                    
                    Text("•")
                        .foregroundColor(.secondary)
                    
                    Text(entry.source.displayName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    // Add debug info for UI tests
                    if AppConfiguration.Testing.isUITesting {
                        Text(entry.id.uuidString.prefix(4))
                            .font(.caption2)
                            .foregroundColor(.gray)
                            .accessibilityIdentifier("entry_id_\(entry.id.uuidString)")
                    }
                }
                
                Text(entry.poem.content)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            Spacer()
            
            // Time
            Text(timeString)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 8)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(entry.poem.title) by \(entry.poem.author ?? "Unknown"), viewed \(entry.relativeDateString)")
    }
    
    private var vibeColor: Color {
        if let vibe = entry.vibeAtTime {
            return Color.vibeColor(for: vibe)
        }
        return .blue
    }
    
    private var timeString: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: entry.viewedDate)
    }
}

// MARK: - History Poem Detail View

struct HistoryPoemDetailView: View {
    let entry: PoemHistoryEntry
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Metadata header
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        if let vibe = entry.vibeAtTime {
                            Label("\(vibe.emoji) \(vibe.displayName)", systemImage: "sparkles")
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Capsule().fill(Color.vibeColor(for: vibe).opacity(0.2)))
                        }
                        
                        Label(entry.source.displayName, systemImage: entry.source.icon)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Capsule().fill(Color.gray.opacity(0.2)))
                        
                        Spacer()
                        
                        Text(entry.formattedDate)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.bottom, 8)
                
                // Poem content
                Text(entry.poem.title)
                    .font(.system(size: 28, weight: .bold, design: .serif))
                    .accessibilityIdentifier("poem_title")
                
                if let author = entry.poem.author {
                    Text("by \(author)")
                        .font(.system(size: 18, weight: .medium, design: .serif))
                        .foregroundColor(.secondary)
                }
                
                Divider()
                
                Text(entry.poem.content)
                    .font(.system(size: 18, weight: .regular, design: .serif))
                    .lineSpacing(8)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier("poem_content")
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(
            LinearGradient(
                gradient: Gradient(colors: [
                    colorScheme == .dark ? Color(red: 0.1, green: 0.1, blue: 0.2) : Color(red: 0.9, green: 0.95, blue: 1.0),
                    colorScheme == .dark ? Color(red: 0.2, green: 0.2, blue: 0.3) : Color(red: 0.8, green: 0.9, blue: 1.0)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        )
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }
}



// MARK: - Preview

#if DEBUG
struct PoemHistoryView_Previews: PreviewProvider {
    static var previews: some View {
        PoemHistoryView()
            .preferredColorScheme(.light)
        
        PoemHistoryView()
            .preferredColorScheme(.dark)
    }
}
#endif
