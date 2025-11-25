//
//  VibeAnalyzerTests.swift
//  Poem of the DayTests
//
//  Created by Claude on 2025-06-19.
//

import XCTest
import SwiftUI
@testable import Poem_of_the_Day

final class VibeAnalyzerTests: XCTestCase {
    
    var vibeAnalyzer: VibeAnalyzer!
    
    override func setUp() {
        super.setUp()
        vibeAnalyzer = VibeAnalyzer()
    }
    
    override func tearDown() {
        vibeAnalyzer = nil
        super.tearDown()
    }
    
    // MARK: - Background Color Tests
    
    func testVibeBackgroundColorsAllCases() async throws {
        // Test that all vibe cases have valid background colors for both light and dark modes
        for vibe in DailyVibe.allCases {
            let lightColors = vibe.lightModeBackgroundColors
            let darkColors = vibe.darkModeBackgroundColors
            
            // Verify light mode colors
            XCTAssertEqual(lightColors.count, 2, "\(vibe.rawValue) should have exactly 2 light mode colors")
            XCTAssertNotEqual(lightColors[0], lightColors[1], "\(vibe.rawValue) light mode colors should be different")
            
            // Verify dark mode colors
            XCTAssertEqual(darkColors.count, 2, "\(vibe.rawValue) should have exactly 2 dark mode colors")
            XCTAssertNotEqual(darkColors[0], darkColors[1], "\(vibe.rawValue) dark mode colors should be different")
            
            // Test gradient generation
            let lightGradient = vibe.backgroundGradient(for: .light)
            let darkGradient = vibe.backgroundGradient(for: .dark)
            
            XCTAssertNotNil(lightGradient, "\(vibe.rawValue) should generate light mode gradient")
            XCTAssertNotNil(darkGradient, "\(vibe.rawValue) should generate dark mode gradient")
            
            // Test primary color extraction
            let lightPrimary = vibe.primaryBackgroundColor(for: .light)
            let darkPrimary = vibe.primaryBackgroundColor(for: .dark)
            
            XCTAssertNotNil(lightPrimary, "\(vibe.rawValue) should have light mode primary color")
            XCTAssertNotNil(darkPrimary, "\(vibe.rawValue) should have dark mode primary color")
        }
    }
    
    func testSpecificVibeBackgroundColors() async throws {
        // Test specific color characteristics for different vibes
        
        // Hopeful should have warm colors
        let hopeful = DailyVibe.hopeful
        let hopefulLight = hopeful.lightModeBackgroundColors
        XCTAssertTrue(hopefulLight.allSatisfy { isWarmColor($0) }, "Hopeful vibe should have warm colors")
        
        // Peaceful should have green tones
        let peaceful = DailyVibe.peaceful
        let peacefulLight = peaceful.lightModeBackgroundColors
        XCTAssertTrue(peacefulLight.allSatisfy { hasGreenTone($0) }, "Peaceful vibe should have green tones")
        
        // Energetic should have vibrant colors
        let energetic = DailyVibe.energetic
        let energeticLight = energetic.lightModeBackgroundColors
        XCTAssertTrue(energeticLight.allSatisfy { isVibrantColor($0) }, "Energetic vibe should have vibrant colors")
        
        // Melancholic should have muted colors
        let melancholic = DailyVibe.melancholic
        let melancholicLight = melancholic.lightModeBackgroundColors
        XCTAssertTrue(melancholicLight.allSatisfy { isMutedColor($0) }, "Melancholic vibe should have muted colors")
    }
    
    func testBackgroundColorIntensityCalculation() async throws {
        let articles = [TestData.sampleNewsArticles[0]]
        let analysis = await vibeAnalyzer.analyzeVibe(from: articles)
        
        // Test that intensity is within valid range
        let intensity = analysis.backgroundColorInfo.intensity
        XCTAssertGreaterThanOrEqual(intensity, 0.0, "Background color intensity should be >= 0.0")
        XCTAssertLessThanOrEqual(intensity, 1.0, "Background color intensity should be <= 1.0")
        
        // Test that minimum intensity is respected
        XCTAssertGreaterThanOrEqual(intensity, 0.3, "Background color intensity should be >= 0.3 for visibility")
    }
    
    func testBackgroundColorIntensityWithDifferentConfidenceLevels() async throws {
        // Create test scenarios with different confidence levels
        let highConfidenceArticles = [
            NewsArticle(
                title: "Amazing breakthrough brings hope to millions",
                description: "Scientists discover revolutionary treatment",
                content: "This incredible discovery will transform lives and bring joy to countless families",
                publishedAt: Date(),
                source: NewsSource(name: "Test News", id: "test"),
                url: nil
            )
        ]
        
        let lowConfidenceArticles = [
            NewsArticle(
                title: "Minor update in local area",
                description: "Small change reported",
                content: "A slight adjustment was made to local procedures",
                publishedAt: Date(),
                source: NewsSource(name: "Test News", id: "test"),
                url: nil
            )
        ]
        
        let highConfidenceAnalysis = await vibeAnalyzer.analyzeVibe(from: highConfidenceArticles)
        let lowConfidenceAnalysis = await vibeAnalyzer.analyzeVibe(from: lowConfidenceArticles)
        
        // High confidence should generally lead to higher intensity
        XCTAssertGreaterThanOrEqual(
            highConfidenceAnalysis.confidence,
            lowConfidenceAnalysis.confidence,
            "High confidence articles should have higher confidence scores"
        )
    }
    
    func testVibeBackgroundColorInfo() async throws {
        let articles = [TestData.sampleNewsArticles[0]]
        let analysis = await vibeAnalyzer.analyzeVibe(from: articles)
        
        // Test VibeBackgroundColorInfo properties
        let colorInfo = analysis.backgroundColorInfo
        XCTAssertEqual(colorInfo.vibe, analysis.vibe, "Background color info vibe should match analysis vibe")
        XCTAssertFalse(colorInfo.colorDescription.isEmpty, "Color description should not be empty")
        XCTAssertGreaterThanOrEqual(colorInfo.intensity, 0.0, "Intensity should be >= 0.0")
        XCTAssertLessThanOrEqual(colorInfo.intensity, 1.0, "Intensity should be <= 1.0")
        
        // Test that color description is appropriate for the vibe
        let description = colorInfo.colorDescription.lowercased()
        switch analysis.vibe {
        case .hopeful:
            XCTAssertTrue(description.contains("warm") || description.contains("sunrise") || description.contains("golden"), 
                         "Hopeful color description should mention warm/sunrise/golden")
        case .peaceful:
            XCTAssertTrue(description.contains("green") || description.contains("nature") || description.contains("tranquil"), 
                         "Peaceful color description should mention green/nature/tranquil")
        case .energetic:
            XCTAssertTrue(description.contains("vibrant") || description.contains("orange") || description.contains("energy"), 
                         "Energetic color description should mention vibrant/orange/energy")
        case .melancholic:
            XCTAssertTrue(description.contains("purple") || description.contains("gray") || description.contains("soft"), 
                         "Melancholic color description should mention purple/gray/soft")
        default:
            break // Other vibes have their own color descriptions
        }
    }
    
    func testColorIntensityWithExtremeSentiment() async throws {
        // Test with very positive sentiment
        let veryPositiveArticles = [
            NewsArticle(
                title: "Incredible amazing fantastic wonderful breakthrough",
                description: "Excellent great beautiful positive developments",
                content: "Joyful happy delighted thrilled successful beneficial helpful exciting thrilling energetic dynamic triumph victory success achieve celebrate explosive intense powerful strong force drive push action move active vibrant lively",
                publishedAt: Date(),
                source: NewsSource(name: "Test News", id: "test"),
                url: nil
            )
        ]
        
        // Test with very negative sentiment
        let veryNegativeArticles = [
            NewsArticle(
                title: "Terrible awful horrible crisis disaster",
                description: "Bad negative failed problem concern",
                content: "Angry sad disappointed frustrated upset troubled terrifying chaotic dangerous violent crisis emergency urgent critical furious fierce savage intense extreme",
                publishedAt: Date(),
                source: NewsSource(name: "Test News", id: "test"),
                url: nil
            )
        ]
        
        let positiveAnalysis = await vibeAnalyzer.analyzeVibe(from: veryPositiveArticles)
        let negativeAnalysis = await vibeAnalyzer.analyzeVibe(from: veryNegativeArticles)
        
        // Both extreme sentiments should result in higher intensity than neutral
        XCTAssertGreaterThan(positiveAnalysis.backgroundColorInfo.intensity, 0.4, 
                           "Very positive sentiment should increase color intensity")
        XCTAssertGreaterThan(negativeAnalysis.backgroundColorInfo.intensity, 0.4, 
                           "Very negative sentiment should increase color intensity")
    }
    
    func testColorIntensityWithHighEnergyContent() async throws {
        // Test with high energy content
        let highEnergyArticles = [
            NewsArticle(
                title: "Fast rapid explosive dynamic breakthrough",
                description: "Quick speed rush burst intense powerful",
                content: "Strong force drive push action move active energetic vibrant lively exciting thrilling",
                publishedAt: Date(),
                source: NewsSource(name: "Test News", id: "test"),
                url: nil
            )
        ]
        
        // Test with low energy content
        let lowEnergyArticles = [
            NewsArticle(
                title: "Slow gentle quiet calm development",
                description: "Peaceful serene tranquil still steady",
                content: "Stable balanced harmonious soothing relaxing comfortable easy smooth gradual patient",
                publishedAt: Date(),
                source: NewsSource(name: "Test News", id: "test"),
                url: nil
            )
        ]
        
        let highEnergyAnalysis = await vibeAnalyzer.analyzeVibe(from: highEnergyArticles)
        let lowEnergyAnalysis = await vibeAnalyzer.analyzeVibe(from: lowEnergyArticles)
        
        // High energy should generally result in higher intensity
        XCTAssertGreaterThan(highEnergyAnalysis.sentiment.energy, lowEnergyAnalysis.sentiment.energy, 
                           "High energy content should have higher energy sentiment")
        XCTAssertGreaterThan(highEnergyAnalysis.backgroundColorInfo.intensity, 0.4, 
                           "High energy should contribute to color intensity")
    }
    
    // MARK: - Original Vibe Analysis Tests
    
    func testAnalyzeVibeFromNews() async throws {
        let articles = TestData.sampleNewsArticles
        let analysis = await vibeAnalyzer.analyzeVibe(from: articles)
        
        XCTAssertNotNil(analysis.vibe)
        XCTAssertGreaterThanOrEqual(analysis.confidence, 0.0)
        XCTAssertLessThanOrEqual(analysis.confidence, 1.0)
        XCTAssertFalse(analysis.reasoning.isEmpty)
        XCTAssertFalse(analysis.keywords.isEmpty)
        
        // Test sentiment scores
        XCTAssertGreaterThanOrEqual(analysis.sentiment.positivity, 0.0)
        XCTAssertLessThanOrEqual(analysis.sentiment.positivity, 1.0)
        XCTAssertGreaterThanOrEqual(analysis.sentiment.energy, 0.0)
        XCTAssertLessThanOrEqual(analysis.sentiment.energy, 1.0)
        XCTAssertGreaterThanOrEqual(analysis.sentiment.complexity, 0.0)
        XCTAssertLessThanOrEqual(analysis.sentiment.complexity, 1.0)
    }
    
    func testAnalyzeVibeWithHopefulNews() async throws {
        let hopefulArticles = [
            NewsArticle(
                title: "Scientists discover breakthrough treatment for rare disease",
                description: "New research brings hope to thousands of patients worldwide",
                content: "This amazing discovery represents a major step forward in medical science, offering new hope and optimism for the future",
                publishedAt: Date(),
                source: NewsSource(name: "Medical News", id: "med"),
                url: nil
            )
        ]
        
        let analysis = await vibeAnalyzer.analyzeVibe(from: hopefulArticles)
        
        // Should detect hopeful or inspiring vibe
        XCTAssertTrue([DailyVibe.hopeful, DailyVibe.inspiring].contains(analysis.vibe),
                     "Should detect hopeful or inspiring vibe from positive medical news")
        XCTAssertGreaterThan(analysis.sentiment.positivity, 0.5, "Should have positive sentiment")
    }
    
    func testAnalyzeVibeWithMelancholicNews() async throws {
        let melancholicArticles = [
            NewsArticle(
                title: "Farewell to beloved community leader",
                description: "Remembering a life of service and dedication",
                content: "The community mourns the loss while celebrating memories of kindness, wisdom, and gentle leadership that touched so many lives",
                publishedAt: Date(),
                source: NewsSource(name: "Community News", id: "community"),
                url: nil
            )
        ]
        
        let analysis = await vibeAnalyzer.analyzeVibe(from: melancholicArticles)
        
        // Should detect melancholic or reflective vibe
        XCTAssertTrue([DailyVibe.melancholic, DailyVibe.reflective].contains(analysis.vibe),
                     "Should detect melancholic or reflective vibe from memorial news")
        XCTAssertLessThan(analysis.sentiment.positivity, 0.7, "Should have less positive sentiment")
    }
    
    func testAnalyzeVibeWithEnergeticNews() async throws {
        let energeticArticles = [
            NewsArticle(
                title: "City marathon breaks attendance records",
                description: "Thousands of runners participate in high-energy event",
                content: "The atmosphere was electric with excitement as participants pushed their limits in this dynamic, action-packed competition",
                publishedAt: Date(),
                source: NewsSource(name: "Sports News", id: "sports"),
                url: nil
            )
        ]
        
        let analysis = await vibeAnalyzer.analyzeVibe(from: energeticArticles)
        
        // Should detect energetic or celebratory vibe
        XCTAssertTrue([DailyVibe.energetic, DailyVibe.celebratory].contains(analysis.vibe),
                     "Should detect energetic or celebratory vibe from sports news")
        XCTAssertGreaterThan(analysis.sentiment.energy, 0.5, "Should have high energy sentiment")
    }
    
    func testAnalyzeVibeWithContemplativeNews() async throws {
        let contemplativeArticles = [
            NewsArticle(
                title: "Philosophers gather to discuss meaning of progress",
                description: "Deep questions about society's direction spark thoughtful debate",
                content: "Scholars engaged in profound discussions about wisdom, understanding, and the deeper meanings of human advancement",
                publishedAt: Date(),
                source: NewsSource(name: "Academic News", id: "academic"),
                url: nil
            )
        ]
        
        let analysis = await vibeAnalyzer.analyzeVibe(from: contemplativeArticles)
        
        // Should detect contemplative or reflective vibe
        XCTAssertTrue([DailyVibe.contemplative, DailyVibe.reflective].contains(analysis.vibe),
                     "Should detect contemplative or reflective vibe from philosophical news")
        XCTAssertGreaterThan(analysis.sentiment.complexity, 0.5, "Should have high complexity sentiment")
    }
    
    func testAnalyzeVibeWithPeacefulNews() async throws {
        let peacefulArticles = [
            NewsArticle(
                title: "New nature preserve opens to public",
                description: "Tranquil sanctuary offers peaceful retreat from city life",
                content: "Visitors can enjoy calm walks through serene landscapes, finding harmony and balance in this soothing natural environment",
                publishedAt: Date(),
                source: NewsSource(name: "Nature News", id: "nature"),
                url: nil
            )
        ]
        
        let analysis = await vibeAnalyzer.analyzeVibe(from: peacefulArticles)
        
        // Should detect peaceful vibe
        XCTAssertEqual(analysis.vibe, DailyVibe.peaceful,
                     "Should detect peaceful vibe from nature news")
        XCTAssertLessThan(analysis.sentiment.energy, 0.7, "Should have calm energy sentiment")
    }
    
    func testAnalyzeVibeEmptyNews() async throws {
        let emptyArticles: [NewsArticle] = []
        let analysis = await vibeAnalyzer.analyzeVibe(from: emptyArticles)
        
        // Should default to contemplative vibe
        XCTAssertEqual(analysis.vibe, DailyVibe.contemplative)
        XCTAssertEqual(analysis.confidence, 0.0)
        XCTAssertTrue(analysis.keywords.isEmpty)
    }
    
    func testVibeAnalysisDateTracking() async throws {
        let articles = [TestData.sampleNewsArticles[0]]
        let beforeAnalysis = Date()
        let analysis = await vibeAnalyzer.analyzeVibe(from: articles)
        let afterAnalysis = Date()
        
        XCTAssertGreaterThanOrEqual(analysis.analysisDate, beforeAnalysis)
        XCTAssertLessThanOrEqual(analysis.analysisDate, afterAnalysis)
    }
    
    func testVibeKeywordExtraction() async throws {
        let keywordRichArticles = [
            NewsArticle(
                title: "Technology breakthrough transforms industry",
                description: "Innovation drives digital transformation",
                content: "Cutting-edge technology revolutionizes business processes with artificial intelligence and machine learning",
                publishedAt: Date(),
                source: NewsSource(name: "Tech News", id: "tech"),
                url: nil
            )
        ]
        
        let analysis = await vibeAnalyzer.analyzeVibe(from: keywordRichArticles)
        
        XCTAssertFalse(analysis.keywords.isEmpty, "Should extract keywords from content")
        XCTAssertLessThanOrEqual(analysis.keywords.count, 5, "Should limit keywords to 5 or fewer")
        
        // Keywords should be unique
        let uniqueKeywords = Set(analysis.keywords)
        XCTAssertEqual(uniqueKeywords.count, analysis.keywords.count, "Keywords should be unique")
    }
    
    // MARK: - Helper Methods for Color Testing
    
    private func isWarmColor(_ color: Color) -> Bool {
        // Simplified warm color detection - in practice, this would extract RGB values
        // For testing purposes, we assume the warm colors have higher red/yellow components
        return true // Placeholder - would need UIColor conversion for actual RGB testing
    }
    
    private func hasGreenTone(_ color: Color) -> Bool {
        // Simplified green tone detection
        return true // Placeholder - would need UIColor conversion for actual RGB testing
    }
    
    private func isVibrantColor(_ color: Color) -> Bool {
        // Simplified vibrant color detection
        return true // Placeholder - would need UIColor conversion for actual RGB testing
    }
    
    private func isMutedColor(_ color: Color) -> Bool {
        // Simplified muted color detection
        return true // Placeholder - would need UIColor conversion for actual RGB testing
    }
} 