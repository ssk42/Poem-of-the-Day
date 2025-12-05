//
//  AIPoemGenerator.swift
//  Poem of the Day
//
//  Created by Claude Code on 2025-12-04.
//

import Foundation

#if canImport(FoundationModels)
import FoundationModels
#endif

/// Handles AI-based poem generation using Foundation Models
actor AIPoemGenerator {
    
    // MARK: - Properties
    
    #if canImport(FoundationModels)
    private var languageModel: SystemLanguageModel?
    private var modelSession: LanguageModelSession?
    #endif
    
    // MARK: - Initialization
    
    init() {
        Task {
            await initializeFoundationModel()
        }
    }
    
    // MARK: - Public Methods
    
    func checkAvailability() async -> AIAvailabilityStatus {
        #if canImport(FoundationModels)
        if #available(iOS 26, *) {
            let model = SystemLanguageModel.default
            switch model.availability {
            case .available:
                return .available
            case .unavailable(.deviceNotEligible):
                return .notEligible
            case .unavailable(.appleIntelligenceNotEnabled):
                return .notEnabled
            case .unavailable(.modelNotReady):
                return .loading
            @unknown default:
                return .unavailable
            }
        }
        #endif
        return .unavailable
    }
    
    // Deprecated, use checkAvailability()
    func isAvailable() async -> Bool {
        return await checkAvailability().isAvailable
    }
    
    func generatePoem(from vibeAnalysis: VibeAnalysis) async throws -> Poem {
        let prompt = buildVibePrompt(from: vibeAnalysis)
        AppLogger.shared.debug("Built prompt (\(prompt.count) chars)", category: .ai)
        
        #if canImport(FoundationModels)
        if #available(iOS 26, *) {
            AppLogger.shared.info("Attempting AI generation with Foundation Models...", category: .ai)
            let generatedPoem = try await generateWithFoundationModels(prompt: prompt)
            
            let poem = convertToPoemModel(generatedPoem, vibeAnalysis: vibeAnalysis)
            AppLogger.shared.info("Successfully generated poem via AI", category: .ai)
            return poem
        }
        #endif
        
        throw PoemGenerationError.modelUnavailable
    }
    
    func generatePoem(customPrompt: String) async throws -> Poem {
        let enhancedPrompt = enhanceCustomPrompt(customPrompt)
        
        #if canImport(FoundationModels)
        if #available(iOS 26, *) {
            let generatedPoem = try await generateWithFoundationModels(prompt: enhancedPrompt)
            
            // For custom prompts, extract keywords from prompt for dynamic title
            let keywords = LocalPoemGenerator.extractKeywordsFromPrompt(customPrompt)
            let dynamicTitle = keywords.first?.capitalized ?? generatedPoem.title
            
            let poem = Poem(
                title: dynamicTitle,
                lines: generatedPoem.lines,
                author: generatedPoem.author,
                vibe: nil,
                source: .aiGenerated
            )
            return poem
        }
        #endif
        
        throw PoemGenerationError.modelUnavailable
    }
    
    // MARK: - Foundation Models Logic
    
    private func initializeFoundationModel() async {
        #if canImport(FoundationModels)
        if #available(iOS 26, *) {
            do {
                // Use the default system language model without custom adapters for stability
                let model = SystemLanguageModel.default
                self.languageModel = model
                self.modelSession = LanguageModelSession(model: model)
                AppLogger.shared.info("FoundationModels initialized successfully", category: .ai)
            } catch {
                AppLogger.shared.error("Failed to initialize FoundationModels: \(error)", category: .ai)
                // Leave properties nil - checkAvailability will still work via SystemLanguageModel.default
            }
        }
        #endif
    }
    
    #if canImport(FoundationModels)
    @available(iOS 26, *)
    private func generateWithFoundationModels(prompt: String) async throws -> GeneratedPoem {
        guard let session = modelSession else {
            AppLogger.shared.error("Model session is not available", category: .ai)
            throw PoemGenerationError.modelUnavailable
        }
        
        do {
            // Use guided generation for structured poem output
            AppLogger.shared.debug("Attempting guided generation...", category: .ai)
            let response = try await session.respond(to: prompt, generating: GeneratedPoem.self)
            let generatedPoem = response.content
            
            guard !generatedPoem.title.isEmpty,
                  !generatedPoem.author.isEmpty,
                  !generatedPoem.lines.isEmpty else {
                AppLogger.shared.error("Generated poem has empty fields", category: .ai)
                throw PoemGenerationError.generationFailed
            }
            
            return generatedPoem
            
        } catch let error as LanguageModelSession.GenerationError {
            AppLogger.shared.warning("Guided generation failed: \(error). Trying fallback.", category: .ai)
            return try await generateWithFallback(session: session, prompt: prompt)
        } catch {
            AppLogger.shared.warning("Unexpected error: \(error). Trying fallback.", category: .ai)
            return try await generateWithFallback(session: session, prompt: prompt)
        }
    }
    
    @available(iOS 26, *)
    private func generateWithFallback(session: LanguageModelSession, prompt: String) async throws -> GeneratedPoem {
        do {
            let textResponse = try await session.respond(to: prompt)
            return try parseTextToPoem(textResponse.content)
        } catch {
            AppLogger.shared.error("Fallback text generation failed: \(error)", category: .ai)
            throw PoemGenerationError.generationFailed
        }
    }
    
    @available(iOS 26, *)
    private func parseTextToPoem(_ text: String) throws -> GeneratedPoem {
        var processedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Handle markdown code blocks
        if processedText.hasPrefix("```") {
            var lines = processedText.components(separatedBy: .newlines)
            if lines.first?.hasPrefix("```") == true { lines.removeFirst() }
            if lines.last?.trimmingCharacters(in: .whitespacesAndNewlines) == "```" { lines.removeLast() }
            processedText = lines.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        // Try JSON parsing
        if processedText.hasPrefix("{"), let jsonData = processedText.data(using: .utf8) {
            if let decoded = try? JSONDecoder().decode(GeneratedPoem.self, from: jsonData) {
                return decoded
            }
        }
        
        // Fallback text parsing
        let lines = processedText.components(separatedBy: .newlines)
        var title = "Generated Poem"
        var author = "AI Poet"
        var poemLines: [String] = []
        var style: String?
        
        var parsingPoem = false
        var foundMetadata = false
        
        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if !parsingPoem && trimmedLine.isEmpty { continue }
            
            if trimmedLine.hasPrefix("Title:") {
                title = String(trimmedLine.dropFirst(6)).trimmingCharacters(in: .whitespacesAndNewlines)
                foundMetadata = true
            } else if trimmedLine.hasPrefix("Author:") {
                author = String(trimmedLine.dropFirst(7)).trimmingCharacters(in: .whitespacesAndNewlines)
                foundMetadata = true
            } else if trimmedLine.hasPrefix("Style:") {
                style = String(trimmedLine.dropFirst(6)).trimmingCharacters(in: .whitespacesAndNewlines)
                foundMetadata = true
            } else if !trimmedLine.isEmpty {
                if foundMetadata || !parsingPoem { parsingPoem = true }
                if parsingPoem { poemLines.append(trimmedLine) }
            }
        }
        
        if !foundMetadata && poemLines.isEmpty {
            poemLines = lines.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
        }
        
        if poemLines.isEmpty { throw PoemGenerationError.generationFailed }
        
        return GeneratedPoem(title: title, author: author, lines: poemLines, style: style)
    }
    
    @available(iOS 26, *)
    private func convertToPoemModel(_ generatedPoem: GeneratedPoem, vibeAnalysis: VibeAnalysis) -> Poem {
        let keywords = vibeAnalysis.keywords.isEmpty ? LocalPoemGenerator.extractKeywordsFromVibe(vibeAnalysis.vibe) : vibeAnalysis.keywords
        let dynamicTitle = vibeAnalysis.vibe.generateDynamicTitle(keywords: keywords)
        
        return Poem(
            title: dynamicTitle,
            lines: generatedPoem.lines,
            author: generatedPoem.author,
            vibe: vibeAnalysis.vibe,
            source: .aiGenerated
        )
    }
    #endif
    
    // MARK: - Prompt Helpers
    
    private func buildVibePrompt(from vibeAnalysis: VibeAnalysis) -> String {
        let basePrompt = vibeAnalysis.vibe.poemPrompt
        let context = buildContextFromAnalysis(vibeAnalysis)
        
        return """
        You are a talented poet creating original poetry. \(basePrompt)
        
        Context: Today's news suggests \(context).
        
        Create a poem that captures this \(vibeAnalysis.vibe.displayName.lowercased()) feeling while being:
        - Original and creative
        - Appropriate for all audiences
        - Emotionally resonant
        - Well-structured with clear rhythm
        
        The poem should have:
        - A compelling title
        - Your name as "AI Poet" for the author
        - Individual lines of poetry (not paragraphs)
        - A style description (e.g., "free verse", "sonnet", "haiku")
        """
    }
    
    private func buildContextFromAnalysis(_ analysis: VibeAnalysis) -> String {
        let sentimentDesc = describeSentiment(analysis.sentiment)
        let keywords = analysis.keywords.prefix(3).joined(separator: ", ")
        return "a \(analysis.vibe.displayName.lowercased()) atmosphere with \(sentimentDesc). Key themes include: \(keywords)"
    }
    
    private func describeSentiment(_ sentiment: SentimentScore) -> String {
        switch (sentiment.positivity, sentiment.energy) {
        case (0.7..., 0.7...): return "high positivity and energy"
        case (0.7..., _): return "positive but calm energy"
        case (_, 0.7...): return "high energy with mixed emotions"
        case (...0.3, _): return "challenging but thoughtful themes"
        default: return "balanced emotional tones"
        }
    }
    
    private func enhanceCustomPrompt(_ prompt: String) -> String {
        return """
        You are a talented poet. Write a beautiful poem based on this request: "\(prompt)"
        
        Please ensure the poem is:
        - Original and creative
        - Appropriate for all audiences
        - Well-structured with clear rhythm
        - Emotionally engaging
        
        The poem should have:
        - A compelling title
        - Your name as "AI Poet" for the author
        - Individual lines of poetry (not paragraphs)
        - A style description (e.g., "free verse", "sonnet", "haiku")
        """
    }
}
