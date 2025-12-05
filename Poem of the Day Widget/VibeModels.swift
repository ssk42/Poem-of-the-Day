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
    
    // New vibes
    case nostalgic = "nostalgic"
    case adventurous = "adventurous"
    case whimsical = "whimsical"
    case urgent = "urgent"
    case triumphant = "triumphant"
    case solemn = "solemn"
    case playful = "playful"
    case mysterious = "mysterious"
    case rebellious = "rebellious"
    case compassionate = "compassionate"
    
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
        case .nostalgic: return "Nostalgic"
        case .adventurous: return "Adventurous"
        case .whimsical: return "Whimsical"
        case .urgent: return "Urgent"
        case .triumphant: return "Triumphant"
        case .solemn: return "Solemn"
        case .playful: return "Playful"
        case .mysterious: return "Mysterious"
        case .rebellious: return "Rebellious"
        case .compassionate: return "Compassionate"
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
        case .nostalgic: return "Remembering days gone by"
        case .adventurous: return "Embracing the unknown"
        case .whimsical: return "Playfully imaginative"
        case .urgent: return "Time-sensitive and pressing"
        case .triumphant: return "Victorious and conquering"
        case .solemn: return "Reverent and dignified"
        case .playful: return "Lighthearted and fun"
        case .mysterious: return "Enigmatic and intriguing"
        case .rebellious: return "Defiant and challenging"
        case .compassionate: return "Empathetic and caring"
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
        case .nostalgic:
            return "Write a tender poem about memories, the passage of time, and the bittersweet beauty of looking back. Explore themes of childhood, heritage, and the golden glow of yesterdays."
        case .adventurous:
            return "Write an exciting poem about exploration, discovery, and the thrill of venturing into the unknown. Capture the spirit of journeys, quests, and the courage to explore new frontiers."
        case .whimsical:
            return "Write a playful poem filled with imagination, creativity, and delightful surprises. Embrace quirky imagery, fantastical ideas, and the joy of seeing the world through wonder-filled eyes."
        case .urgent:
            return "Write a compelling poem about pressing matters, crucial moments, and the weight of time-sensitive decisions. Explore themes of immediacy, crisis, and the need for swift action."
        case .triumphant:
            return "Write a powerful poem about victory, conquest, and the sweet taste of achievement. Capture the exhilaration of overcoming challenges and emerging victorious."
        case .solemn:
            return "Write a dignified poem about reverence, respect, and serious contemplation. Explore themes of remembrance, honor, and the weight of profound moments."
        case .playful:
            return "Write a joyful poem about fun, laughter, and the lightness of being. Embrace themes of games, dance, and the simple pleasures that make life delightful."
        case .mysterious:
            return "Write an intriguing poem about secrets, enigmas, and the allure of the unknown. Explore themes of puzzles, hidden truths, and the fascinating nature of mysteries."
        case .rebellious:
            return "Write a bold poem about defiance, resistance, and challenging the status quo. Explore themes of revolution, breaking boundaries, and standing up for beliefs."
        case .compassionate:
            return "Write a gentle poem about kindness, empathy, and the power of caring for others. Explore themes of love, tenderness, and the beauty of human connection."
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
        case .nostalgic: return "📚"
        case .adventurous: return "🗺️"
        case .whimsical: return "🎨"
        case .urgent: return "⏰"
        case .triumphant: return "🏆"
        case .solemn: return "🕯️"
        case .playful: return "🎭"
        case .mysterious: return "🔮"
        case .rebellious: return "⚔️"
        case .compassionate: return "💕"
        }
    }
    
    /// Title templates for poem generation - placeholders are [keyword] and [theme]
    var titleTemplates: [String] {
        switch self {
        case .hopeful:
            return ["Dawn of [keyword]", "[keyword] Rising", "When [theme] Met Hope", "The Promise of [keyword]", "[theme]: A New Beginning"]
        case .contemplative:
            return ["Thoughts on [keyword]", "Pondering [theme]", "The Depth of [keyword]", "Reflections: [theme]", "In Search of [keyword]"]
        case .energetic:
            return ["The Rush of [keyword]", "[theme] in Motion", "Surge of [keyword]", "Racing Through [theme]", "[keyword] Ablaze"]
        case .peaceful:
            return ["Tranquil [keyword]", "The Calm of [theme]", "[keyword] at Rest", "Serenity in [theme]", "Stillness: [keyword]"]
        case .melancholic:
            return ["Farewell to [keyword]", "The Weight of [theme]", "[keyword] in Rain", "Autumn [theme]", "Missing [keyword]"]
        case .inspiring:
            return ["Rise of [keyword]", "[theme] Awakening", "The Power of [keyword]", "Courage in [theme]", "[keyword] Ascends"]
        case .uncertain:
            return ["Crossroads of [keyword]", "Navigating [theme]", "The Unknown [keyword]", "Doubts About [theme]", "[keyword] in Question"]
        case .celebratory:
            return ["Victory of [keyword]", "Celebrating [theme]", "[keyword] Triumphant", "Joy in [theme]", "Festival of [keyword]"]
        case .reflective:
            return ["Looking Back at [keyword]", "Lessons from [theme]", "Wisdom of [keyword]", "Memory: [theme]", "[keyword] Remembered"]
        case .determined:
            return ["The Will of [keyword]", "Persevering Through [theme]", "[keyword] Unshaken", "Resolve in [theme]", "Standing for [keyword]"]
        case .nostalgic:
            return ["Echoes of [keyword]", "When [theme] Was New", "Remembering [keyword]", "[theme] Through Time", "Yesterday's [keyword]"]
        case .adventurous:
            return ["The Quest for [keyword]", "[theme] Uncharted", "Beyond [keyword]", "Exploring [theme]", "Journey to [keyword]"]
        case .whimsical:
            return ["A [keyword] Daydream", "[theme] in Wonderland", "The Curious [keyword]", "Whimsy of [theme]", "[keyword] and Magic"]
        case .urgent:
            return ["[theme] Now", "The Pressing [keyword]", "Time for [theme]", "[keyword] Urgent", "Critical [theme]"]
        case .triumphant:
            return ["The Triumph of [keyword]", "[theme] Victorious", "Conquering [keyword]", "Victory: [theme]", "[keyword] Prevails"]
        case .solemn:
            return ["In Remembrance of [keyword]", "The Weight of [theme]", "Honoring [keyword]", "Sacred [theme]", "[keyword] in Dignity"]
        case .playful:
            return ["Dancing with [keyword]", "The [theme] Waltz", "When [keyword] Plays", "Games of [theme]", "[keyword] in Jest"]
        case .mysterious:
            return ["The Mystery of [keyword]", "[theme] Unveiled", "Secrets of [keyword]", "Enigma: [theme]", "[keyword] Unknown"]
        case .rebellious:
            return ["Rising Against [keyword]", "The [theme] Rebellion", "Breaking [keyword]", "Defying [theme]", "[keyword] Unbound"]
        case .compassionate:
            return ["With Love for [keyword]", "The Gentle [theme]", "Embracing [keyword]", "Kindness in [theme]", "[keyword] in Heart"]
        }
    }
    
    /// Generates a dynamic poem title using keywords and themes
    func generateDynamicTitle(keywords: [String], theme: String? = nil) -> String {
        let templates = titleTemplates
        let template = templates.randomElement() ?? "[keyword]"
        
        var title = template
        
        // Replace [keyword] with first keyword
        if let keyword = keywords.first?.capitalized {
            title = title.replacingOccurrences(of: "[keyword]", with: keyword)
        } else {
            title = title.replacingOccurrences(of: "[keyword]", with: displayName)
        }
        
        // Replace [theme] with theme or second keyword
        let themeReplacement = theme?.capitalized ?? keywords.dropFirst().first?.capitalized ?? displayName
        title = title.replacingOccurrences(of: "[theme]", with: themeReplacement)
        
        return title
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
        case .nostalgic:
            return [Color(red: 0.95, green: 0.9, blue: 0.85), Color(red: 0.9, green: 0.85, blue: 0.8)] // Warm sepia
        case .adventurous:
            return [Color(red: 0.85, green: 1.0, blue: 0.9), Color(red: 0.8, green: 0.95, blue: 0.85)] // Fresh teal-green
        case .whimsical:
            return [Color(red: 1.0, green: 0.95, blue: 0.9), Color(red: 0.95, green: 0.9, blue: 0.95)] // Soft rainbow
        case .urgent:
            return [Color(red: 1.0, green: 0.85, blue: 0.7), Color(red: 0.95, green: 0.75, blue: 0.6)] // Alert orange-red
        case .triumphant:
            return [Color(red: 1.0, green: 0.95, blue: 0.7), Color(red: 0.95, green: 0.9, blue: 0.6)] // Victory gold
        case .solemn:
            return [Color(red: 0.85, green: 0.85, blue: 0.9), Color(red: 0.8, green: 0.8, blue: 0.85)] // Dignified gray-blue
        case .playful:
            return [Color(red: 1.0, green: 0.9, blue: 0.8), Color(red: 0.95, green: 0.85, blue: 0.75)] // Cheerful peach
        case .mysterious:
            return [Color(red: 0.8, green: 0.75, blue: 0.9), Color(red: 0.75, green: 0.7, blue: 0.85)] // Enigmatic purple
        case .rebellious:
            return [Color(red: 0.95, green: 0.7, blue: 0.7), Color(red: 0.9, green: 0.6, blue: 0.6)] // Bold red
        case .compassionate:
            return [Color(red: 1.0, green: 0.9, blue: 0.95), Color(red: 0.95, green: 0.85, blue: 0.9)] // Tender pink
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
        case .nostalgic:
            return [Color(red: 0.3, green: 0.25, blue: 0.2), Color(red: 0.35, green: 0.3, blue: 0.25)] // Deep sepia
        case .adventurous:
            return [Color(red: 0.1, green: 0.3, blue: 0.25), Color(red: 0.15, green: 0.35, blue: 0.3)] // Deep teal
        case .whimsical:
            return [Color(red: 0.3, green: 0.2, blue: 0.3), Color(red: 0.35, green: 0.25, blue: 0.35)] // Soft dark rainbow
        case .urgent:
            return [Color(red: 0.4, green: 0.2, blue: 0.15), Color(red: 0.45, green: 0.25, blue: 0.2)] // Dark alert orange
        case .triumphant:
            return [Color(red: 0.4, green: 0.35, blue: 0.15), Color(red: 0.45, green: 0.4, blue: 0.2)] // Deep gold
        case .solemn:
            return [Color(red: 0.15, green: 0.15, blue: 0.25), Color(red: 0.2, green: 0.2, blue: 0.3)] // Deep gray-blue
        case .playful:
            return [Color(red: 0.3, green: 0.2, blue: 0.15), Color(red: 0.35, green: 0.25, blue: 0.2)] // Warm dark peach
        case .mysterious:
            return [Color(red: 0.2, green: 0.15, blue: 0.35), Color(red: 0.25, green: 0.2, blue: 0.4)] // Deep purple
        case .rebellious:
            return [Color(red: 0.35, green: 0.1, blue: 0.1), Color(red: 0.4, green: 0.15, blue: 0.15)] // Deep red
        case .compassionate:
            return [Color(red: 0.3, green: 0.15, blue: 0.25), Color(red: 0.35, green: 0.2, blue: 0.3)] // Deep pink
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
        case .nostalgic:
            return "Warm sepia tones that evoke memories and the gentle glow of days gone by"
        case .adventurous:
            return "Fresh teal-green colors that inspire exploration and discovery"
        case .whimsical:
            return "Soft rainbow hues that sparkle with imagination and playful creativity"
        case .urgent:
            return "Alert orange-red tones that convey immediacy and pressing importance"
        case .triumphant:
            return "Victory gold colors that shine with achievement and conquest"
        case .solemn:
            return "Dignified gray-blue hues that reflect reverence and serious contemplation"
        case .playful:
            return "Cheerful peach colors that radiate fun, laughter, and joy"
        case .mysterious:
            return "Enigmatic purple shades that hint at secrets and hidden truths"
        case .rebellious:
            return "Bold red colors that burn with defiance and the spirit of revolution"
        case .compassionate:
            return "Tender pink tones that embody kindness, empathy, and caring"
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
    
    static let neutral = SentimentScore(positivity: 0.5, energy: 0.5, complexity: 0.0)
}

// Note: Poem model with vibe support is defined in Poem.swift