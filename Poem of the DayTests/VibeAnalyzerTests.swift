//
//  VibeAnalyzerTests.swift
//  Poem of the DayTests
//
//  Created by Claude Code on 2025-06-19.
//

import XCTest
@testable import Poem_of_the_Day

final class VibeAnalyzerTests: XCTestCase {
    var sut: VibeAnalyzer!
    
    override func setUp() {
        sut = VibeAnalyzer()
    }
    
    override func tearDown() {
        sut = nil
    }
    
    func testAnalyzeVibe_WithHopefulNews_ReturnsHopefulVibe() async {
        // Given
        let hopefulArticles = [
            NewsArticle(
                title: "Scientists Discover Breakthrough in Renewable Energy",
                description: "Major breakthrough promises bright future for clean energy",
                content: "This discovery brings hope and progress to our fight against climate change",
                publishedAt: Date(),
                source: NewsSource(name: "Science News", id: "science"),
                url: nil
            ),
            NewsArticle(
                title: "Community Initiative Brings Positive Change",
                description: "Local community achieves success in neighborhood improvement",
                content: "The project shows promising results and bright opportunities ahead",
                publishedAt: Date(),
                source: NewsSource(name: "Local News", id: "local"),
                url: nil
            )
        ]
        
        // When
        let analysis = await sut.analyzeVibe(from: hopefulArticles)
        
        // Then
        XCTAssertEqual(analysis.vibe, .hopeful)
        XCTAssertGreaterThan(analysis.confidence, 0.0)
        XCTAssertFalse(analysis.reasoning.isEmpty)
        XCTAssertFalse(analysis.keywords.isEmpty)
        XCTAssertGreaterThan(analysis.sentiment.positivity, 0.5)
    }
    
    func testAnalyzeVibe_WithMelancholicNews_ReturnsMelancholicVibe() async {
        // Given
        let melancholicArticles = [
            NewsArticle(
                title: "Memorial Service for Beloved Community Leader",
                description: "Community mourns the loss of influential figure",
                content: "Residents remember with sadness and grief the departed leader who brought so much to our community",
                publishedAt: Date(),
                source: NewsSource(name: "Local News", id: "local"),
                url: nil
            ),
            NewsArticle(
                title: "End of an Era as Historic Building Closes",
                description: "Nostalgia fills the air as landmark says farewell",
                content: "The closure brings feelings of loss and longing for the past memories created here",
                publishedAt: Date(),
                source: NewsSource(name: "Heritage News", id: "heritage"),
                url: nil
            )
        ]
        
        // When
        let analysis = await sut.analyzeVibe(from: melancholicArticles)
        
        // Then
        XCTAssertEqual(analysis.vibe, .melancholic)
        XCTAssertGreaterThan(analysis.confidence, 0.0)
        XCTAssertFalse(analysis.reasoning.isEmpty)
        XCTAssertContains(analysis.keywords, "loss")
        XCTAssertLessThan(analysis.sentiment.positivity, 0.5)
    }
    
    func testAnalyzeVibe_WithEnergeticNews_ReturnsEnergeticVibe() async {
        // Given
        let energeticArticles = [
            NewsArticle(
                title: "Fast-Paced Tech Launch Excites Industry",
                description: "Dynamic startup launches thrilling new platform",
                content: "The rapid development and intense energy around this launch has everyone excited and moving quickly",
                publishedAt: Date(),
                source: NewsSource(name: "Tech News", id: "tech"),
                url: nil
            ),
            NewsArticle(
                title: "High-Energy Sports Tournament Begins",
                description: "Athletes bring powerful performances to championship",
                content: "The vibrant competition and dynamic action creates an atmosphere of intense excitement",
                publishedAt: Date(),
                source: NewsSource(name: "Sports News", id: "sports"),
                url: nil
            )
        ]
        
        // When
        let analysis = await sut.analyzeVibe(from: energeticArticles)
        
        // Then
        XCTAssertEqual(analysis.vibe, .energetic)
        XCTAssertGreaterThan(analysis.confidence, 0.0)
        XCTAssertGreaterThan(analysis.sentiment.energy, 0.5)
    }
    
    func testAnalyzeVibe_WithEmptyArticles_ReturnsDefaultVibe() async {
        // Given
        let emptyArticles: [NewsArticle] = []
        
        // When
        let analysis = await sut.analyzeVibe(from: emptyArticles)
        
        // Then
        XCTAssertEqual(analysis.vibe, .contemplative) // Default vibe
        XCTAssertEqual(analysis.confidence, 0.0)
    }
    
    func testAnalyzeVibe_WithMixedSentiment_CalculatesCorrectScores() async {
        // Given
        let mixedArticles = [
            NewsArticle(
                title: "Study Reveals Complex Research Findings",
                description: "Analysis shows both positive and negative aspects",
                content: "The research examination reveals thoughtful insights into both good and bad outcomes",
                publishedAt: Date(),
                source: NewsSource(name: "Research News", id: "research"),
                url: nil
            )
        ]
        
        // When
        let analysis = await sut.analyzeVibe(from: mixedArticles)
        
        // Then
        XCTAssertGreaterThan(analysis.sentiment.complexity, 0.3)
        XCTAssertGreaterThan(analysis.confidence, 0.0)
        XCTAssertNotNil(analysis.reasoning)
    }
    
    func testSentimentScore_InitializesWithValidRanges() {
        // Given & When
        let sentiment = SentimentScore(positivity: -0.5, energy: 1.5, complexity: 0.5)
        
        // Then
        XCTAssertEqual(sentiment.positivity, 0.0) // Clamped to 0.0
        XCTAssertEqual(sentiment.energy, 1.0) // Clamped to 1.0
        XCTAssertEqual(sentiment.complexity, 0.5) // Within range
    }
    
    func testVibeAnalysis_InitializesCorrectly() {
        // Given
        let vibe = DailyVibe.hopeful
        let confidence = 0.8
        let reasoning = "Test reasoning"
        let keywords = ["test", "keywords"]
        let sentiment = SentimentScore(positivity: 0.7, energy: 0.6, complexity: 0.5)
        
        // When
        let analysis = VibeAnalysis(
            vibe: vibe,
            confidence: confidence,
            reasoning: reasoning,
            keywords: keywords,
            sentiment: sentiment
        )
        
        // Then
        XCTAssertEqual(analysis.vibe, vibe)
        XCTAssertEqual(analysis.confidence, confidence)
        XCTAssertEqual(analysis.reasoning, reasoning)
        XCTAssertEqual(analysis.keywords, keywords)
        XCTAssertEqual(analysis.sentiment.positivity, sentiment.positivity)
        XCTAssertNotNil(analysis.analysisDate)
    }
}

// MARK: - Helper Extensions

extension XCTestCase {
    func XCTAssertContains<T: Equatable>(_ collection: [T], _ element: T, _ message: String = "", file: StaticString = #file, line: UInt = #line) {
        XCTAssertTrue(collection.contains(element), message.isEmpty ? "Collection does not contain \\(element)" : message, file: file, line: line)
    }
}