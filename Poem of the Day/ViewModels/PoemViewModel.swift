//
//  PoemViewModel.swift
//  Poem of the Day
//
//  Created by Claude Code on 2025-06-19.
//

import Foundation
import SwiftUI

@MainActor
final class PoemViewModel: ObservableObject {
    @Published var poemOfTheDay: Poem?
    @Published var favorites: [Poem] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showErrorAlert = false
    @Published var isAIGenerationAvailable = false
    @Published var currentVibe: VibeAnalysis?
    @Published var showVibeGeneration = false
    @Published var showCustomPrompt = false
    
    private let repository: PoemRepositoryProtocol
    private let telemetryService: TelemetryServiceProtocol
    
    init(repository: PoemRepositoryProtocol = PoemRepository(), telemetryService: TelemetryServiceProtocol = TelemetryService()) {
        self.repository = repository
        self.telemetryService = telemetryService
        
        Task {
            await loadInitialData()
        }
    }
    
    func loadInitialData() async {
        let isUITesting = AppConfiguration.Testing.isUITesting
        
        if isUITesting {
            isLoading = true
            isAIGenerationAvailable = AppConfiguration.Testing.isAIAvailable
            
            // Create mock vibe for testing
            
            // Create mock vibe for testing
            let mockVibe = DailyVibe.hopeful
            currentVibe = VibeAnalysis(
                vibe: mockVibe,
                confidence: 0.9,
                reasoning: "Mock reasoning for testing",
                keywords: ["hope", "test", "future"],
                sentiment: SentimentScore(positivity: 0.8, energy: 0.7, complexity: 0.5),
                backgroundColorIntensity: 0.8
            )
            
            // Create mock poem
            poemOfTheDay = Poem(
                id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
                title: "Test Poem",
                lines: ["This is a test poem", "For UI testing purposes"],
                author: "Test Author",
                vibe: mockVibe,
                source: .api
            )
            
            isLoading = false
            return
        }
        
        isLoading = true
        
        // Track app launch
        let appLaunchEvent = AppLaunchEvent(
            timestamp: Date(),
            launchType: .normal,
            coldStart: true,
            aiAvailable: false // Will be updated after AI check
        )
        await telemetryService.track(appLaunchEvent)
        
        async let _poem: Void = loadDailyPoem()
        async let _favorites: Void = loadFavorites()
        async let _ai: Void = checkAIAvailability()
        async let _vibe: Void = loadDailyVibe()
        
        // Await all tasks to complete
        _ = await (_poem, _favorites, _ai, _vibe)
        
        isLoading = false
    }
    
    func refreshPoem(showLoading: Bool = true) async {
        NSLog("PoemViewModel: refreshPoem called with showLoading=\(showLoading)")
        if showLoading {
            isLoading = true
        }
        errorMessage = nil // Clear previous error
        
        do {
            poemOfTheDay = try await repository.refreshDailyPoem()
        } catch {
            await handleError(error)
        }
        
        if showLoading {
            isLoading = false
        }
    }
    
    func loadFavorites() async {
        NSLog("PoemViewModel: loadFavorites called")
        self.favorites = await repository.getFavorites()
        NSLog("PoemViewModel: Favorites loaded. Count: \(self.favorites.count)")
    }
    
    func toggleFavorite(poem: Poem) async {
        NSLog("PoemViewModel: toggleFavorite called for poem: \(poem.title)")
        let isFavorite = await repository.isFavorite(poem)
        
        if isFavorite {
            NSLog("PoemViewModel: Poem is favorite. Removing.")
            await repository.removeFromFavorites(poem)
        } else {
            NSLog("PoemViewModel: Poem is NOT favorite. Adding.")
            await repository.addToFavorites(poem)
        }
        
        await loadFavorites()
    }
    
    
    func generateVibeBasedPoem() async {
        isLoading = true
        
        do {
            poemOfTheDay = try await repository.generateVibeBasedPoem()
        } catch {
            await handleError(error)
        }
        
        isLoading = false
    }
    
    func generateCustomPoem(prompt: String) async {
        isLoading = true
        
        do {
            poemOfTheDay = try await repository.generateCustomPoem(prompt: prompt)
        } catch {
            await handleError(error)
        }
        
        isLoading = false
    }
    
    func isFavorite(poem: Poem) -> Bool {
        favorites.contains { $0.id == poem.id }
    }
    
    func sharePoem(_ poem: Poem) async {
        let event = ShareEvent(
            timestamp: Date(),
            source: .mainApp,
            poemSource: poem.vibe != nil ? "ai_generated" : "api"
        )
        await telemetryService.track(event)
    }
    
    // MARK: - Private Methods
    
    private func loadDailyPoem() async {
        do {
            poemOfTheDay = try await repository.getDailyPoem()
        } catch {
            await handleError(error)
        }
    }
    

    
    private func checkAIAvailability() async {
        isAIGenerationAvailable = await repository.isAIGenerationAvailable()
    }
    
    private func loadDailyVibe() async {
        do {
            // Always try to load vibe analysis if AI is available
            if await repository.isAIGenerationAvailable() {
                currentVibe = try await repository.getVibeOfTheDay()
            }
        } catch {
            // Don't show error for vibe loading failure
            print("Failed to load daily vibe: \(error)")
        }
    }
    
    
    private func handleError(_ error: Error) async {
        if let poemError = error as? PoemError {
            errorMessage = poemError.localizedDescription
        } else if let generationError = error as? PoemGenerationError {
            errorMessage = generationError.localizedDescription
        } else {
            errorMessage = "An unexpected error occurred"
        }
        showErrorAlert = true
    }
}
