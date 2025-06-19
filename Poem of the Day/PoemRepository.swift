//
//  PoemRepository.swift
//  Poem of the Day
//
//  Created by Claude Code on 2025-06-19.
//

import Foundation
import WidgetKit

protocol PoemRepositoryProtocol: Sendable {
    func getDailyPoem() async throws -> Poem
    func refreshDailyPoem() async throws -> Poem
    func generateVibeBasedPoem() async throws -> Poem
    func generateCustomPoem(prompt: String) async throws -> Poem
    func getVibeOfTheDay() async throws -> VibeAnalysis
    func isAIGenerationAvailable() async -> Bool
    func getFavorites() async -> [Poem]
    func addToFavorites(_ poem: Poem) async
    func removeFromFavorites(_ poem: Poem) async
    func isFavorite(_ poem: Poem) async -> Bool
}

actor PoemRepository: PoemRepositoryProtocol {
    private let networkService: NetworkServiceProtocol
    private let newsService: NewsServiceProtocol
    private let vibeAnalyzer: VibeAnalyzerProtocol
    private let aiService: PoemGenerationServiceProtocol?
    private let userDefaults: UserDefaults
    
    private var cachedFavorites: [Poem] = []
    private var favoritesLoaded = false
    
    init(networkService: NetworkServiceProtocol = NetworkService(),
         newsService: NewsServiceProtocol = NewsService(),
         vibeAnalyzer: VibeAnalyzerProtocol = VibeAnalyzer(),
         aiService: PoemGenerationServiceProtocol? = nil,
         userDefaults: UserDefaults = UserDefaults(suiteName: "group.com.stevereitz.poemoftheday") ?? .standard) {
        self.networkService = networkService
        self.newsService = newsService
        self.vibeAnalyzer = vibeAnalyzer
        self.userDefaults = userDefaults
        
        // Initialize AI service if available (iOS 18.1+)
        if #available(iOS 18.1, *) {
            self.aiService = aiService ?? PoemGenerationService()
        } else {
            self.aiService = nil
        }
    }
    
    func getDailyPoem() async throws -> Poem {
        if shouldFetchNewPoem() {
            return try await fetchAndCachePoem()
        } else if let cachedPoem = loadCachedPoem() {
            return cachedPoem
        } else {
            return try await fetchAndCachePoem()
        }
    }
    
    func refreshDailyPoem() async throws -> Poem {
        return try await fetchAndCachePoem()
    }
    
    func generateVibeBasedPoem() async throws -> Poem {
        guard let aiService = aiService else {
            throw PoemError.unsupportedOperation
        }
        
        let vibeAnalysis = try await getVibeOfTheDay()
        return try await aiService.generatePoemFromVibe(vibeAnalysis)
    }
    
    func generateCustomPoem(prompt: String) async throws -> Poem {
        guard let aiService = aiService else {
            throw PoemError.unsupportedOperation
        }
        
        return try await aiService.generatePoemWithCustomPrompt(prompt)
    }
    
    func getVibeOfTheDay() async throws -> VibeAnalysis {
        // Check if we have a cached vibe analysis for today
        if let cachedVibe = loadCachedVibeAnalysis() {
            return cachedVibe
        }
        
        // Fetch fresh news and analyze vibe
        let articles = try await newsService.fetchDailyNews()
        let vibeAnalysis = await vibeAnalyzer.analyzeVibe(from: articles)
        
        // Cache the analysis
        await cacheVibeAnalysis(vibeAnalysis)
        
        return vibeAnalysis
    }
    
    func isAIGenerationAvailable() async -> Bool {
        guard let aiService = aiService else { return false }
        return await aiService.isAvailable()
    }
    
    
    func getFavorites() async -> [Poem] {
        if !favoritesLoaded {
            await loadFavorites()
        }
        return cachedFavorites
    }
    
    func addToFavorites(_ poem: Poem) async {
        if !favoritesLoaded {
            await loadFavorites()
        }
        
        guard !cachedFavorites.contains(where: { $0.id == poem.id }) else { return }
        
        cachedFavorites.append(poem)
        await saveFavorites()
    }
    
    func removeFromFavorites(_ poem: Poem) async {
        if !favoritesLoaded {
            await loadFavorites()
        }
        
        cachedFavorites.removeAll { $0.id == poem.id }
        await saveFavorites()
    }
    
    func isFavorite(_ poem: Poem) async -> Bool {
        if !favoritesLoaded {
            await loadFavorites()
        }
        return cachedFavorites.contains { $0.id == poem.id }
    }
    
    // MARK: - Private Methods
    
    private func shouldFetchNewPoem() -> Bool {
        guard let lastFetchDate = userDefaults.object(forKey: "lastPoemFetchDate") as? Date else {
            return true
        }
        
        return !Calendar.current.isDate(lastFetchDate, inSameDayAs: Date())
    }
    
    private func fetchAndCachePoem() async throws -> Poem {
        let poem = try await networkService.fetchRandomPoem()
        await cachePoem(poem)
        WidgetCenter.shared.reloadAllTimelines()
        return poem
    }
    
    private func cachePoem(_ poem: Poem) async {
        userDefaults.set(poem.title, forKey: "poemTitle")
        userDefaults.set(poem.content, forKey: "poemContent")
        userDefaults.set(poem.author ?? "", forKey: "poemAuthor")
        userDefaults.set(Date(), forKey: "lastPoemFetchDate")
    }
    
    private func loadCachedVibeAnalysis() -> VibeAnalysis? {
        guard let lastVibeDate = userDefaults.object(forKey: "lastVibeAnalysisDate") as? Date,
              Calendar.current.isDate(lastVibeDate, inSameDayAs: Date()),
              let vibeData = userDefaults.data(forKey: "cachedVibeAnalysis"),
              let vibeAnalysis = try? JSONDecoder().decode(VibeAnalysis.self, from: vibeData) else {
            return nil
        }
        
        return vibeAnalysis
    }
    
    private func cacheVibeAnalysis(_ analysis: VibeAnalysis) async {
        guard let data = try? JSONEncoder().encode(analysis) else { return }
        userDefaults.set(data, forKey: "cachedVibeAnalysis")
        userDefaults.set(Date(), forKey: "lastVibeAnalysisDate")
    }
    
    private func loadCachedPoem() -> Poem? {
        guard let title = userDefaults.string(forKey: "poemTitle"),
              let content = userDefaults.string(forKey: "poemContent") else {
            return nil
        }
        
        let author = userDefaults.string(forKey: "poemAuthor")
        return Poem(
            title: title, 
            lines: content.components(separatedBy: "\n"), 
            author: author?.isEmpty == true ? nil : author
        )
    }
    
    private func loadFavorites() async {
        guard let data = userDefaults.data(forKey: "favoritePoems"),
              let favorites = try? JSONDecoder().decode([Poem].self, from: data) else {
            cachedFavorites = []
            favoritesLoaded = true
            return
        }
        
        cachedFavorites = favorites
        favoritesLoaded = true
    }
    
    private func saveFavorites() async {
        guard let data = try? JSONEncoder().encode(cachedFavorites) else { return }
        userDefaults.set(data, forKey: "favoritePoems")
    }
}