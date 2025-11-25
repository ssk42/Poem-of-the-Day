//
//  PoemHistoryViewModel.swift
//  Poem of the Day
//
//  Created by Claude Code on 2025-07-04.
//

import Foundation
import SwiftUI

/// Minimal class to make tests compile - following TDD Red phase
@MainActor
final class PoemHistoryViewModel: ObservableObject {
    @Published var historyEntries: [PoemHistoryEntry] = []
    @Published var groupedHistory: [(date: Date, entries: [PoemHistoryEntry])] = []
    @Published var streakInfo: StreakInfo?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var selectedDate: Date = Date()
    @Published var showErrorAlert = false
    @Published var showClearConfirmation = false
    
    private let repository: PoemRepositoryProtocol
    private let historyService: PoemHistoryServiceProtocol
    
    init(repository: PoemRepositoryProtocol = PoemRepository(), historyService: PoemHistoryServiceProtocol = PoemHistoryService()) {
        self.repository = repository
        self.historyService = historyService
    }
    
    // Minimal stub methods to make tests compile
    func loadPoemHistory() async {
        self.isLoading = true
        self.errorMessage = nil
        
        let entries = await repository.getHistory()
        self.historyEntries = entries
        self.isLoading = false
    }
    
    func loadHistory() async {
        isLoading = true
        errorMessage = nil
        
        async let entriesTask = historyService.getHistoryGroupedByDate()
        async let streakTask = historyService.getStreakInfo()
        
        let (entries, streak) = await (entriesTask, streakTask)
        
        self.groupedHistory = entries
        self.streakInfo = streak
        self.isLoading = false
    }
    
    func clearHistory() async {
        await historyService.clearHistory()
        groupedHistory = []
        streakInfo = .empty
    }
    
    func deleteEntry(_ entry: PoemHistoryEntry) async {
        await historyService.deleteEntry(entry)
        await loadHistory()
    }
    
    func getPoemForDate(_ date: Date) async -> Poem? {
        // Get all history entries and filter by date
        let entries = await repository.getHistory()
        let calendar = Calendar.current
        let matchingEntry = entries.first(where: { entry in
            calendar.isDate(entry.viewedDate, inSameDayAs: date)
        })
        return matchingEntry?.poem
    }
    
    func getPoemsForDateRange(start: Date, end: Date) async -> [PoemHistoryEntry] {
        // Get all history entries and filter by date range
        let entries = await repository.getHistory()
        return entries.filter { entry in
            entry.viewedDate >= start && entry.viewedDate <= end
        }
    }
    
    func toggleFavorite(for entry: PoemHistoryEntry) async {
        // Stub - will make tests fail
    }
    
    func isValidHistoryDate(_ date: Date) -> Bool {
        // Don't allow future dates
        return date <= Date()
    }
    
    func formatDateForDisplay(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
    func setLoadingState(_ isLoading: Bool) {
        self.isLoading = isLoading
    }
    
    func setError(_ message: String) {
        self.errorMessage = message
        self.showErrorAlert = true
    }
}