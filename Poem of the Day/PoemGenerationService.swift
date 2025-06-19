//
//  PoemGenerationService.swift
//  Poem of the Day
//
//  Created by Claude Code on 2025-06-19.
//

import Foundation
import FoundationModels

// Custom error types for AI poem generation
enum PoemGenerationError: LocalizedError, Equatable {
    case modelUnavailable
    case generationFailed
    case invalidPrompt
    case deviceNotSupported
    case contentFiltered
    case quotaExceeded
    
    var errorDescription: String? {
        switch self {
        case .modelUnavailable:
            return "AI model is not available on this device."
        case .generationFailed:
            return "Failed to generate poem. Please try again."
        case .invalidPrompt:
            return "Invalid poem request. Please try a different theme."
        case .deviceNotSupported:
            return "This device doesn't support AI poem generation."
        case .contentFiltered:
            return "Generated content was filtered. Please try a different theme."
        case .quotaExceeded:
            return "Daily AI generation limit reached. Please try again tomorrow."
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .modelUnavailable, .deviceNotSupported:
            return "AI poems are available on iOS 18.1+ devices with Neural Engine."
        case .generationFailed:
            return "Check your internet connection and try again."
        case .invalidPrompt, .contentFiltered:
            return "Try requesting a poem about nature, love, or friendship."
        case .quotaExceeded:
            return "You can still enjoy poems from our curated collection."
        }
    }
}

// Poem themes for AI generation
enum PoemTheme: String, CaseIterable {
    case nature = "nature"
    case love = "love"
    case friendship = "friendship"
    case hope = "hope"
    case seasons = "seasons"
    case dreams = "dreams"
    case journey = "journey"
    case peace = "peace"
    case wonder = "wonder"
    case gratitude = "gratitude"
    
    var displayName: String {
        switch self {
        case .nature: return "Nature"
        case .love: return "Love"
        case .friendship: return "Friendship"
        case .hope: return "Hope"
        case .seasons: return "Seasons"
        case .dreams: return "Dreams"
        case .journey: return "Journey"
        case .peace: return "Peace"
        case .wonder: return "Wonder"
        case .gratitude: return "Gratitude"
        }
    }
    
    var prompt: String {
        switch self {
        case .nature:
            return "Write a beautiful poem about nature, focusing on landscapes, animals, or natural phenomena. Make it contemplative and inspiring."
        case .love:
            return "Create a heartfelt poem about love - it could be romantic love, family love, or love for life itself. Make it warm and touching."
        case .friendship:
            return "Compose a poem celebrating friendship, loyalty, and the bonds between people. Make it uplifting and meaningful."
        case .hope:
            return "Write an inspiring poem about hope, resilience, and looking forward to better times. Make it encouraging and optimistic."
        case .seasons:
            return "Create a poem about the changing seasons, their beauty, and what they represent. Make it vivid and reflective."
        case .dreams:
            return "Write a poem about dreams, aspirations, and the power of imagination. Make it inspiring and whimsical."
        case .journey:
            return "Compose a poem about life's journey, adventures, and personal growth. Make it thoughtful and motivating."
        case .peace:
            return "Create a calming poem about peace, tranquility, and finding serenity in life. Make it soothing and meditative."
        case .wonder:
            return "Write a poem about wonder, curiosity, and the magic found in everyday moments. Make it enchanting and thoughtful."
        case .gratitude:
            return "Compose a poem expressing gratitude for life's blessings, big and small. Make it heartfelt and appreciative."
        }
    }
}

// Protocol for AI poem generation
protocol PoemGenerationServiceProtocol: Sendable {
    func isAvailable() async -> Bool
    func generatePoem(theme: PoemTheme) async throws -> Poem
    func generateRandomPoem() async throws -> Poem
}

// AI-powered poem generation service using FoundationModels
actor PoemGenerationService: PoemGenerationServiceProtocol {
    private var dailyGenerationCount: Int = 0
    private var lastResetDate: Date = Date()
    private let maxDailyGenerations = 10 // Reasonable limit for on-device AI
    
    init() {
        resetDailyCountIfNeeded()
    }
    
    func isAvailable() async -> Bool {
        // Check if FoundationModels is available on this device
        if #available(iOS 18.1, *) {
            return await LanguageModelSession.isAvailable
        } else {
            return false
        }
    }
    
    func generatePoem(theme: PoemTheme) async throws -> Poem {
        guard await isAvailable() else {
            throw PoemGenerationError.deviceNotSupported
        }
        
        resetDailyCountIfNeeded()
        
        guard dailyGenerationCount < maxDailyGenerations else {
            throw PoemGenerationError.quotaExceeded
        }
        
        guard #available(iOS 18.1, *) else {
            throw PoemGenerationError.deviceNotSupported
        }
        
        do {
            let session = try await LanguageModelSession()
            
            let fullPrompt = """
            \(theme.prompt)
            
            Format the poem with:
            - A creative, meaningful title
            - 3-4 stanzas of 4 lines each
            - Beautiful, accessible language
            - No explicit content
            - Family-friendly themes
            
            Please respond in this exact format:
            Title: [poem title]
            
            [stanza 1 line 1]
            [stanza 1 line 2]
            [stanza 1 line 3]
            [stanza 1 line 4]
            
            [stanza 2 line 1]
            [stanza 2 line 2]
            [stanza 2 line 3]
            [stanza 2 line 4]
            
            [continue with remaining stanzas...]
            """
            
            let response = try await session.generate(prompt: fullPrompt)
            
            dailyGenerationCount += 1
            
            return try parseGeneratedPoem(response)
            
        } catch {
            if error is PoemGenerationError {
                throw error
            } else {
                throw PoemGenerationError.generationFailed
            }
        }
    }
    
    func generateRandomPoem() async throws -> Poem {
        let randomTheme = PoemTheme.allCases.randomElement() ?? .nature
        return try await generatePoem(theme: randomTheme)
    }
    
    // MARK: - Private Methods
    
    private func resetDailyCountIfNeeded() {
        let calendar = Calendar.current
        if !calendar.isDate(lastResetDate, inSameDayAs: Date()) {
            dailyGenerationCount = 0
            lastResetDate = Date()
        }
    }
    
    private func parseGeneratedPoem(_ text: String) throws -> Poem {
        let lines = text.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        
        guard !lines.isEmpty else {
            throw PoemGenerationError.generationFailed
        }
        
        // Extract title
        var title = "Untitled Poem"
        var poemLines: [String] = []
        
        for line in lines {
            if line.lowercased().hasPrefix("title:") {
                title = String(line.dropFirst(6)).trimmingCharacters(in: .whitespaces)
            } else if !line.lowercased().contains("title:") {
                poemLines.append(line)
            }
        }
        
        // Ensure we have some content
        guard !poemLines.isEmpty else {
            throw PoemGenerationError.generationFailed
        }
        
        // Basic content filtering
        let content = poemLines.joined(separator: "\n")
        if containsInappropriateContent(content) {
            throw PoemGenerationError.contentFiltered
        }
        
        return Poem(
            title: title,
            lines: poemLines,
            author: "AI Generated"
        )
    }
    
    private func containsInappropriateContent(_ text: String) -> Bool {
        let inappropriateTerms = ["violence", "hate", "explicit", "inappropriate"]
        let lowercaseText = text.lowercased()
        
        return inappropriateTerms.contains { term in
            lowercaseText.contains(term)
        }
    }
}

// Mock implementation for testing and fallback
final class MockPoemGenerationService: PoemGenerationServiceProtocol {
    var mockAvailable: Bool = true
    var mockError: Error?
    
    func isAvailable() async -> Bool {
        return mockAvailable
    }
    
    func generatePoem(theme: PoemTheme) async throws -> Poem {
        if let error = mockError {
            throw error
        }
        
        return Poem(
            title: "Mock \(theme.displayName) Poem",
            lines: [
                "This is a mock poem about \(theme.rawValue)",
                "Generated for testing purposes",
                "With beautiful imagery and rhyme",
                "Created in development time"
            ],
            author: "Mock AI"
        )
    }
    
    func generateRandomPoem() async throws -> Poem {
        let randomTheme = PoemTheme.allCases.randomElement() ?? .nature
        return try await generatePoem(theme: randomTheme)
    }
}