//
//  PoemRepositoryTests.swift
//  Poem of the DayTests
//
//  Created by Claude Code on 2025-06-19.
//

import XCTest
@testable import Poem_of_the_Day

final class PoemRepositoryTests: XCTestCase {
    var sut: PoemRepository!
    var mockNetworkService: MockNetworkService!
    var mockAIService: MockPoemGenerationService!
    var mockUserDefaults: UserDefaults!
    
    override func setUp() async throws {
        mockNetworkService = MockNetworkService()
        mockAIService = MockPoemGenerationService()
        mockUserDefaults = UserDefaults(suiteName: "test.poem.repository")!
        sut = PoemRepository(networkService: mockNetworkService, aiService: mockAIService, userDefaults: mockUserDefaults)
    }
    
    override func tearDown() async throws {
        mockUserDefaults.removePersistentDomain(forName: "test.poem.repository")
        sut = nil
        mockNetworkService = nil
        mockAIService = nil
        mockUserDefaults = nil
    }
    
    func testGetDailyPoem_ShouldFetchWhenNoCache() async throws {
        // Given
        let expectedPoem = Poem(title: "Test Poem", lines: ["Line 1"], author: "Test Author")
        mockNetworkService.mockPoem = expectedPoem
        
        // When
        let poem = try await sut.getDailyPoem()
        
        // Then
        XCTAssertEqual(poem.title, expectedPoem.title)
        XCTAssertTrue(mockNetworkService.fetchRandomPoemCalled)
    }
    
    func testGetDailyPoem_ShouldReturnCachedWhenSameDay() async throws {
        // Given
        let cachedPoem = Poem(title: "Cached Poem", lines: ["Cached content"], author: "Cached Author")
        mockUserDefaults.set(cachedPoem.title, forKey: "poemTitle")
        mockUserDefaults.set(cachedPoem.content, forKey: "poemContent")
        mockUserDefaults.set(cachedPoem.author, forKey: "poemAuthor")
        mockUserDefaults.set(Date(), forKey: "lastPoemFetchDate")
        
        // When
        let poem = try await sut.getDailyPoem()
        
        // Then
        XCTAssertEqual(poem.title, cachedPoem.title)
        XCTAssertFalse(mockNetworkService.fetchRandomPoemCalled)
    }
    
    func testGetDailyPoem_ShouldFetchWhenNewDay() async throws {
        // Given
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        mockUserDefaults.set("Old Poem", forKey: "poemTitle")
        mockUserDefaults.set("Old content", forKey: "poemContent")
        mockUserDefaults.set("Old Author", forKey: "poemAuthor")
        mockUserDefaults.set(yesterday, forKey: "lastPoemFetchDate")
        
        let newPoem = Poem(title: "New Poem", lines: ["New content"], author: "New Author")
        mockNetworkService.mockPoem = newPoem
        
        // When
        let poem = try await sut.getDailyPoem()
        
        // Then
        XCTAssertEqual(poem.title, newPoem.title)
        XCTAssertTrue(mockNetworkService.fetchRandomPoemCalled)
    }
    
    func testRefreshDailyPoem_ShouldAlwaysFetch() async throws {
        // Given
        let newPoem = Poem(title: "Fresh Poem", lines: ["Fresh content"], author: "Fresh Author")
        mockNetworkService.mockPoem = newPoem
        
        // When
        let poem = try await sut.refreshDailyPoem()
        
        // Then
        XCTAssertEqual(poem.title, newPoem.title)
        XCTAssertTrue(mockNetworkService.fetchRandomPoemCalled)
    }
    
    func testAddToFavorites_ShouldAddPoem() async {
        // Given
        let poem = Poem(title: "Favorite Poem", lines: ["Great content"], author: "Great Author")
        
        // When
        await sut.addToFavorites(poem)
        let favorites = await sut.getFavorites()
        
        // Then
        XCTAssertEqual(favorites.count, 1)
        XCTAssertEqual(favorites.first?.title, poem.title)
    }
    
    func testAddToFavorites_ShouldNotAddDuplicate() async {
        // Given
        let poem = Poem(title: "Favorite Poem", lines: ["Great content"], author: "Great Author")
        
        // When
        await sut.addToFavorites(poem)
        await sut.addToFavorites(poem) // Add same poem twice
        let favorites = await sut.getFavorites()
        
        // Then
        XCTAssertEqual(favorites.count, 1)
    }
    
    func testRemoveFromFavorites_ShouldRemovePoem() async {
        // Given
        let poem = Poem(title: "Favorite Poem", lines: ["Great content"], author: "Great Author")
        await sut.addToFavorites(poem)
        
        // When
        await sut.removeFromFavorites(poem)
        let favorites = await sut.getFavorites()
        
        // Then
        XCTAssertTrue(favorites.isEmpty)
    }
    
    func testIsFavorite_ShouldReturnCorrectStatus() async {
        // Given
        let poem = Poem(title: "Favorite Poem", lines: ["Great content"], author: "Great Author")
        let otherPoem = Poem(title: "Other Poem", lines: ["Other content"], author: "Other Author")
        
        await sut.addToFavorites(poem)
        
        // When & Then
        let isFavorite = await sut.isFavorite(poem)
        let isNotFavorite = await sut.isFavorite(otherPoem)
        
        XCTAssertTrue(isFavorite)
        XCTAssertFalse(isNotFavorite)
    }
    
    func testGenerateAIPoem_WithTheme_ReturnsAIPoem() async throws {
        // Given
        let theme = PoemTheme.nature
        let expectedPoem = Poem(title: "AI Nature Poem", lines: ["AI generated content"], author: "Mock AI", source: .aiGenerated)
        mockAIService.mockPoem = expectedPoem
        
        // When
        let poem = try await sut.generateAIPoem(theme: theme)
        
        // Then
        XCTAssertEqual(poem.title, expectedPoem.title)
        XCTAssertEqual(poem.source, .aiGenerated)
    }
    
    func testGenerateAIPoem_WithoutTheme_ReturnsRandomAIPoem() async throws {
        // Given
        let expectedPoem = Poem(title: "Random AI Poem", lines: ["Random AI content"], author: "Mock AI", source: .aiGenerated)
        mockAIService.mockPoem = expectedPoem
        
        // When
        let poem = try await sut.generateAIPoem(theme: nil)
        
        // Then
        XCTAssertNotNil(poem)
        XCTAssertEqual(poem.source, .aiGenerated)
    }
    
    func testIsAIGenerationAvailable_ReturnsCorrectStatus() async {
        // Given
        mockAIService.mockAvailable = true
        
        // When
        let isAvailable = await sut.isAIGenerationAvailable()
        
        // Then
        XCTAssertTrue(isAvailable)
        
        // Given
        mockAIService.mockAvailable = false
        
        // When
        let isNotAvailable = await sut.isAIGenerationAvailable()
        
        // Then
        XCTAssertFalse(isNotAvailable)
    }
}

// MARK: - Enhanced Mock AI Service

extension MockPoemGenerationService {
    var mockPoem: Poem? {
        get { nil }
        set {
            // Store the mock poem for generation
            if let poem = newValue {
                mockError = nil
            }
        }
    }
}

// MARK: - Mock Network Service

final class MockNetworkService: NetworkServiceProtocol {
    var mockPoem: Poem?
    var mockError: Error?
    var fetchRandomPoemCalled = false
    
    func fetchRandomPoem() async throws -> Poem {
        fetchRandomPoemCalled = true
        
        if let error = mockError {
            throw error
        }
        
        guard let poem = mockPoem else {
            throw PoemError.noPoems
        }
        
        return poem
    }
}