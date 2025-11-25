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
        if AppConfiguration.Testing.isUITesting {
            isLoading = true
            isAIGenerationAvailable = AppConfiguration.Testing.isAIAvailable
            
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
        
        async let poemTask = loadDailyPoem()
        async let favoritesTask = loadFavorites()
        async let aiAvailabilityTask = checkAIAvailability()
        async let vibeTask = loadDailyVibe()
        
        await poemTask
        await favoritesTask
        await aiAvailabilityTask
        await vibeTask
        
        isLoading = false
    }
    
    func refreshPoem() async {
        isLoading = true
        
        do {
            poemOfTheDay = try await repository.refreshDailyPoem()
        } catch {
            await handleError(error)
        }
        
        isLoading = false
    }
    
    func toggleFavorite(poem: Poem) async {
        let isFavorite = await repository.isFavorite(poem)
        
        if isFavorite {
            await repository.removeFromFavorites(poem)
        } else {
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
    
    private func loadFavorites() async {
        favorites = await repository.getFavorites()
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