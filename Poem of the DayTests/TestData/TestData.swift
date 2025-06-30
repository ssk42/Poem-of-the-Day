import Foundation
@testable import Poem_of_the_Day

// MARK: - Test Data Factory

struct TestData {
    
    // MARK: - Sample Poems
    
    static let samplePoem = Poem(
        title: "The Road Not Taken",
        author: "Robert Frost",
        lines: [
            "Two roads diverged in a yellow wood,",
            "And sorry I could not travel both",
            "And be one traveler, long I stood",
            "And looked down one as far as I could",
            "To where it bent in the undergrowth;"
        ],
        linecount: "5"
    )
    
    static let samplePoem2 = Poem(
        title: "Hope",
        author: "Emily Dickinson",
        lines: [
            "Hope is the thing with feathers",
            "That perches in the soul,",
            "And sings the tune without the words,",
            "And never stops at all."
        ],
        linecount: "4"
    )
    
    static let samplePoem3 = Poem(
        title: "The Love Song of J. Alfred Prufrock",
        author: "T.S. Eliot",
        lines: [
            "Let us go then, you and I,",
            "When the evening is spread out against the sky",
            "Like a patient etherized upon a table;"
        ],
        linecount: "3"
    )
    
    static func sampleAIPoem(vibe: DailyVibe) -> Poem {
        let poemContent = generatePoemForVibe(vibe)
        return Poem(
            title: poemContent.title,
            author: "AI Generated",
            lines: poemContent.lines,
            linecount: "\(poemContent.lines.count)",
            vibe: vibe
        )
    }
    
    static func sampleCustomPoem(prompt: String) -> Poem {
        return Poem(
            title: "Custom Creation",
            author: "AI Generated",
            lines: [
                "In response to your prompt:",
                "\"\(prompt)\"",
                "I craft these words with care,",
                "A poem born from digital thought,",
                "Yet filled with human prayer."
            ],
            linecount: "5",
            vibe: .inspiring
        )
    }
    
    static let samplePoems: [Poem] = [
        samplePoem,
        samplePoem2,
        samplePoem3
    ]
    
    // MARK: - Sample News Articles
    
    static let sampleNewsArticles: [NewsArticle] = [
        NewsArticle(
            title: "Scientists Discover New Treatment for Rare Disease",
            description: "Breakthrough research offers hope for patients worldwide",
            content: "Researchers at a leading university have developed a promising new treatment...",
            publishedAt: Date().addingTimeInterval(-3600),
            source: NewsSource(name: "Science Daily", url: URL(string: "https://sciencedaily.com")!),
            url: URL(string: "https://sciencedaily.com/breakthrough-treatment")
        ),
        NewsArticle(
            title: "Local Community Comes Together to Help Neighbors",
            description: "Heartwarming story of solidarity during challenging times",
            content: "In a remarkable display of community spirit, residents have organized...",
            publishedAt: Date().addingTimeInterval(-7200),
            source: NewsSource(name: "Community News", url: URL(string: "https://community.news")!),
            url: URL(string: "https://community.news/solidarity-story")
        ),
        NewsArticle(
            title: "Technology Innovation Promises Sustainable Future",
            description: "New green technology could revolutionize energy production",
            content: "A startup company has unveiled technology that could significantly reduce...",
            publishedAt: Date().addingTimeInterval(-10800),
            source: NewsSource(name: "Tech World", url: URL(string: "https://techworld.com")!),
            url: URL(string: "https://techworld.com/green-innovation")
        )
    ]
    
    // MARK: - Sample Vibe Analysis
    
    static let sampleVibeAnalysis = VibeAnalysis(
        vibe: .hopeful,
        confidence: 0.85,
        reasoning: "The news articles contain positive developments in science, community solidarity, and sustainable technology, indicating an overall hopeful outlook.",
        keywords: ["breakthrough", "hope", "community", "innovation", "future"],
        sentiment: SentimentScore(positivity: 0.8, energy: 0.7, complexity: 0.6),
        analysisDate: Date()
    )
    
    static let sampleVibeAnalyses: [VibeAnalysis] = [
        VibeAnalysis(
            vibe: .hopeful,
            confidence: 0.85,
            reasoning: "Positive news about scientific breakthroughs and community support",
            keywords: ["breakthrough", "hope", "community"],
            sentiment: SentimentScore(positivity: 0.8, energy: 0.7, complexity: 0.6),
            analysisDate: Date()
        ),
        VibeAnalysis(
            vibe: .contemplative,
            confidence: 0.72,
            reasoning: "Complex global issues requiring deep thought and reflection",
            keywords: ["complex", "reflection", "analysis"],
            sentiment: SentimentScore(positivity: 0.5, energy: 0.4, complexity: 0.9),
            analysisDate: Date().addingTimeInterval(-86400)
        ),
        VibeAnalysis(
            vibe: .energetic,
            confidence: 0.91,
            reasoning: "News of technological innovations and rapid progress",
            keywords: ["innovation", "progress", "dynamic"],
            sentiment: SentimentScore(positivity: 0.9, energy: 0.95, complexity: 0.7),
            analysisDate: Date().addingTimeInterval(-172800)
        )
    ]
    
    // MARK: - Test Scenarios
    
    enum TestScenario {
        case normalOperation
        case networkError
        case serverError
        case emptyData
        case rateLimited
        case aiUnavailable
        case aiError
        case slowResponse
        case malformedData
        
        var description: String {
            switch self {
            case .normalOperation:
                return "Normal operation with successful responses"
            case .networkError:
                return "Network connectivity issues"
            case .serverError:
                return "Server returning error responses"
            case .emptyData:
                return "APIs returning empty or no data"
            case .rateLimited:
                return "Rate limiting from external services"
            case .aiUnavailable:
                return "AI services not available on device"
            case .aiError:
                return "AI generation failures"
            case .slowResponse:
                return "Slow response times from services"
            case .malformedData:
                return "Invalid or corrupted data responses"
            }
        }
    }
    
    // MARK: - JSON Test Data
    
    static let samplePoemJSON = """
    {
        "title": "The Road Not Taken",
        "author": "Robert Frost",
        "lines": [
            "Two roads diverged in a yellow wood,",
            "And sorry I could not travel both",
            "And be one traveler, long I stood",
            "And looked down one as far as I could",
            "To where it bent in the undergrowth;"
        ],
        "linecount": "5"
    }
    """
    
    static let samplePoemResponseJSON = """
    [
        {
            "title": "The Road Not Taken",
            "author": "Robert Frost",
            "lines": [
                "Two roads diverged in a yellow wood,",
                "And sorry I could not travel both"
            ],
            "linecount": "2"
        }
    ]
    """
    
    static let malformedPoemJSON = """
    {
        "title": "Incomplete Poem",
        "author": null,
        "lines": "This should be an array",
        "linecount": "invalid"
    }
    """
    
    static let emptyPoemResponseJSON = "[]"
    
    // MARK: - Test UserDefaults Keys
    
    enum TestUserDefaultsKeys {
        static let testPoem = "test_daily_poem"
        static let testFavorites = "test_favorites"
        static let testVibeAnalysis = "test_vibe_analysis"
        static let testLastFetchDate = "test_last_fetch_date"
        static let testTelemetryEvents = "test_telemetry_events"
    }
    
    // MARK: - Test Utilities
    
    static func createTestUserDefaults() -> UserDefaults {
        let defaults = MockUserDefaults()
        return defaults
    }
    
    static func poemData(from poem: Poem) -> Data? {
        return try? JSONEncoder().encode(poem)
    }
    
    static func vibeAnalysisData(from analysis: VibeAnalysis) -> Data? {
        return try? JSONEncoder().encode(analysis)
    }
    
    static func favoritesData(from poems: [Poem]) -> Data? {
        return try? JSONEncoder().encode(poems)
    }
    
    // MARK: - Private Helpers
    
    private static func generatePoemForVibe(_ vibe: DailyVibe) -> (title: String, lines: [String]) {
        switch vibe {
        case .hopeful:
            return (
                title: "Tomorrow's Light",
                lines: [
                    "Dawn breaks with promise anew,",
                    "Golden rays pierce morning dew,",
                    "Hope rises with the sun,",
                    "A new day has begun."
                ]
            )
        case .contemplative:
            return (
                title: "Quiet Thoughts",
                lines: [
                    "In silence, wisdom speaks,",
                    "The mind its answers seeks,",
                    "Through stillness, truth unfolds,",
                    "Stories that must be told."
                ]
            )
        case .energetic:
            return (
                title: "Lightning Spirit",
                lines: [
                    "Energy flows like electric streams,",
                    "Powering hopes and wildest dreams,",
                    "Movement creates the spark of life,",
                    "Cutting through doubt like sharpest knife."
                ]
            )
        case .peaceful:
            return (
                title: "Serene Waters",
                lines: [
                    "Calm waters reflect the sky,",
                    "Gentle breezes whisper by,",
                    "Peace settles on the soul,",
                    "Making broken spirits whole."
                ]
            )
        case .melancholic:
            return (
                title: "Autumn Rain",
                lines: [
                    "Rain taps on window panes,",
                    "Washing away summer's gains,",
                    "Melancholy fills the air,",
                    "Beautiful in its despair."
                ]
            )
        case .inspiring:
            return (
                title: "Mountain Peak",
                lines: [
                    "Climb higher than you've been before,",
                    "Push through and find what lies in store,",
                    "Inspiration lights the way,",
                    "To reach new heights this very day."
                ]
            )
        case .uncertain:
            return (
                title: "Foggy Path",
                lines: [
                    "The path ahead is unclear,",
                    "Shrouded in doubt and fear,",
                    "Yet step by step we go,",
                    "Through mist we'll find what's true to know."
                ]
            )
        case .celebratory:
            return (
                title: "Victory Dance",
                lines: [
                    "Raise your voice in joyful song,",
                    "Celebrate what makes you strong,",
                    "Dance beneath the starlit sky,",
                    "Let your spirit soar and fly."
                ]
            )
        case .reflective:
            return (
                title: "Mirror Lake",
                lines: [
                    "Looking back on days gone by,",
                    "Seeing truth in memory's eye,",
                    "Reflection shows us who we are,",
                    "And guides us to our destined star."
                ]
            )
        case .determined:
            return (
                title: "Iron Will",
                lines: [
                    "Nothing can break my steady will,",
                    "I'll climb each mountain, every hill,",
                    "Determination burns so bright,",
                    "It turns the darkness into light."
                ]
            )
        }
    }
}

// MARK: - Test Data Extensions

extension Poem {
    static func testPoem(
        title: String = "Test Poem",
        author: String = "Test Author",
        lines: [String] = ["Line 1", "Line 2"],
        vibe: DailyVibe? = nil
    ) -> Poem {
        return Poem(
            title: title,
            author: author,
            lines: lines,
            linecount: "\(lines.count)",
            vibe: vibe
        )
    }
}

extension VibeAnalysis {
    static func testVibe(
        vibe: DailyVibe = .hopeful,
        confidence: Double = 0.8
    ) -> VibeAnalysis {
        return VibeAnalysis(
            vibe: vibe,
            confidence: confidence,
            reasoning: "Test reasoning",
            keywords: ["test", "sample"],
            sentiment: SentimentScore(positivity: 0.7, energy: 0.6, complexity: 0.5),
            analysisDate: Date()
        )
    }
}

extension NewsArticle {
    static func testArticle(
        title: String = "Test Article",
        description: String = "Test description",
        publishedAt: Date = Date()
    ) -> NewsArticle {
        return NewsArticle(
            title: title,
            description: description,
            content: "Test content",
            publishedAt: publishedAt,
            source: NewsSource(name: "Test Source", url: URL(string: "https://test.com")!),
            url: URL(string: "https://test.com/article")
        )
    }
}