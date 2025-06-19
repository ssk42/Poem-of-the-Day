//
//  VibeAnalyzer.swift
//  Poem of the Day
//
//  Created by Claude Code on 2025-06-19.
//

import Foundation

protocol VibeAnalyzerProtocol: Sendable {
    func analyzeVibe(from articles: [NewsArticle]) async -> VibeAnalysis
}

actor VibeAnalyzer: VibeAnalyzerProtocol {
    
    // MARK: - Keyword Dictionaries
    
    private let vibeKeywords: [DailyVibe: [String]] = [
        .hopeful: [
            "breakthrough", "discovery", "progress", "success", "achievement", "improvement", 
            "recovery", "growth", "positive", "advance", "solution", "innovation", "hope",
            "promising", "bright", "optimistic", "future", "opportunity", "healing"
        ],
        .contemplative: [
            "study", "research", "analysis", "report", "findings", "investigation",
            "examination", "review", "consideration", "reflection", "thought", "meditation",
            "philosophy", "wisdom", "understanding", "insight", "depth", "meaning"
        ],
        .energetic: [
            "launch", "start", "begin", "action", "movement", "fast", "rapid", "quick",
            "energy", "power", "dynamic", "active", "vibrant", "exciting", "thrilling",
            "passionate", "intense", "vigorous", "lively", "enthusiastic"
        ],
        .peaceful: [
            "agreement", "peace", "calm", "quiet", "serene", "harmony", "balance",
            "resolution", "settled", "tranquil", "still", "gentle", "cooperation",
            "collaboration", "unity", "accord", "reconciliation", "mediation"
        ],
        .melancholic: [
            "loss", "death", "mourning", "grief", "sad", "tragedy", "decline", "ending",
            "farewell", "memorial", "remembrance", "nostalgia", "bittersweet", "longing",
            "missing", "departed", "past", "memory", "regret", "sorrow"
        ],
        .inspiring: [
            "hero", "brave", "courage", "overcome", "triumph", "victory", "inspire",
            "motivate", "encourage", "uplift", "empower", "strength", "resilience",
            "perseverance", "determination", "achievement", "excellence", "outstanding"
        ],
        .uncertain: [
            "unclear", "unknown", "uncertain", "doubt", "question", "mystery", "puzzle",
            "confusion", "ambiguous", "unclear", "unsure", "debate", "speculation",
            "possibility", "maybe", "perhaps", "investigation", "pending", "waiting"
        ],
        .celebratory: [
            "celebration", "festival", "party", "joy", "happiness", "success", "win",
            "victory", "achievement", "milestone", "anniversary", "honor", "award",
            "recognition", "congratulations", "cheers", "festive", "jubilant", "triumphant"
        ],
        .reflective: [
            "looking back", "history", "past", "lessons", "learned", "experience",
            "retrospective", "memorial", "remembering", "tradition", "heritage",
            "legacy", "wisdom", "knowledge", "understanding", "perspective", "insight"
        ],
        .determined: [
            "commitment", "dedication", "focus", "goal", "target", "mission", "purpose",
            "resolve", "determination", "persistence", "effort", "work", "strive",
            "push", "drive", "ambition", "will", "strength", "fight", "struggle"
        ]
    ]
    
    private let positiveWords = [
        "good", "great", "excellent", "amazing", "wonderful", "fantastic", "positive",
        "successful", "beneficial", "helpful", "beautiful", "love", "joy", "happy",
        "pleased", "excited", "thrilled", "delighted", "proud", "grateful"
    ]
    
    private let negativeWords = [
        "bad", "terrible", "awful", "horrible", "negative", "failed", "disaster",
        "crisis", "problem", "issue", "concern", "worry", "fear", "angry", "sad",
        "disappointed", "frustrated", "upset", "troubled", "disturbed", "alarmed"
    ]
    
    private let energyWords = [
        "fast", "quick", "rapid", "speed", "rush", "burst", "explosive", "dynamic",
        "intense", "powerful", "strong", "force", "drive", "push", "action", "move",
        "active", "energetic", "vibrant", "lively", "exciting", "thrilling"
    ]
    
    private let calmWords = [
        "slow", "gentle", "soft", "quiet", "calm", "peaceful", "serene", "tranquil",
        "still", "steady", "stable", "balanced", "harmonious", "soothing", "relaxing",
        "comfortable", "easy", "smooth", "gradual", "patient", "mindful"
    ]
    
    func analyzeVibe(from articles: [NewsArticle]) async -> VibeAnalysis {
        let combinedText = articles.map { $0.fullText }.joined(separator: " ")
        let words = extractWords(from: combinedText)
        
        // Calculate sentiment scores
        let sentiment = calculateSentiment(from: words)
        
        // Calculate vibe scores for each vibe type
        var vibeScores: [DailyVibe: Double] = [:]
        
        for vibe in DailyVibe.allCases {
            let score = calculateVibeScore(for: vibe, in: words)
            vibeScores[vibe] = score
        }
        
        // Find the vibe with the highest score
        let topVibe = vibeScores.max(by: { $0.value < $1.value })?.key ?? .contemplative
        let confidence = vibeScores[topVibe] ?? 0.0
        
        // Generate reasoning
        let reasoning = generateReasoning(for: topVibe, from: articles, sentiment: sentiment)
        
        // Extract key thematic words
        let keywords = extractKeywords(for: topVibe, from: words)
        
        return VibeAnalysis(
            vibe: topVibe,
            confidence: min(1.0, confidence),
            reasoning: reasoning,
            keywords: keywords,
            sentiment: sentiment
        )
    }
    
    private func extractWords(from text: String) -> [String] {
        let cleanedText = text.lowercased()
            .replacingOccurrences(of: "[^a-zA-Z\\s]", with: " ", options: .regularExpression)
        
        return cleanedText
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { $0.count > 2 } // Filter out very short words
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }
    
    private func calculateSentiment(from words: [String]) -> SentimentScore {
        let totalWords = Double(words.count)
        guard totalWords > 0 else {
            return SentimentScore(positivity: 0.5, energy: 0.5, complexity: 0.5)
        }
        
        // Calculate positivity
        let positiveCount = Double(words.filter { positiveWords.contains($0) }.count)
        let negativeCount = Double(words.filter { negativeWords.contains($0) }.count)
        let positivity = (positiveCount - negativeCount + totalWords * 0.1) / (totalWords * 0.2)
        
        // Calculate energy level
        let energyCount = Double(words.filter { energyWords.contains($0) }.count)
        let calmCount = Double(words.filter { calmWords.contains($0) }.count)
        let energy = (energyCount - calmCount * 0.5 + totalWords * 0.1) / (totalWords * 0.2)
        
        // Calculate complexity (based on average word length and vocabulary diversity)
        let averageWordLength = words.reduce(0) { $0 + $1.count } / words.count
        let uniqueWords = Set(words).count
        let vocabularyDiversity = Double(uniqueWords) / totalWords
        let complexity = (Double(averageWordLength) / 10.0 + vocabularyDiversity) / 2.0
        
        return SentimentScore(
            positivity: max(0.0, min(1.0, positivity)),
            energy: max(0.0, min(1.0, energy)),
            complexity: max(0.0, min(1.0, complexity))
        )
    }
    
    private func calculateVibeScore(for vibe: DailyVibe, in words: [String]) -> Double {
        guard let keywords = vibeKeywords[vibe] else { return 0.0 }
        
        let matchCount = words.filter { word in
            keywords.contains { keyword in
                word.contains(keyword) || keyword.contains(word)
            }
        }.count
        
        // Normalize by total word count and keyword count
        let totalWords = Double(words.count)
        let totalKeywords = Double(keywords.count)
        
        guard totalWords > 0 && totalKeywords > 0 else { return 0.0 }
        
        // Score based on keyword density
        let density = Double(matchCount) / totalWords
        let normalizedScore = density * 100 * (totalKeywords / 20.0) // Adjust for keyword list size
        
        return normalizedScore
    }
    
    private func generateReasoning(for vibe: DailyVibe, from articles: [NewsArticle], sentiment: SentimentScore) -> String {
        let topTitles = articles.prefix(3).map { $0.title }
        let keyThemes = identifyKeyThemes(from: articles)
        
        let sentimentDescription: String
        switch sentiment.positivity {
        case 0.0..<0.3:
            sentimentDescription = "challenging news"
        case 0.3..<0.7:
            sentimentDescription = "mixed developments"
        default:
            sentimentDescription = "positive developments"
        }
        
        let energyDescription: String
        switch sentiment.energy {
        case 0.0..<0.3:
            sentimentDescription = "calm, steady news"
        case 0.3..<0.7:
            sentimentDescription = "moderate activity"
        default:
            sentimentDescription = "high-energy events"
        }
        
        return "Today's news reflects a \(vibe.displayName.lowercased()) mood based on \(sentimentDescription) and \(energyDescription). Key themes include: \(keyThemes.joined(separator: ", ")). Headlines suggest \(vibe.description.lowercased())."
    }
    
    private func identifyKeyThemes(from articles: [NewsArticle]) -> [String] {
        let allText = articles.map { $0.fullText }.joined(separator: " ")
        let words = extractWords(from: allText)
        
        // Common news themes to look for
        let themes = [
            "politics": ["government", "president", "congress", "election", "policy", "law"],
            "health": ["health", "medical", "doctor", "hospital", "treatment", "vaccine"],
            "technology": ["technology", "digital", "app", "internet", "computer", "innovation"],
            "environment": ["climate", "environment", "green", "renewable", "pollution", "nature"],
            "economy": ["economy", "business", "market", "financial", "money", "economic"],
            "social": ["community", "social", "people", "family", "education", "culture"]
        ]
        
        var themeScores: [String: Int] = [:]
        
        for (theme, keywords) in themes {
            let matches = words.filter { word in
                keywords.contains { keyword in
                    word.contains(keyword) || keyword.contains(word)
                }
            }.count
            themeScores[theme] = matches
        }
        
        return themeScores
            .sorted { $0.value > $1.value }
            .prefix(3)
            .map { $0.key }
    }
    
    private func extractKeywords(for vibe: DailyVibe, from words: [String]) -> [String] {
        guard let vibeWords = vibeKeywords[vibe] else { return [] }
        
        let matchedWords = words.filter { word in
            vibeWords.contains { vibeWord in
                word.contains(vibeWord) || vibeWord.contains(word)
            }
        }
        
        // Return unique, most relevant keywords
        return Array(Set(matchedWords))
            .sorted()
            .prefix(5)
            .map { $0 }
    }
}