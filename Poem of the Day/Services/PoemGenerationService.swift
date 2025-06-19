//
//  PoemGenerationService.swift
//  Poem of the Day
//
//  Created by Claude Code on 2025-06-19.
//

import Foundation

// Only import FoundationModels if running on iOS 26+
@available(iOS 26, *)
import FoundationModels

// MARK: - Protocols

protocol PoemGenerationServiceProtocol: Sendable {
    func generatePoemFromVibe(_ vibeAnalysis: VibeAnalysis) async throws -> Poem
    func generatePoemWithCustomPrompt(_ prompt: String) async throws -> Poem
    func isAvailable() async -> Bool
}

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

// Only define the FoundationModels-based actor on iOS 26+
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
        try await checkAvailabilityAndQuota()
        
        let prompt = buildVibePrompt(from: vibeAnalysis)
        let poemContent = try await generateContent(prompt: prompt)
        let poem = try parseGeneratedPoem(poemContent, vibe: vibeAnalysis.vibe)
        
        await incrementDailyCount()
        return poem
    }
    
    func generatePoemWithCustomPrompt(_ prompt: String) async throws -> Poem {
        try await checkAvailabilityAndQuota()
        
        guard !prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw PoemGenerationError.invalidPrompt
        }
        
        let enhancedPrompt = enhanceCustomPrompt(prompt)
        let poemContent = try await generateContent(prompt: enhancedPrompt)
        let poem = try parseGeneratedPoem(poemContent, vibe: nil)
        
        await incrementDailyCount()
        return poem
    }
    
    func isAvailable() async -> Bool {
        // For iOS 26 FoundationModels, check device capabilities
        return await checkDeviceSupport() && await checkModelAvailability()
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
        
        return \"\"\"\n        \\(basePrompt)\n        \n        Context: Today's news suggests \\(context). \n        \n        Please write a poem that captures this \\(vibeAnalysis.vibe.displayName.lowercased()) feeling while being:\n        - Original and creative\n        - Appropriate for all audiences\n        - 12-20 lines long\n        - Emotionally resonant\n        - Well-structured with clear rhythm\n        \n        Format the response as:\n        Title: [Poem Title]\n        Author: AI Poet\n        \n        [Poem content with line breaks]\n        \"\"\"\n    }\n    \n    private func buildContextFromAnalysis(_ analysis: VibeAnalysis) -> String {\n        let sentimentDesc = describeSentiment(analysis.sentiment)\n        let keywords = analysis.keywords.prefix(3).joined(separator: \", \")\n        \n        return \"a \\(analysis.vibe.displayName.lowercased()) atmosphere with \\(sentimentDesc). Key themes include: \\(keywords)\"\n    }\n    \n    private func describeSentiment(_ sentiment: SentimentScore) -> String {\n        switch (sentiment.positivity, sentiment.energy) {\n        case (0.7..., 0.7...):\n            return \"high positivity and energy\"\n        case (0.7..., _):\n            return \"positive but calm energy\"\n        case (_, 0.7...):\n            return \"high energy with mixed emotions\"\n        case (...0.3, ...):\n            return \"challenging but thoughtful themes\"\n        default:\n            return \"balanced emotional tones\"\n        }\n    }\n    \n    private func enhanceCustomPrompt(_ prompt: String) -> String {\n        return \"\"\"\n        Write a beautiful poem based on this request: \"\\(prompt)\"\n        \n        Please ensure the poem is:\n        - Original and creative\n        - Appropriate for all audiences\n        - 12-20 lines long\n        - Well-structured with clear rhythm\n        - Emotionally engaging\n        \n        Format the response as:\n        Title: [Poem Title]\n        Author: AI Poet\n        \n        [Poem content with line breaks]\n        \"\"\"\n    }\n    \n    private func generateContent(prompt: String) async throws -> String {\n        // This is where we would use the actual FoundationModels API\n        // For iOS 26, this might look something like:\n        /*\n        import FoundationModels\n        \n        let model = try await FoundationModel.textGeneration()\n        let request = TextGenerationRequest(\n            prompt: prompt,\n            maxTokens: 500,\n            temperature: 0.8,\n            topP: 0.9\n        )\n        \n        let response = try await model.generate(request)\n        return response.text\n        */\n        \n        // For now, we'll simulate the API call with mock generation\n        try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds\n        \n        // Check for content filtering\n        if containsInappropriateContent(prompt) {\n            throw PoemGenerationError.contentFiltered\n        }\n        \n        // Return a mock poem for demonstration\n        return await generateMockPoem(based: prompt)\n    }\n    \n    private func generateMockPoem(based prompt: String) async -> String {\n        // This is a simple mock implementation\n        // In reality, this would be handled by FoundationModels\n        let mockPoems = [\n            \"\"\"\n            Title: Morning's Promise\n            Author: AI Poet\n            \n            In the quiet dawn, hope whispers soft,\n            Through golden rays that lift hearts aloft,\n            Each new day brings a chance to grow,\n            To find the light that helps us glow.\n            \n            The world awakens with gentle grace,\n            And peace settles in this sacred space,\n            Where dreams and reality softly meet,\n            And life's rhythm finds its beat.\n            \n            So let us cherish this moment here,\n            Where love casts out all trace of fear,\n            For in this dawn, we clearly see\n            The beauty of what we're meant to be.\n            \"\"\",\n            \n            \"\"\"\n            Title: Winds of Change\n            Author: AI Poet\n            \n            The winds of change blow fierce and free,\n            Across the landscape of our destiny,\n            They carry stories from afar,\n            Of those who've wished upon a star.\n            \n            Through trials faced and lessons learned,\n            We find the bridges we have burned\n            Were merely paths that led us here,\n            To face tomorrow without fear.\n            \n            The storms may rage, the thunder roll,\n            But deep within lives a peaceful soul,\n            That knows beyond the clouded sky,\n            The sun still shines for you and I.\n            \"\"\",\n            \n            \"\"\"\n            Title: Quiet Reflections\n            Author: AI Poet\n            \n            In moments of silence, wisdom speaks,\n            To hearts that listen, souls that seek\n            The deeper truths that life can show\n            Through seasons of both joy and woe.\n            \n            The gentle rain upon the earth\n            Reminds us of our sacred worth,\n            Each drop a gift, each moment blessed\n            With opportunities to rest.\n            \n            And in this stillness, we can find\n            The peace that calms both heart and mind,\n            Where gratitude and wonder meet\n            To make our journey feel complete.\n            \"\"\"\n        ]\n        \n        return mockPoems.randomElement() ?? mockPoems[0]\n    }\n    \n    private func containsInappropriateContent(_ prompt: String) -> Bool {\n        // Simple content filtering - in reality would be more sophisticated\n        let inappropriateWords = [\"violence\", \"hate\", \"harm\", \"explicit\"]\n        let lowercasePrompt = prompt.lowercased()\n        return inappropriateWords.contains { lowercasePrompt.contains($0) }\n    }\n    \n    private func parseGeneratedPoem(_ content: String, vibe: DailyVibe?) throws -> Poem {\n        let lines = content.components(separatedBy: .newlines)\n        \n        var title = \"Generated Poem\"\n        var author = \"AI Poet\"\n        var poemLines: [String] = []\n        \n        var parsingPoem = false\n        \n        for line in lines {\n            let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)\n            \n            if trimmedLine.hasPrefix(\"Title:\") {\n                title = String(trimmedLine.dropFirst(6)).trimmingCharacters(in: .whitespacesAndNewlines)\n            } else if trimmedLine.hasPrefix(\"Author:\") {\n                author = String(trimmedLine.dropFirst(7)).trimmingCharacters(in: .whitespacesAndNewlines)\n            } else if !trimmedLine.isEmpty && !trimmedLine.hasPrefix(\"Title:\") && !trimmedLine.hasPrefix(\"Author:\") {\n                parsingPoem = true\n            }\n            \n            if parsingPoem && !trimmedLine.isEmpty {\n                poemLines.append(trimmedLine)\n            }\n        }\n        \n        if poemLines.isEmpty {\n            throw PoemGenerationError.generationFailed\n        }\n        \n        return Poem(\n            title: title,\n            lines: poemLines,\n            author: author,\n            vibe: vibe\n        )\n    }\n    \n    private func incrementDailyCount() async {\n        dailyGenerationCount += 1\n        userDefaults.set(dailyGenerationCount, forKey: \"dailyGenerationCount\")\n    }\n}

// For iOS <26, provide a fallback mock implementation
actor PoemGenerationService: PoemGenerationServiceProtocol {
    // ... existing code for mock/fallback ...
}