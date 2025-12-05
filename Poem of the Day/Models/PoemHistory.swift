//
//  PoemHistory.swift
//  Poem of the Day
//
//  Created by Claude on 2025-01-01.
//

import Foundation

// MARK: - History Entry Model

struct PoemHistoryEntry: Identifiable, Codable, Equatable {
    let id: UUID
    let poem: Poem
    let viewedDate: Date
    let source: PoemSource
    let vibeAtTime: DailyVibe?
    
    init(poem: Poem, viewedDate: Date = Date(), source: PoemSource = .api, vibeAtTime: DailyVibe? = nil) {
        self.id = UUID()
        self.poem = poem
        self.viewedDate = viewedDate
        self.source = source
        self.vibeAtTime = vibeAtTime ?? poem.vibe
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: viewedDate)
    }
    
    var dayOfWeek: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter.string(from: viewedDate)
    }
    
    var isToday: Bool {
        Calendar.current.isDateInToday(viewedDate)
    }
    
    var isYesterday: Bool {
        Calendar.current.isDateInYesterday(viewedDate)
    }
    
    var relativeDateString: String {
        if isToday {
            return "Today"
        } else if isYesterday {
            return "Yesterday"
        } else {
            return formattedDate
        }
    }
}

enum PoemSource: String, Codable {
    case api = "api"
    case aiGenerated = "ai_generated"
    case customPrompt = "custom_prompt"
    case cached = "cached"
    
    var displayName: String {
        switch self {
        case .api: return "PoetryDB"
        case .aiGenerated: return "AI Generated"
        case .customPrompt: return "Custom"
        case .cached: return "Cached"
        }
    }
    
    var icon: String {
        switch self {
        case .api: return "network"
        case .aiGenerated: return "brain.head.profile"
        case .customPrompt: return "pencil.and.outline"
        case .cached: return "internaldrive"
        }
    }
}

// MARK: - History Service Protocol

protocol PoemHistoryServiceProtocol: Sendable {
    func addEntry(_ poem: Poem, source: PoemSource, vibe: DailyVibe?) async
    func getHistory() async -> [PoemHistoryEntry]
    func getHistory(for date: Date) async -> [PoemHistoryEntry]
    func getHistoryGroupedByDate() async -> [(date: Date, entries: [PoemHistoryEntry])]
    func clearHistory() async
    func deleteEntry(_ entry: PoemHistoryEntry) async
    func getEntryCount() async -> Int
    func getUniquePoems() async -> Int
    func getStreakInfo() async -> StreakInfo
}

// MARK: - Streak Info

struct StreakInfo: Codable, Equatable {
    let currentStreak: Int
    let longestStreak: Int
    let totalDaysWithPoems: Int
    let lastViewedDate: Date?
    
    static let empty = StreakInfo(currentStreak: 0, longestStreak: 0, totalDaysWithPoems: 0, lastViewedDate: nil)
}

// MARK: - History Service

actor PoemHistoryService: PoemHistoryServiceProtocol {
    
    // MARK: - Properties
    
    private let userDefaults: UserDefaults
    private let maxHistoryEntries = 365 // Keep one year of history
    private var cache: [PoemHistoryEntry]?
    
    // MARK: - Initialization
    
    init(userDefaults: UserDefaults = UserDefaults(suiteName: AppConfiguration.Storage.appGroupIdentifier) ?? .standard) {
        self.userDefaults = userDefaults
    }
    
    // MARK: - Public Methods
    
    func addEntry(_ poem: Poem, source: PoemSource, vibe: DailyVibe?) async {
        var history = await loadHistory()
        
        // Check if we already have an entry for this poem today
        let today = Calendar.current.startOfDay(for: Date())
        let existingTodayEntry = history.first { entry in
            Calendar.current.isDate(entry.viewedDate, inSameDayAs: today) &&
            entry.poem.id == poem.id
        }
        
        // Don't add duplicate entries for the same poem on the same day
        if existingTodayEntry != nil {
            logDebug("Poem already in today's history, skipping", category: .repository)
            return
        }
        
        let entry = PoemHistoryEntry(
            poem: poem,
            viewedDate: Date(),
            source: source,
            vibeAtTime: vibe
        )
        
        history.insert(entry, at: 0) // Add to beginning (most recent first)
        
        // Trim history if needed
        if history.count > maxHistoryEntries {
            history = Array(history.prefix(maxHistoryEntries))
        }
        
        await saveHistory(history)
        cache = history
        
        logInfo("Added poem to history: \(poem.title)", category: .repository)
    }
    
    func getHistory() async -> [PoemHistoryEntry] {
        if let cache = cache {
            return cache
        }
        
        let history = await loadHistory()
        cache = history
        return history
    }
    
    func getHistory(for date: Date) async -> [PoemHistoryEntry] {
        let history = await getHistory()
        let targetDay = Calendar.current.startOfDay(for: date)
        
        return history.filter { entry in
            Calendar.current.isDate(entry.viewedDate, inSameDayAs: targetDay)
        }
    }
    
    func getHistoryGroupedByDate() async -> [(date: Date, entries: [PoemHistoryEntry])] {
        let history = await getHistory()
        let calendar = Calendar.current
        
        var grouped: [Date: [PoemHistoryEntry]] = [:]
        
        for entry in history {
            let day = calendar.startOfDay(for: entry.viewedDate)
            grouped[day, default: []].append(entry)
        }
        
        return grouped
            .sorted { $0.key > $1.key } // Most recent first
            .map { (date: $0.key, entries: $0.value) }
    }
    
    func clearHistory() async {
        userDefaults.removeObject(forKey: StorageKeys.poemHistory)
        cache = nil
        logInfo("Cleared poem history", category: .repository)
    }
    
    func deleteEntry(_ entry: PoemHistoryEntry) async {
        var history = await getHistory()
        history.removeAll { $0.id == entry.id }
        await saveHistory(history)
        cache = history
    }
    
    func getEntryCount() async -> Int {
        return await getHistory().count
    }
    
    func getUniquePoems() async -> Int {
        let history = await getHistory()
        let uniquePoemIds = Set(history.map { $0.poem.id })
        return uniquePoemIds.count
    }
    
    func getStreakInfo() async -> StreakInfo {
        let history = await getHistory()
        guard !history.isEmpty else { return .empty }
        
        let calendar = Calendar.current
        
        // Get unique dates with poems
        let datesWithPoems = Set(history.map { calendar.startOfDay(for: $0.viewedDate) })
            .sorted(by: >)
        
        guard let mostRecentDate = datesWithPoems.first else { return .empty }
        
        // Calculate current streak
        var currentStreak = 0
        var checkDate = calendar.startOfDay(for: Date())
        
        // If most recent poem wasn't today or yesterday, streak is 0
        let daysSinceLast = calendar.dateComponents([.day], from: mostRecentDate, to: checkDate).day ?? 0
        if daysSinceLast > 1 {
            currentStreak = 0
        } else {
            // Count consecutive days
            for date in datesWithPoems {
                if calendar.isDate(date, inSameDayAs: checkDate) {
                    currentStreak += 1
                    checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate) ?? checkDate
                } else {
                    break
                }
            }
        }
        
        // Calculate longest streak
        var longestStreak = 0
        var tempStreak = 0
        var previousDate: Date?
        
        for date in datesWithPoems.reversed() {
            if let prev = previousDate {
                let daysBetween = calendar.dateComponents([.day], from: prev, to: date).day ?? 0
                if daysBetween == 1 {
                    tempStreak += 1
                } else {
                    longestStreak = max(longestStreak, tempStreak)
                    tempStreak = 1
                }
            } else {
                tempStreak = 1
            }
            previousDate = date
        }
        longestStreak = max(longestStreak, tempStreak)
        
        return StreakInfo(
            currentStreak: currentStreak,
            longestStreak: longestStreak,
            totalDaysWithPoems: datesWithPoems.count,
            lastViewedDate: mostRecentDate
        )
    }
    
    // MARK: - Private Methods
    
    private func loadHistory() async -> [PoemHistoryEntry] {
        guard let data = userDefaults.data(forKey: StorageKeys.poemHistory),
              let history = try? JSONDecoder().decode([PoemHistoryEntry].self, from: data) else {
            return []
        }
        return history
    }
    
    private func saveHistory(_ history: [PoemHistoryEntry]) async {
        guard let data = try? JSONEncoder().encode(history) else {
            logError("Failed to encode poem history", category: .error)
            return
        }
        userDefaults.set(data, forKey: StorageKeys.poemHistory)
    }
}

// MARK: - Mock Service for Testing

final class MockPoemHistoryService: PoemHistoryServiceProtocol, @unchecked Sendable {
    private var entries: [PoemHistoryEntry] = []
    
    func addEntry(_ poem: Poem, source: PoemSource, vibe: DailyVibe?) async {
        let entry = PoemHistoryEntry(poem: poem, source: source, vibeAtTime: vibe)
        entries.insert(entry, at: 0)
    }
    
    func getHistory() async -> [PoemHistoryEntry] {
        return entries
    }
    
    func getHistory(for date: Date) async -> [PoemHistoryEntry] {
        return entries.filter { Calendar.current.isDate($0.viewedDate, inSameDayAs: date) }
    }
    
    func getHistoryGroupedByDate() async -> [(date: Date, entries: [PoemHistoryEntry])] {
        return []
    }
    
    func clearHistory() async {
        entries.removeAll()
    }
    
    func deleteEntry(_ entry: PoemHistoryEntry) async {
        entries.removeAll { $0.id == entry.id }
    }
    
    func getEntryCount() async -> Int {
        return entries.count
    }
    
    func getUniquePoems() async -> Int {
        return Set(entries.map { $0.poem.id }).count
    }
    
    func getStreakInfo() async -> StreakInfo {
        return .empty
    }
}
