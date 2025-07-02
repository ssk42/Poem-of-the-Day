import Foundation
@testable import Poem_of_the_Day

// MARK: - Test Data Factory

struct TestData {
    
    // MARK: - Sample Poems
    
    static let samplePoem = Poem(
        title: "The Road Not Taken",
        lines: [
            "Two roads diverged in a yellow wood,",
            "And sorry I could not travel both",
            "And be one traveler, long I stood",
            "And looked down one as far as I could",
            "To where it bent in the undergrowth;"
        ],
        author: "Robert Frost"
    )
    
    static let vibePoem = Poem(
        title: "Digital Dreams",
        lines: [
            "In circuits bright and screens aglow,",
            "Where data streams and algorithms flow,",
            "We find our hearts in silicon,",
            "A future built, never undone."
        ],
        author: "AI Poet",
        vibe: .hopeful
    )
    
    static let shortPoem = Poem(
        title: "Haiku",
        lines: [
            "Morning dew glistens",
            "On petals soft and tender",
            "Nature's gentle kiss"
        ],
        author: "Anonymous"
    )
    
    static let longPoem = Poem(
        title: "The Journey",
        lines: [
            "Life is but a winding path",
            "Through valleys deep and mountains high",
            "We walk with hope, we walk with faith",
            "Beneath the ever-changing sky",
            "Each step we take, each breath we draw",
            "Brings wisdom that we never saw",
            "And in the end, when day is done",
            "We'll see that all our paths were one"
        ],
        author: "Test Author"
    )
    
    static let customPoem = Poem(
        title: "Custom Creation",
        lines: [
            "In response to your prompt:",
            "Words flow like rivers deep,",
            "Through valleys of imagination,",
            "Where thoughts and dreams can leap.",
            "Yet filled with human prayer."
        ],
        author: "AI Generated",
        vibe: .inspiring
    )
    
    static func sampleAIPoem(vibe: DailyVibe) -> Poem {
        let poemContent = generatePoemForVibe(vibe)
        return Poem(
            title: poemContent.title,
            lines: poemContent.lines,
            author: "AI Generated",
            vibe: vibe
        )
    }
    
    static func sampleCustomPoem(prompt: String) -> Poem {
        return Poem(
            title: "Custom Creation",
            lines: [
                "In response to your prompt:",
                "\"\(prompt)\"",
                "I craft these words with care,",
                "A poem born from digital thought,",
                "Yet filled with human prayer."
            ],
            author: "AI Generated",
            vibe: .inspiring
        )
    }
    
    static let samplePoems: [Poem] = [
        samplePoem,
        vibePoem,
        shortPoem,
        longPoem
    ]
    
    // MARK: - Sample News Articles
    
    static let sampleNewsArticles = [
        NewsArticle(
            title: "Scientists Discover New Species of Deep-Sea Creature",
            description: "Researchers have found a previously unknown species in the depths of the Pacific Ocean.",
            content: "In a groundbreaking discovery, marine biologists have identified a new species of deep-sea creature that exhibits unique bioluminescent properties...",
            publishedAt: Date(),
            source: NewsSource(name: "Science Daily", id: "science-daily"),
            url: URL(string: "https://sciencedaily.com/article1")
        ),
        NewsArticle(
            title: "Local Community Comes Together for Charity Drive",
            description: "Neighbors unite to support families in need during the holiday season.",
            content: "The annual charity drive organized by the local community center has exceeded all expectations this year...",
            publishedAt: Date().addingTimeInterval(-3600),
            source: NewsSource(name: "Community News", id: "community-news"),
            url: URL(string: "https://community.news/article2")
        ),
        NewsArticle(
            title: "Breakthrough in Renewable Energy Technology",
            description: "New solar panel design achieves record efficiency rates.",
            content: "Engineers at the University of Technology have developed a revolutionary solar panel design that achieves unprecedented efficiency rates...",
            publishedAt: Date().addingTimeInterval(-7200),
            source: NewsSource(name: "Tech World", id: "tech-world"),
            url: URL(string: "https://techworld.com/article3")
        )
    ]
    
    // MARK: - Sample Vibe Analysis
    
    static let sampleVibeAnalysis = VibeAnalysis(
        vibe: .hopeful,
        confidence: 0.85,
        reasoning: "The overall tone of today's news reflects positive developments in science and community cooperation.",
        keywords: ["discovery", "cooperation", "breakthrough", "community"],
        sentiment: SentimentScore(positivity: 0.8, energy: 0.7, complexity: 0.5)
    )
    
    static let differentVibeAnalyses = [
        VibeAnalysis(
            vibe: .reflective,
            confidence: 0.75,
            reasoning: "Today's events encourage introspection and thoughtful consideration.",
            keywords: ["contemplation", "reflection", "thoughtful"],
            sentiment: SentimentScore(positivity: 0.6, energy: 0.4, complexity: 0.8)
        ),
        VibeAnalysis(
            vibe: .energetic,
            confidence: 0.9,
            reasoning: "High-energy events and positive developments dominate the news cycle.",
            keywords: ["energy", "action", "dynamic", "progress"],
            sentiment: SentimentScore(positivity: 0.9, energy: 0.95, complexity: 0.4)
        ),
        VibeAnalysis(
            vibe: .melancholic,
            confidence: 0.7,
            reasoning: "Somber themes and reflective content characterize today's atmosphere.",
            keywords: ["loss", "reflection", "memory", "change"],
            sentiment: SentimentScore(positivity: 0.3, energy: 0.2, complexity: 0.9)
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
        case .hopeful:
            return (
                title: "Digital Dreams",
                lines: [
                    "In circuits bright and screens aglow,",
                    "Where data streams and algorithms flow,",
                    "We find our hearts in silicon,",
                    "A future built, never undone."
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
            lines: lines,
            author: author,
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
            sentiment: SentimentScore(positivity: 0.7, energy: 0.6, complexity: 0.5)
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
            source: NewsSource(name: "Test Source", id: "test-source"),
            url: URL(string: "https://test.com/article")
        )
    }
}