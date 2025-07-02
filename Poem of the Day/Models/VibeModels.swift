//
//  VibeModels.swift
//  Poem of the Day
//
//  Created by Claude Code on 2025-06-19.
//

import Foundation
import SwiftUI

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
    
    /// Returns the background color gradient for this vibe in light mode
    var lightModeBackgroundColors: [Color] {
        switch self {
        case .hopeful:
            return [Color(red: 1.0, green: 0.95, blue: 0.8), Color(red: 1.0, green: 0.9, blue: 0.7)] // Warm sunrise yellow/orange
        case .contemplative:
            return [Color(red: 0.85, green: 0.9, blue: 1.0), Color(red: 0.8, green: 0.85, blue: 0.95)] // Soft blue-gray
        case .energetic:
            return [Color(red: 1.0, green: 0.7, blue: 0.3), Color(red: 0.9, green: 0.6, blue: 0.2)] // Vibrant orange
        case .peaceful:
            return [Color(red: 0.9, green: 1.0, blue: 0.9), Color(red: 0.8, green: 0.95, blue: 0.8)] // Gentle green
        case .melancholic:
            return [Color(red: 0.9, green: 0.9, blue: 1.0), Color(red: 0.8, green: 0.8, blue: 0.95)] // Soft purple-gray
        case .inspiring:
            return [Color(red: 1.0, green: 0.9, blue: 1.0), Color(red: 0.95, green: 0.8, blue: 0.95)] // Light magenta/pink
        case .uncertain:
            return [Color(red: 0.95, green: 0.95, blue: 0.95), Color(red: 0.9, green: 0.9, blue: 0.9)] // Neutral gray
        case .celebratory:
            return [Color(red: 1.0, green: 0.8, blue: 0.6), Color(red: 1.0, green: 0.7, blue: 0.5)] // Golden celebration
        case .reflective:
            return [Color(red: 0.9, green: 0.95, blue: 1.0), Color(red: 0.85, green: 0.9, blue: 0.95)] // Calm blue
        case .determined:
            return [Color(red: 0.8, green: 0.9, blue: 1.0), Color(red: 0.7, green: 0.8, blue: 0.95)] // Strong blue
        }
    }
    
    /// Returns the background color gradient for this vibe in dark mode
    var darkModeBackgroundColors: [Color] {
        switch self {
        case .hopeful:
            return [Color(red: 0.3, green: 0.25, blue: 0.1), Color(red: 0.4, green: 0.3, blue: 0.15)] // Deep warm brown/gold
        case .contemplative:
            return [Color(red: 0.1, green: 0.15, blue: 0.3), Color(red: 0.15, green: 0.2, blue: 0.35)] // Deep blue-gray
        case .energetic:
            return [Color(red: 0.4, green: 0.2, blue: 0.1), Color(red: 0.5, green: 0.25, blue: 0.1)] // Dark orange
        case .peaceful:
            return [Color(red: 0.1, green: 0.3, blue: 0.15), Color(red: 0.15, green: 0.35, blue: 0.2)] // Deep forest green
        case .melancholic:
            return [Color(red: 0.2, green: 0.15, blue: 0.3), Color(red: 0.25, green: 0.2, blue: 0.35)] // Deep purple
        case .inspiring:
            return [Color(red: 0.3, green: 0.1, blue: 0.3), Color(red: 0.35, green: 0.15, blue: 0.35)] // Deep magenta
        case .uncertain:
            return [Color(red: 0.2, green: 0.2, blue: 0.25), Color(red: 0.25, green: 0.25, blue: 0.3)] // Dark gray
        case .celebratory:
            return [Color(red: 0.4, green: 0.3, blue: 0.1), Color(red: 0.45, green: 0.35, blue: 0.15)] // Rich gold
        case .reflective:
            return [Color(red: 0.1, green: 0.2, blue: 0.3), Color(red: 0.15, green: 0.25, blue: 0.35)] // Deep blue
        case .determined:
            return [Color(red: 0.1, green: 0.2, blue: 0.4), Color(red: 0.15, green: 0.25, blue: 0.45)] // Strong dark blue
        }
    }
    
    /// Returns the appropriate background gradient for the current color scheme
    func backgroundGradient(for colorScheme: ColorScheme) -> LinearGradient {
        let colors = colorScheme == .dark ? darkModeBackgroundColors : lightModeBackgroundColors
        return LinearGradient(
            gradient: Gradient(colors: colors),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    /// Returns the primary background color (first color in gradient) for the current color scheme
    func primaryBackgroundColor(for colorScheme: ColorScheme) -> Color {
        let colors = colorScheme == .dark ? darkModeBackgroundColors : lightModeBackgroundColors
        return colors.first ?? (colorScheme == .dark ? Color(red: 0.1, green: 0.1, blue: 0.2) : Color(red: 0.9, green: 0.95, blue: 1.0))
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
    let backgroundColorInfo: VibeBackgroundColorInfo
    
    init(vibe: DailyVibe, confidence: Double, reasoning: String, keywords: [String], sentiment: SentimentScore, backgroundColorIntensity: Double = 0.8) {
        self.vibe = vibe
        self.confidence = confidence
        self.reasoning = reasoning
        self.keywords = keywords
        self.sentiment = sentiment
        self.analysisDate = Date()
        self.backgroundColorInfo = VibeBackgroundColorInfo(vibe: vibe, intensity: backgroundColorIntensity)
    }
}

struct VibeBackgroundColorInfo: Codable {
    let vibe: DailyVibe
    let colorDescription: String
    let intensity: Double // 0.0 to 1.0, based on confidence
    
    init(vibe: DailyVibe, intensity: Double = 0.8) {
        self.vibe = vibe
        self.intensity = max(0.0, min(1.0, intensity))
        self.colorDescription = Self.generateColorDescription(for: vibe)
    }
    
    private static func generateColorDescription(for vibe: DailyVibe) -> String {
        switch vibe {
        case .hopeful:
            return "Warm sunrise colors with golden and amber tones that evoke optimism and new beginnings"
        case .contemplative:
            return "Soft blue-gray hues that inspire deep thought and peaceful reflection"
        case .energetic:
            return "Vibrant orange and warm colors that pulse with life and dynamic energy"
        case .peaceful:
            return "Gentle green tones reminiscent of serene nature and tranquil moments"
        case .melancholic:
            return "Soft purple-gray colors that capture the beauty of bittersweet emotions"
        case .inspiring:
            return "Light magenta and pink hues that uplift the spirit and encourage dreams"
        case .uncertain:
            return "Neutral gray tones that provide calm stability during unclear times"
        case .celebratory:
            return "Golden celebration colors that sparkle with joy and achievement"
        case .reflective:
            return "Calm blue shades that encourage quiet introspection and wisdom"
        case .determined:
            return "Strong blue colors that convey resolve, focus, and unwavering strength"
        }
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

// Note: Poem model with vibe support is defined in Poem.swift