//
//  PoemRepository.swift
//  Poem of the Day
//
//  Created by Claude Code on 2025-06-19.
//  Updated with history tracking
//

import Foundation
import WidgetKit

protocol WidgetReloaderProtocol {
    func reloadAllTimelines()
}

class DefaultWidgetReloader: WidgetReloaderProtocol {
    func reloadAllTimelines() {
        WidgetCenter.shared.reloadAllTimelines()
    }
}

actor PoemRepository: PoemRepositoryProtocol {
    private let networkService: NetworkServiceProtocol
    private let newsService: NewsServiceProtocol
    private let vibeAnalyzer: VibeAnalyzerProtocol
    private let aiService: PoemGenerationServiceProtocol?
    private let telemetryService: TelemetryServiceProtocol
    private let historyService: PoemHistoryServiceProtocol
    private let userDefaults: UserDefaults
    private let widgetReloader: WidgetReloaderProtocol
    
    private var cachedFavorites: [Poem] = []
    private var favoritesLoaded = false
    
    init(networkService: NetworkServiceProtocol = NetworkService(),
         newsService: NewsServiceProtocol = NewsService(),
         vibeAnalyzer: VibeAnalyzerProtocol = VibeAnalyzer(),
         aiService: PoemGenerationServiceProtocol? = nil,
         telemetryService: TelemetryServiceProtocol = TelemetryService(),
         historyService: PoemHistoryServiceProtocol = PoemHistoryService(),
         userDefaults: UserDefaults = UserDefaults(suiteName: AppConfiguration.Storage.appGroupIdentifier) ?? .standard,
         widgetReloader: WidgetReloaderProtocol = DefaultWidgetReloader()) {
        self.networkService = networkService
        self.newsService = newsService
        self.vibeAnalyzer = vibeAnalyzer
        self.telemetryService = telemetryService
        self.historyService = historyService
        self.userDefaults = userDefaults
        self.widgetReloader = widgetReloader
        
        // Initialize AI service if available (iOS 18+)
        if #available(iOS 18, *) {
            self.aiService = aiService ?? PoemGenerationService()
        } else {
            self.aiService = nil
        }
        
        // Check for reset flag in UI tests
        if ProcessInfo.processInfo.arguments.contains("-ResetFavorites") {
            NSLog("PoemRepository: ResetFavorites flag detected. Clearing favorites.")
            self.userDefaults.removeObject(forKey: StorageKeys.favoritePoems)
            self.cachedFavorites = []
            self.favoritesLoaded = true
            NSLog("PoemRepository: Favorites cleared.")
        } else {
            NSLog("PoemRepository: ResetFavorites flag NOT detected.")
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
        let startTime = Date()
        var success = false
        var errorType: String?
        var vibeScore: Double?
        
        print("🎬 Starting vibe-based poem generation...")
        
        do {
            guard let aiService = aiService else {
                print("❌ AI service not available")
                throw PoemError.unsupportedOperation
            }
            
            print("✅ AI service available, checking availability...")
            let isAvailable = await aiService.isAvailable()
            print("   AI Available: \(isAvailable)")
            
            // Use cached vibe if available, otherwise refresh
            print("🔄 Getting vibe analysis...")
            let vibeAnalysis = try await getVibeOfTheDayInternal(forceRefresh: false)
            print("✅ Vibe analysis complete: \(vibeAnalysis.vibe.displayName)")
            print("   Sentiment: positivity=\(vibeAnalysis.sentiment.positivity), energy=\(vibeAnalysis.sentiment.energy)")
            print("   Keywords: \(vibeAnalysis.keywords.joined(separator: ", "))")
            
            vibeScore = vibeAnalysis.confidence
            
            print("🤖 Generating poem from AI service...")
            let poem = try await aiService.generatePoemFromVibe(vibeAnalysis)
            
            // Validate that we actually got content
            guard !poem.title.isEmpty, !poem.content.isEmpty else {
                print("❌ ERROR: Generated poem has empty title or content!")
                print("   Title: '\(poem.title)'")
                print("   Content length: \(poem.content.count)")
                throw PoemError.localGenerationFailed
            }
            
            // Check if we got a fallback poem
            if poem.source == .localFallback {
                print("⚠️ Received fallback poem instead of AI-generated content")
                logWarning("AI generation returned fallback poem", category: .ai)
            } else {
                print("✅ Poem generated successfully!")
            }
            
            print("📄 Generated Poem Details:")
            print("   Title: '\(poem.title)'")
            print("   Author: \(poem.author ?? "Unknown")")
            print("   Content length: \(poem.content.count) chars")
            print("   Lines count: \(poem.content.components(separatedBy: "\n").count)")
            print("   Vibe: \(poem.vibe?.displayName ?? "none")")
            print("   Source: \(poem.source?.rawValue ?? "unknown")")
            print("   First 150 chars: \(String(poem.content.prefix(150)))")
            
            success = true
            
            // Cache the poem as today's poem (so it becomes the daily poem)
            print("💾 Caching generated poem...")
            await cachePoemWithVibe(poem)
            print("✅ Poem cached successfully")
            
            // Track in history
            print("📚 Adding to history...")
            await historyService.addEntry(poem, source: .aiGenerated, vibe: vibeAnalysis.vibe)
            print("✅ Added to history")
            
            // Reload widgets to show new poem
            print("🔄 Reloading widgets...")
            widgetReloader.reloadAllTimelines()
            
            let event = AIGenerationEvent(
                timestamp: Date(),
                source: .mainApp,
                generationType: .vibeBasedPoem,
                duration: Date().timeIntervalSince(startTime),
                success: success,
                errorType: errorType,
                vibeScore: vibeScore
            )
            await telemetryService.track(event)
            
            print("✅ Vibe-based poem generation complete!")
            return poem
        } catch {
            errorType = (error as? PoemError)?.localizedDescription ?? error.localizedDescription
            print("❌ Error generating vibe-based poem: \(error)")
            print("   Error type: \(errorType ?? "Unknown")")
            print("   Error details: \(String(describing: error))")
            
            let event = AIGenerationEvent(
                timestamp: Date(),
                source: .mainApp,
                generationType: .vibeBasedPoem,
                duration: Date().timeIntervalSince(startTime),
                success: success,
                errorType: errorType,
                vibeScore: vibeScore
            )
            await telemetryService.track(event)
            
            throw error
        }
    }
    
    func generateCustomPoem(prompt: String) async throws -> Poem {
        guard let aiService = aiService else {
            throw PoemError.unsupportedOperation
        }
        
        let poem = try await aiService.generatePoemWithCustomPrompt(prompt)
        
        // Track in history
        await historyService.addEntry(poem, source: .customPrompt, vibe: nil)
        
        return poem
    }
    
    func getVibeOfTheDay() async throws -> VibeAnalysis {
        return try await getVibeOfTheDayInternal(forceRefresh: false)
    }
    
    private func getVibeOfTheDayInternal(forceRefresh: Bool) async throws -> VibeAnalysis {
        // Check if we have a cached vibe analysis for today (unless forcing refresh)
        if !forceRefresh, let cachedVibe = loadCachedVibeAnalysis() {
            print("📦 Using cached vibe: \(cachedVibe.vibe.displayName)")
            return cachedVibe
        }
        
        print("🔄 Fetching fresh news and analyzing vibe...")
        // Fetch fresh news and analyze vibe
        let articles = try await newsService.fetchDailyNews()
        print("📰 Fetched \(articles.count) news articles")
        
        let vibeAnalysis = await vibeAnalyzer.analyzeVibe(from: articles)
        print("✅ Analyzed vibe: \(vibeAnalysis.vibe.displayName) (confidence: \(vibeAnalysis.confidence))")
        
        // Cache the analysis
        await cacheVibeAnalysis(vibeAnalysis)
        
        return vibeAnalysis
    }
    
    func isAIGenerationAvailable() async -> Bool {
        // Check for UI Testing mode - check standard user defaults as launch arguments populate there
        if UserDefaults.standard.bool(forKey: "UITESTING") || ProcessInfo.processInfo.environment["UITESTING"] == "1" {
            return true
        }
        
        guard let aiService = aiService else { return false }
        return await aiService.isAvailable()
    }
    
    // MARK: - Favorites
    
    func getFavorites() async -> [Poem] {
        if !favoritesLoaded {
            await loadFavorites()
        }
        return cachedFavorites
    }
    
    func addToFavorites(_ poem: Poem) async {
        NSLog("PoemRepository: addToFavorites called for poem: \(poem.title) (ID: \(poem.id))")
        if !favoritesLoaded {
            await loadFavorites()
        }
        
        guard !cachedFavorites.contains(where: { $0.id == poem.id }) else {
            NSLog("PoemRepository: Poem already in favorites. Skipping add.")
            return
        }
        
        // Enforce max favorites limit
        if cachedFavorites.count >= AppConfiguration.Storage.maxFavoritePoems {
            // Remove oldest favorite
            cachedFavorites.removeFirst()
        }
        
        cachedFavorites.append(poem)
        await saveFavorites()
        
        let event = FavoriteActionEvent(
            timestamp: Date(),
            source: .mainApp,
            action: .add,
            poemSource: poem.vibe != nil ? "ai_generated" : "api"
        )
        await telemetryService.track(event)
    }
    
    func removeFromFavorites(_ poem: Poem) async {
        if !favoritesLoaded {
            await loadFavorites()
        }
        
        cachedFavorites.removeAll { $0.id == poem.id }
        await saveFavorites()
        
        let event = FavoriteActionEvent(
            timestamp: Date(),
            source: .mainApp,
            action: .remove,
            poemSource: poem.vibe != nil ? "ai_generated" : "api"
        )
        await telemetryService.track(event)
    }
    
    func isFavorite(_ poem: Poem) async -> Bool {
        if !favoritesLoaded {
            await loadFavorites()
        }
        return cachedFavorites.contains { $0.id == poem.id }
    }
    
    // MARK: - History Access
    
    func getHistory() async -> [PoemHistoryEntry] {
        return await historyService.getHistory()
    }
    
    func getHistoryGroupedByDate() async -> [(date: Date, entries: [PoemHistoryEntry])] {
        return await historyService.getHistoryGroupedByDate()
    }
    
    func getStreakInfo() async -> StreakInfo {
        return await historyService.getStreakInfo()
    }
    
    // MARK: - Private Methods
    
    private func shouldFetchNewPoem() -> Bool {
        guard let lastFetchDate = userDefaults.object(forKey: StorageKeys.lastPoemFetchDate) as? Date else {
            return true
        }
        
        return !Calendar.current.isDate(lastFetchDate, inSameDayAs: Date())
    }
    
    private func fetchAndCacheDailyPoem() async throws -> Poem {
        var currentVibe: DailyVibe? = nil
        
        // Try to get current vibe for history tracking
        if let cachedVibeAnalysis = loadCachedVibeAnalysis() {
            currentVibe = cachedVibeAnalysis.vibe
        }
        
        // Check user preference for poem source (default to "api" / PoetryDB)
        let preferredSource = userDefaults.string(forKey: StorageKeys.preferredPoemSource) ?? "api"
        
        // Only use AI if explicitly preferred AND available
        var useAI = false
        if preferredSource == "ai" {
            useAI = await isAIGenerationAvailable()
        }
        
        if useAI {
            do {
                let vibePoem = try await generateVibeBasedPoem()
                await cachePoemWithVibe(vibePoem)
                widgetReloader.reloadAllTimelines()
                return vibePoem
            } catch {
                // Fall back to API poem if AI generation fails
                logWarning("AI poem generation failed, falling back to API: \(error)", category: .ai)
            }
        }
        
        // Use traditional API poem as fallback
        let startTime = Date()
        var success = false
        var errorType: String?
        
        do {
            let poem: Poem
            // Add timeout for network request (20 seconds)
            poem = try await withThrowingTaskGroup(of: Poem.self) { group in
                group.addTask {
                    return try await self.networkService.fetchRandomPoem()
                }
                group.addTask {
                    // 10 second timeout for poem fetch (matches test expectations)
                    try await Task.sleep(nanoseconds: 10 * 1_000_000_000)
                    throw PoemError.networkUnavailable
                }
                let result = try await group.next()!
                group.cancelAll()
                return result
            }
            
            await cachePoem(poem)
            
            // Track in history
            await historyService.addEntry(poem, source: .api, vibe: currentVibe)
            
            widgetReloader.reloadAllTimelines()
            success = true
            
            let event = PoemFetchEvent(
                timestamp: Date(),
                source: .mainApp,
                poemSource: "api",
                duration: Date().timeIntervalSince(startTime),
                success: success,
                errorType: errorType,
                vibeType: currentVibe?.rawValue
            )
            await telemetryService.track(event)
            
            return poem
        } catch {
            errorType = (error as? PoemError)?.localizedDescription ?? error.localizedDescription
            
            let event = PoemFetchEvent(
                timestamp: Date(),
                source: .mainApp,
                poemSource: "api",
                duration: Date().timeIntervalSince(startTime),
                success: success,
                errorType: errorType,
                vibeType: currentVibe?.rawValue
            )
            await telemetryService.track(event)
            
            throw error
        }
    }
    
    private func cachePoem(_ poem: Poem) async {
        userDefaults.set(poem.title, forKey: StorageKeys.poemTitle)
        userDefaults.set(poem.content, forKey: StorageKeys.poemContent)
        userDefaults.set(poem.author ?? "", forKey: StorageKeys.poemAuthor)
        userDefaults.set("api", forKey: StorageKeys.poemSource)
        userDefaults.removeObject(forKey: StorageKeys.poemVibe) // Clear vibe for API poems
        userDefaults.set(Date(), forKey: StorageKeys.lastPoemFetchDate)
    }
    
    private func cachePoemWithVibe(_ poem: Poem) async {
        userDefaults.set(poem.title, forKey: StorageKeys.poemTitle)
        userDefaults.set(poem.content, forKey: StorageKeys.poemContent)
        userDefaults.set(poem.author ?? "", forKey: StorageKeys.poemAuthor)
        userDefaults.set("ai_generated", forKey: StorageKeys.poemSource)
        
        // Cache the vibe information if available
        if let vibe = poem.vibe {
            userDefaults.set(vibe.rawValue, forKey: StorageKeys.poemVibe)
        }
        
        userDefaults.set(Date(), forKey: StorageKeys.lastPoemFetchDate)
    }
    
    private func loadCachedVibeAnalysis() -> VibeAnalysis? {
        guard let lastVibeDate = userDefaults.object(forKey: StorageKeys.lastVibeAnalysisDate) as? Date,
              Calendar.current.isDate(lastVibeDate, inSameDayAs: Date()),
              let vibeData = userDefaults.data(forKey: StorageKeys.cachedVibeAnalysis),
              let vibeAnalysis = try? JSONDecoder().decode(VibeAnalysis.self, from: vibeData) else {
            return nil
        }
        
        return vibeAnalysis
    }
    
    private func cacheVibeAnalysis(_ analysis: VibeAnalysis) async {
        guard let data = try? JSONEncoder().encode(analysis) else { return }
        userDefaults.set(data, forKey: StorageKeys.cachedVibeAnalysis)
        userDefaults.set(Date(), forKey: StorageKeys.lastVibeAnalysisDate)
    }
    
    private func loadCachedPoem() -> Poem? {
        guard let title = userDefaults.string(forKey: StorageKeys.poemTitle),
              let content = userDefaults.string(forKey: StorageKeys.poemContent) else {
            return nil
        }
        
        let author = userDefaults.string(forKey: StorageKeys.poemAuthor)
        let vibeRawValue = userDefaults.string(forKey: StorageKeys.poemVibe)
        let vibe = vibeRawValue.flatMap { DailyVibe(rawValue: $0) }
        
        return Poem(
            title: title, 
            lines: content.components(separatedBy: "\n"), 
            author: author?.isEmpty == true ? nil : author,
            vibe: vibe
        )
    }
    
    private func loadFavorites() async {
        NSLog("PoemRepository: loadFavorites called")
        guard let data = userDefaults.data(forKey: StorageKeys.favoritePoems),
              let favorites = try? JSONDecoder().decode([Poem].self, from: data) else {
            NSLog("PoemRepository: No favorites found in UserDefaults or decode failed")
            cachedFavorites = []
            favoritesLoaded = true
            return
        }
        
        NSLog("PoemRepository: Loaded \(favorites.count) favorites from UserDefaults")
        cachedFavorites = favorites
        favoritesLoaded = true
    }
    
    private func saveFavorites() async {
        NSLog("PoemRepository: saveFavorites called with \(cachedFavorites.count) favorites")
        guard let data = try? JSONEncoder().encode(cachedFavorites) else {
            NSLog("PoemRepository: Failed to encode favorites")
            return
        }
        userDefaults.set(data, forKey: StorageKeys.favoritePoems)
        userDefaults.synchronize() // Force save
        NSLog("PoemRepository: Favorites saved to UserDefaults")
    }
}
