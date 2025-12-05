//
//  AIVibeAnalyzer.swift
//  Poem of the Day
//
//  Created by Claude Code on 2025-12-04.
//

import Foundation

#if canImport(FoundationModels)
import FoundationModels
#endif

/// Analyzes news content to determine the "vibe" using on-device Foundation Models
@available(iOS 26, *)
actor AIVibeAnalyzer {
    
    // MARK: - Types
    
    #if canImport(FoundationModels)
    @Generable(description: "Analysis of the mood and themes from news headlines")
    struct AIVibeResult: Codable {
        @Guide(description: "The mood from: hopeful, contemplative, energetic, peaceful, melancholic, inspiring, uncertain, celebratory, reflective, determined, nostalgic, adventurous, whimsical, urgent, triumphant, solemn, playful, mysterious, rebellious, compassionate")
        let vibe: String
        
        @Guide(description: "Brief reasoning for this mood choice (max 1 sentence)")
        let reasoning: String
        
        @Guide(description: "3-5 key themes extracted from the news")
        let themes: [String]
        
        @Guide(description: "Confidence score between 0.0 and 1.0")
        let confidence: Double
    }
    #endif
    
    // MARK: - Properties
    
    #if canImport(FoundationModels)
    private var modelSession: LanguageModelSession?
    #endif
    
    // MARK: - Initialization
    
    init() {
        Task {
            await initializeModel()
        }
    }
    
    private func initializeModel() async {
        #if canImport(FoundationModels)
        do {
            // Use the default system model for general text analysis
            let model = SystemLanguageModel.default
            self.modelSession = LanguageModelSession(model: model)
            AppLogger.shared.info("Model session initialized", category: .ai)
        } catch {
            AppLogger.shared.error("Failed to initialize model session: \(error)", category: .ai)
        }
        #endif
    }
    
    // MARK: - Analysis
    
    /// Analyzes the provided news articles to determine the daily vibe
    func analyzeVibe(from articles: [NewsArticle]) async throws -> VibeAnalysis? {
        #if canImport(FoundationModels)
        guard !articles.isEmpty else { return nil }
        guard let session = modelSession else {
            AppLogger.shared.warning("Model session not available", category: .ai)
            return nil
        }
        
        // Prepare the prompt with news headlines
        let headlines = articles.prefix(10).map { "- \($0.title)" }.joined(separator: "\n")
        let prompt = """
        Analyze these news headlines and determine the overall mood or "vibe":
        
        \(headlines)
        
        Select the most appropriate vibe from this list:
        hopeful, contemplative, energetic, peaceful, melancholic, inspiring, uncertain, celebratory, reflective, determined, nostalgic, adventurous, whimsical, urgent, triumphant, solemn, playful, mysterious, rebellious, compassionate.
        """
        
        AppLogger.shared.info("Starting analysis of \(articles.count) articles", category: .ai)
        
        do {
            // Use guided generation to get structured output
            let response = try await session.respond(to: prompt, generating: AIVibeResult.self)
            let result = response.content
            
            AppLogger.shared.info("Analysis complete", category: .ai)
            AppLogger.shared.debug("Vibe: \(result.vibe)", category: .ai)
            AppLogger.shared.debug("Confidence: \(result.confidence)", category: .ai)
            AppLogger.shared.debug("Reasoning: \(result.reasoning)", category: .ai)
            
            // Map string vibe to DailyVibe enum
            guard let dailyVibe = DailyVibe(rawValue: result.vibe.lowercased()) ?? 
                                  DailyVibe(rawValue: result.vibe.lowercased().trimmingCharacters(in: .whitespaces)) else {
                AppLogger.shared.warning("Could not map '\(result.vibe)' to DailyVibe enum", category: .ai)
                return nil
            }
            
            // Convert confidence to sentiment score (rough approximation)
            // In a real app, we might ask the AI for specific sentiment values too
            let sentiment = SentimentScore(
                positivity: result.confidence, // Using confidence as a proxy for intensity/positivity alignment for now
                energy: 0.5, // Neutral energy default
                complexity: 0.5 // Moderate complexity default
            )
            
            return VibeAnalysis(
                vibe: dailyVibe,
                confidence: result.confidence,
                reasoning: result.reasoning,
                keywords: result.themes,
                sentiment: sentiment
            )
            
        } catch {
            AppLogger.shared.error("Analysis failed: \(error)", category: .ai)
            return nil
        }
        #else
        return nil
        #endif
    }
    
    /// Checks if AI analysis is supported on this device
    var isAvailable: Bool {
        #if canImport(FoundationModels)
        return SystemLanguageModel.default.availability == .available
        #else
        return false
        #endif
    }
}
