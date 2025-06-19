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
    func generateAIPoem(theme: PoemTheme?) async throws -> Poem
    func getFavorites() async -> [Poem]
    func addToFavorites(_ poem: Poem) async
    func removeFromFavorites(_ poem: Poem) async
    func isFavorite(_ poem: Poem) async -> Bool
    func isAIGenerationAvailable() async -> Bool
}

actor PoemRepository: PoemRepositoryProtocol {
    private let networkService: NetworkServiceProtocol
    private let aiService: PoemGenerationServiceProtocol
    private let userDefaults: UserDefaults
    
    private var cachedFavorites: [Poem] = []
    private var favoritesLoaded = false
    
    init(networkService: NetworkServiceProtocol = NetworkService(), 
         aiService: PoemGenerationServiceProtocol = PoemGenerationService(),
         userDefaults: UserDefaults = UserDefaults(suiteName: "group.com.stevereitz.poemoftheday") ?? .standard) {
        self.networkService = networkService
        self.aiService = aiService
        self.userDefaults = userDefaults
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
    
    func generateAIPoem(theme: PoemTheme?) async throws -> Poem {
        if let theme = theme {
            return try await aiService.generatePoem(theme: theme)
        } else {
            return try await aiService.generateRandomPoem()
        }
    }
    
    func isAIGenerationAvailable() async -> Bool {
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
        userDefaults.set(poem.source.rawValue, forKey: "poemSource")
        userDefaults.set(Date(), forKey: "lastPoemFetchDate")
    }
    
    private func loadCachedPoem() -> Poem? {
        guard let title = userDefaults.string(forKey: "poemTitle"),
              let content = userDefaults.string(forKey: "poemContent") else {
            return nil
        }
        
        let author = userDefaults.string(forKey: "poemAuthor")
        let sourceRaw = userDefaults.string(forKey: "poemSource") ?? "api"
        let source = PoemSource(rawValue: sourceRaw) ?? .api
        
        return Poem(
            title: title, 
            lines: content.components(separatedBy: "\n"), 
            author: author?.isEmpty == true ? nil : author,
            source: source
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