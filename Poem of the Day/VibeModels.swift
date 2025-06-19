//
//  VibeModels.swift
//  Poem of the Day
//
//  Created by Claude Code on 2025-06-19.
//

import Foundation

// MARK: - Daily Vibe System

enum DailyVibe: String, Codable, CaseIterable {
    case hopeful = "hopeful"
    case contemplative = "contemplative"
    case energetic = "energetic"
    case peaceful = "peaceful"
    case melancholic = "melancholic"
    case inspiring = "inspiring"
    case uncertain = "uncertain"
    case celebratory = "celebratory"
    case reflective = "reflective"
    case determined = "determined"
    
    var displayName: String {
        switch self {
        case .hopeful: return "Hopeful"
        case .contemplative: return "Contemplative"
        case .energetic: return "Energetic"
        case .peaceful: return "Peaceful"
        case .melancholic: return "Melancholic"
        case .inspiring: return "Inspiring"
        case .uncertain: return "Uncertain"
        case .celebratory: return "Celebratory"
        case .reflective: return "Reflective"
        case .determined: return "Determined"
        }
    }
    
    var description: String {
        switch self {
        case .hopeful: return "Looking forward with optimism"
        case .contemplative: return "Deep thoughts and reflection"
        case .energetic: return "Full of life and motivation"
        case .peaceful: return "Calm and serene moments"
        case .melancholic: return "Bittersweet and thoughtful"
        case .inspiring: return "Uplifting and encouraging"
        case .uncertain: return "Navigating unclear times"
        case .celebratory: return "Joyful and triumphant"
        case .reflective: return "Quiet introspection"
        case .determined: return "Focused and resolute"
        }
    }
    
    var poemPrompt: String {
        switch self {
        case .hopeful:
            return "Write an uplifting poem about hope, new beginnings, and the promise of better days ahead. Focus on light breaking through darkness, seeds growing into flowers, and the resilience of the human spirit."
        case .contemplative:
            return "Write a thoughtful poem about life's deeper meanings, the passage of time, and quiet moments of reflection. Explore themes of wisdom, understanding, and the beauty found in stillness."
        case .energetic:
            return "Write a vibrant poem full of life, movement, and enthusiasm. Capture the feeling of rushing wind, dancing, laughter, and the joy of being fully alive and engaged with the world."
        case .peaceful:
            return "Write a serene poem about tranquility, calm waters, gentle breezes, and moments of perfect stillness. Focus on harmony, balance, and the quiet beauty of peaceful scenes."
        case .melancholic:
            return "Write a bittersweet poem that captures the beauty in sadness, the poetry of rain, autumn leaves, and gentle farewells. Explore themes of nostalgia, memory, and the tender ache of longing."
        case .inspiring:
            return "Write a motivational poem about overcoming challenges, reaching for dreams, and the power within each person to create change. Focus on courage, perseverance, and the triumph of the human spirit."
        case .uncertain:
            return "Write a poem about navigating unclear paths, standing at crossroads, and finding strength in times of doubt. Explore themes of patience, trust, and the wisdom of not knowing."
        case .celebratory:
            return "Write a joyful poem about celebration, achievement, and moments of pure happiness. Capture the feeling of success, gratitude, and the shared joy of special occasions."
        case .reflective:
            return "Write a quiet poem about looking back on life's journey, lessons learned, and the wisdom that comes with experience. Focus on memory, growth, and understanding."
        case .determined:
            return "Write a strong poem about unwavering resolve, commitment to goals, and the power of focused intention. Explore themes of persistence, strength, and the will to overcome obstacles."
        }
    }
    
    var emoji: String {
        switch self {
        case .hopeful: return "🌅"
        case .contemplative: return "🤔"
        case .energetic: return "⚡"
        case .peaceful: return "🕊️"
        case .melancholic: return "🌧️"
        case .inspiring: return "✨"
        case .uncertain: return "🌫️"
        case .celebratory: return "🎉"
        case .reflective: return "🪞"
        case .determined: return "💪"
        }
    }
}

// MARK: - News Data Models

struct NewsArticle: Codable, Identifiable {
    let id: UUID
    let title: String
    let description: String?
    let content: String?
    let publishedAt: Date
    let source: NewsSource
    let url: URL?
    
    init(title: String, description: String?, content: String?, publishedAt: Date, source: NewsSource, url: URL?) {
        self.id = UUID()
        self.title = title
        self.description = description
        self.content = content
        self.publishedAt = publishedAt
        self.source = source
        self.url = url
    }
    
    var fullText: String {
        var text = title
        if let description = description, !description.isEmpty {
            text += " " + description
        }
        if let content = content, !content.isEmpty {
            text += " " + content
        }
        return text
    }
}

struct NewsSource: Codable {
    let name: String
    let id: String?
}

struct NewsResponse: Codable {
    let status: String
    let totalResults: Int
    let articles: [NewsAPIArticle]
}

struct NewsAPIArticle: Codable {
    let source: NewsSource
    let title: String
    let description: String?
    let content: String?
    let publishedAt: String
    let url: String?
    
    func toNewsArticle() -> NewsArticle? {
        let formatter = ISO8601DateFormatter()
        guard let date = formatter.date(from: publishedAt) else { return nil }
        
        return NewsArticle(
            title: title,
            description: description,
            content: content,
            publishedAt: date,
            source: source,
            url: URL(string: url ?? "")
        )
    }
}

// MARK: - Vibe Analysis Result

struct VibeAnalysis: Codable {
    let vibe: DailyVibe
    let confidence: Double
    let reasoning: String
    let keywords: [String]
    let sentiment: SentimentScore
    let analysisDate: Date
    
    init(vibe: DailyVibe, confidence: Double, reasoning: String, keywords: [String], sentiment: SentimentScore) {
        self.vibe = vibe
        self.confidence = confidence
        self.reasoning = reasoning
        self.keywords = keywords
        self.sentiment = sentiment
        self.analysisDate = Date()
    }
}

struct SentimentScore: Codable {
    let positivity: Double // 0.0 to 1.0
    let energy: Double     // 0.0 to 1.0
    let complexity: Double // 0.0 to 1.0
    
    init(positivity: Double, energy: Double, complexity: Double) {
        self.positivity = max(0.0, min(1.0, positivity))
        self.energy = max(0.0, min(1.0, energy))
        self.complexity = max(0.0, min(1.0, complexity))
    }
}

// MARK: - Enhanced Poem Model

extension Poem {
    var vibe: DailyVibe? {
        // This could be stored as metadata in the future
        return nil
    }
    
    init(title: String, lines: [String], author: String? = nil, vibe: DailyVibe? = nil) {
        self.id = UUID()
        self.title = title
        self.content = lines.joined(separator: "\n")
        self.author = author?.isEmpty == true ? nil : author
    }
}