//
//  PoemRepository.swift
//  Poem of the Day
//
//  Created by Claude Code on 2025-06-19.
//

import Foundation
import WidgetKit

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
            return try await fetchAndCacheDailyPoem()
        } else if let cachedPoem = loadCachedPoem() {
            return cachedPoem
        } else {
            return try await fetchAndCacheDailyPoem()
        }
    }
    
    func refreshDailyPoem() async throws -> Poem {
        return try await fetchAndCacheDailyPoem()
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
    
    private func fetchAndCacheDailyPoem() async throws -> Poem {
        // Try to generate vibe-based poem first if AI is available
        if await isAIGenerationAvailable() {
            do {
                let vibePoem = try await generateVibeBasedPoem()
                await cachePoemWithVibe(vibePoem)
                WidgetCenter.shared.reloadAllTimelines()
                return vibePoem
            } catch {
                // Fall back to API poem if AI generation fails
                print("AI poem generation failed, falling back to API: \(error)")
            }
        }
        
        // Use traditional API poem as fallback
        let poem = try await networkService.fetchRandomPoem()
        await cachePoem(poem)
        WidgetCenter.shared.reloadAllTimelines()
        return poem
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
        userDefaults.set("api", forKey: "poemSource")
        userDefaults.removeObject(forKey: "poemVibe") // Clear vibe for API poems
        userDefaults.set(Date(), forKey: "lastPoemFetchDate")
    }
    
    private func cachePoemWithVibe(_ poem: Poem) async {
        userDefaults.set(poem.title, forKey: "poemTitle")
        userDefaults.set(poem.content, forKey: "poemContent")
        userDefaults.set(poem.author ?? "", forKey: "poemAuthor")
        userDefaults.set("ai_generated", forKey: "poemSource")
        
        // Cache the vibe information if available
        if let vibe = poem.vibe {
            userDefaults.set(vibe.rawValue, forKey: "poemVibe")
        }
        
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
        let vibeRawValue = userDefaults.string(forKey: "poemVibe")
        let vibe = vibeRawValue.flatMap { DailyVibe(rawValue: $0) }
        
        return Poem(
            title: title, 
            lines: content.components(separatedBy: "\n"), 
            author: author?.isEmpty == true ? nil : author,
            vibe: vibe
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