//
//  PoemGenerationService.swift
//  Poem of the Day
//
//  Created by Claude Code on 2025-06-19.
//

import Foundation

// Apple FoundationModels framework for iOS 26+
// Uses on-device large language model for text generation
#if canImport(FoundationModels)
import FoundationModels
#endif

// MARK: - Errors

enum PoemGenerationError: Error, LocalizedError {
    case modelUnavailable
    case generationFailed
    case invalidPrompt
    case deviceNotSupported
    case contentFiltered
    case quotaExceeded
    case networkRequired
    case systemResourcesUnavailable
    
    var errorDescription: String? {
        switch self {
        case .modelUnavailable:
            return "AI model is currently unavailable"
        case .generationFailed:
            return "Failed to generate poem"
        case .invalidPrompt:
            return "Invalid prompt provided"
        case .deviceNotSupported:
            return "Device does not support AI poem generation"
        case .contentFiltered:
            return "Content was filtered for safety"
        case .quotaExceeded:
            return "Daily generation limit exceeded"
        case .networkRequired:
            return "Network connection required for AI features"
        case .systemResourcesUnavailable:
            return "System resources unavailable"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .modelUnavailable:
            return "Please try again later"
        case .deviceNotSupported:
            return "AI poem generation requires iOS 18.1 or later with Neural Engine"
        case .quotaExceeded:
            return "You can generate more poems tomorrow"
        case .networkRequired:
            return "Connect to the internet to use AI features"
        default:
            return "Please try again"
        }
    }
}

// MARK: - Foundation Models Service

// FoundationModels implementation for iOS 26+
@available(iOS 26, *)
actor PoemGenerationService: PoemGenerationServiceProtocol {
    
    // MARK: - Properties
    
    private var dailyGenerationCount: Int = 0
    private let maxDailyGenerations = 10
    private let lastResetDate: Date
    private let userDefaults: UserDefaults
    
    // MARK: - Initialization
    
    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        self.lastResetDate = userDefaults.object(forKey: "lastGenerationReset") as? Date ?? Date()
        self.dailyGenerationCount = userDefaults.integer(forKey: "dailyGenerationCount")
        
        // Reset daily count if it's a new day
        if !Calendar.current.isDate(lastResetDate, inSameDayAs: Date()) {
            self.dailyGenerationCount = 0
            userDefaults.set(0, forKey: "dailyGenerationCount")
            userDefaults.set(Date(), forKey: "lastGenerationReset")
        }
    }
    
    // MARK: - Public Methods
    
    func generatePoemFromVibe(_ vibeAnalysis: VibeAnalysis) async throws -> Poem {
        do {
            try await checkAvailabilityAndQuota()
            
            let prompt = buildVibePrompt(from: vibeAnalysis)
            let poemContent = try await generateContent(prompt: prompt)
            let poem = try parseGeneratedPoem(poemContent, vibe: vibeAnalysis.vibe)
            
            await incrementDailyCount()
            return poem
        } catch PoemGenerationError.deviceNotSupported {
            // Fallback to local generation if AI is not supported
            return generateLocalPoem(vibe: vibeAnalysis.vibe)
        } catch {
            throw error
        }
    }
    
    func generatePoemWithCustomPrompt(_ prompt: String) async throws -> Poem {
        do {
            try await checkAvailabilityAndQuota()
            
            guard !prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                throw PoemGenerationError.invalidPrompt
            }
            
            let enhancedPrompt = enhanceCustomPrompt(prompt)
            let poemContent = try await generateContent(prompt: enhancedPrompt)
            let poem = try parseGeneratedPoem(poemContent, vibe: nil)
            
            await incrementDailyCount()
            return poem
        } catch PoemGenerationError.deviceNotSupported {
            // Fallback to local generation for custom prompts when AI is not supported
            return generateLocalPoem(prompt: prompt)
        } catch {
            throw error
        }
    }
    
    func isAvailable() async -> Bool {
        // Check FoundationModels availability for iOS 26+
        let deviceSupported = await checkDeviceSupport()
        let modelAvailable = await checkModelAvailability()
        return deviceSupported && modelAvailable
    }
    
    // MARK: - Private Methods
    
    private func checkAvailabilityAndQuota() async throws {
        guard await isAvailable() else {
            throw PoemGenerationError.deviceNotSupported
        }
        
        guard dailyGenerationCount < maxDailyGenerations else {
            throw PoemGenerationError.quotaExceeded
        }
    }
    
    private func checkDeviceSupport() async -> Bool {
        // Check for Neural Engine or similar AI capabilities
        // This would use actual FoundationModels API to check device support
        #if targetEnvironment(simulator)
        return false
        #else
        // In real implementation, this would check:
        // - Device has Neural Engine
        // - iOS version compatibility
        // - Available memory/storage
        return true
        #endif
    }
    
    private func checkModelAvailability() async -> Bool {
        // This would check if the foundation models are available and loaded
        // For now, we'll simulate this check
        return true
    }
    
    private func buildVibePrompt(from vibeAnalysis: VibeAnalysis) -> String {
        let basePrompt = vibeAnalysis.vibe.poemPrompt
        let context = buildContextFromAnalysis(vibeAnalysis)
        
        return """
        \(basePrompt)
        
        Context: Today's news suggests \(context).
        
        Please write a poem that captures this \(vibeAnalysis.vibe.displayName.lowercased()) feeling while being:
        - Original and creative
        - Appropriate for all audiences
        - 12-20 lines long
        - Emotionally resonant
        - Well-structured with clear rhythm
        
        Format the response as:
        Title: [Poem Title]
        Author: AI Poet
        
        [Poem content with line breaks]
        """
    }
    
    private func buildContextFromAnalysis(_ analysis: VibeAnalysis) -> String {
        let sentimentDesc = describeSentiment(analysis.sentiment)
        let keywords = analysis.keywords.prefix(3).joined(separator: ", ")
        
        return "a \(analysis.vibe.displayName.lowercased()) atmosphere with \(sentimentDesc). Key themes include: \(keywords)"
    }
    
    private func describeSentiment(_ sentiment: SentimentScore) -> String {
        switch (sentiment.positivity, sentiment.energy) {
        case (0.7..., 0.7...):
            return "high positivity and energy"
        case (0.7..., _):
            return "positive but calm energy"
        case (_, 0.7...):
            return "high energy with mixed emotions"
        case (...0.3, _):
            return "challenging but thoughtful themes"
        default:
            return "balanced emotional tones"
        }
    }
    
    private func enhanceCustomPrompt(_ prompt: String) -> String {
        return """
        Write a beautiful poem based on this request: "\(prompt)"
        
        Please ensure the poem is:
        - Original and creative
        - Appropriate for all audiences
        - 12-20 lines long
        - Well-structured with clear rhythm
        - Emotionally engaging
        
        Format the response as:
        Title: [Poem Title]
        Author: AI Poet
        
        [Poem content with line breaks]
        """
    }
    
    private func generateContent(prompt: String) async throws -> String {
        // This is where we would use the actual FoundationModels API
        // For iOS 26, this might look something like:
        /*
        import FoundationModels
        
        let model = try await FoundationModel.textGeneration()
        let request = TextGenerationRequest(
            prompt: prompt,
            maxTokens: 500,
            temperature: 0.8,
            topP: 0.9
        )
        
        let response = try await model.generate(request)
        return response.text
        */
        
        // For now, we'll simulate the API call with mock generation
        try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
        
        // Check for content filtering
        if containsInappropriateContent(prompt) {
            throw PoemGenerationError.contentFiltered
        }
        
        // Return a mock poem for demonstration
        return await generateMockPoem(based: prompt)
    }
    
    private func generateMockPoem(based prompt: String) async -> String {
        // This is a simple mock implementation
        // In reality, this would be handled by FoundationModels
        let mockPoems = [
            """
            Title: Morning's Promise
            Author: AI Poet
            
            In the quiet dawn, hope whispers soft,
            Through golden rays that lift hearts aloft,
            Each new day brings a chance to grow,
            To find the light that helps us glow.
            
            The world awakens with gentle grace,
            And peace settles in this sacred space,
            Where dreams and reality softly meet,
            And life's rhythm finds its beat.
            
            So let us cherish this moment here,
            Where love casts out all trace of fear,
            For in this dawn, we clearly see
            The beauty of what we're meant to be.
            """,
            
            """
            Title: Winds of Change
            Author: AI Poet
            
            The winds of change blow fierce and free,
            Across the landscape of our destiny,
            They carry stories from afar,
            Of those who've wished upon a star.
            
            Through trials faced and lessons learned,
            We find the bridges we have burned
            Were merely paths that led us here,
            To face tomorrow without fear.
            
            The storms may rage, the thunder roll,
            But deep within lives a peaceful soul,
            That knows beyond the clouded sky,
            The sun still shines for you and I.
            """,
            
            """
            Title: Quiet Reflections
            Author: AI Poet
            
            In moments of silence, wisdom speaks,
            To hearts that listen, souls that seek
            The deeper truths that life can show
            Through seasons of both joy and woe.
            
            The gentle rain upon the earth
            Reminds us of our sacred worth,
            Each drop a gift, each moment blessed
            With opportunities to rest.
            
            And in this stillness, we can find
            The peace that calms both heart and mind,
            Where gratitude and wonder meet
            To make our journey feel complete.
            """
        ]
        
        return mockPoems.randomElement() ?? mockPoems[0]
    }
    
    private func containsInappropriateContent(_ prompt: String) -> Bool {
        // Simple content filtering - in reality would be more sophisticated
        let inappropriateWords = ["violence", "hate", "harm", "explicit"]
        let lowercasePrompt = prompt.lowercased()
        return inappropriateWords.contains { lowercasePrompt.contains($0) }
    }
    
    private func parseGeneratedPoem(_ content: String, vibe: DailyVibe?) throws -> Poem {
        let lines = content.components(separatedBy: .newlines)
        
        var title = "Generated Poem"
        var author = "AI Poet"
        var poemLines: [String] = []
        
        var parsingPoem = false
        
        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
            
            if trimmedLine.hasPrefix("Title:") {
                title = String(trimmedLine.dropFirst(6)).trimmingCharacters(in: .whitespacesAndNewlines)
            } else if trimmedLine.hasPrefix("Author:") {
                author = String(trimmedLine.dropFirst(7)).trimmingCharacters(in: .whitespacesAndNewlines)
            } else if !trimmedLine.isEmpty && !trimmedLine.hasPrefix("Title:") && !trimmedLine.hasPrefix("Author:") {
                parsingPoem = true
            }
            
            if parsingPoem && !trimmedLine.isEmpty {
                poemLines.append(trimmedLine)
            }
        }
        
        if poemLines.isEmpty {
            throw PoemGenerationError.generationFailed
        }
        
        return Poem(
            title: title,
            lines: poemLines,
            author: author,
            vibe: vibe
        )
    }
    
    private func incrementDailyCount() async {
        dailyGenerationCount += 1
        userDefaults.set(dailyGenerationCount, forKey: "dailyGenerationCount")
    }
    
    private func generateLocalPoem(vibe: DailyVibe? = nil, prompt: String? = nil) -> Poem {
        let title = vibe?.displayName ?? "A Simple Poem"
        let author = "Local Poet"
        
        let lines = [
            "When AI sleeps, and models rest,",
            "A local verse is put to the test.",
            "No complex thoughts, no grand design,",
            "Just simple words, in a simple line.",
            "A poem born from code, not art,",
            "A humble offering, from the heart."
        ]
        
        return Poem(title: title, lines: lines, author: author, vibe: vibe)
    }
}