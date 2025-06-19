//
//  PoemViewModelTests.swift
//  Poem of the DayTests
//
//  Created by Claude Code on 2025-06-19.
//

import XCTest
@testable import Poem_of_the_Day

@MainActor
final class PoemViewModelTests: XCTestCase {
    var sut: PoemViewModel!
    var mockRepository: MockPoemRepository!
    
    override func setUp() async throws {
        mockRepository = MockPoemRepository()
        sut = PoemViewModel(repository: mockRepository)
    }
    
    override func tearDown() {
        sut = nil
        mockRepository = nil
    }
    
    func testLoadInitialData_Success() async {
        // Given
        let expectedPoem = Poem(title: "Test Poem", lines: ["Test content"], author: "Test Author")
        let expectedFavorites = [Poem(title: "Favorite", lines: ["Favorite content"], author: "Favorite Author")]
        
        mockRepository.mockDailyPoem = expectedPoem
        mockRepository.mockFavorites = expectedFavorites
        
        // When
        await sut.loadInitialData()
        
        // Then
        XCTAssertEqual(sut.poemOfTheDay?.title, expectedPoem.title)
        XCTAssertEqual(sut.favorites.count, 1)
        XCTAssertFalse(sut.isLoading)
        XCTAssertNil(sut.errorMessage)
    }
    
    func testLoadInitialData_Error() async {
        // Given
        mockRepository.mockError = PoemError.networkUnavailable
        
        // When
        await sut.loadInitialData()
        
        // Then
        XCTAssertNil(sut.poemOfTheDay)
        XCTAssertFalse(sut.isLoading)
        XCTAssertNotNil(sut.errorMessage)
        XCTAssertTrue(sut.showErrorAlert)
    }
    
    func testRefreshPoem_Success() async {
        // Given
        let refreshedPoem = Poem(title: "Refreshed Poem", lines: ["Refreshed content"], author: "Refreshed Author")
        mockRepository.mockRefreshedPoem = refreshedPoem
        
        // When
        await sut.refreshPoem()
        
        // Then
        XCTAssertEqual(sut.poemOfTheDay?.title, refreshedPoem.title)
        XCTAssertFalse(sut.isLoading)
        XCTAssertTrue(mockRepository.refreshDailyPoemCalled)
    }
    
    func testRefreshPoem_Error() async {
        // Given
        mockRepository.mockRefreshError = PoemError.rateLimited
        
        // When
        await sut.refreshPoem()
        
        // Then
        XCTAssertNil(sut.poemOfTheDay)
        XCTAssertFalse(sut.isLoading)
        XCTAssertNotNil(sut.errorMessage)
        XCTAssertTrue(sut.showErrorAlert)
    }
    
    func testToggleFavorite_AddToFavorites() async {
        // Given
        let poem = Poem(title: "Test Poem", lines: ["Test content"], author: "Test Author")
        mockRepository.mockFavorites = []
        
        // When
        await sut.toggleFavorite(poem: poem)
        
        // Then
        XCTAssertTrue(mockRepository.addToFavoritesCalled)
        XCTAssertFalse(mockRepository.removeFromFavoritesCalled)
    }
    
    func testToggleFavorite_RemoveFromFavorites() async {
        // Given
        let poem = Poem(title: "Test Poem", lines: ["Test content"], author: "Test Author")
        mockRepository.mockIsFavorite = true
        
        // When
        await sut.toggleFavorite(poem: poem)
        
        // Then
        XCTAssertTrue(mockRepository.removeFromFavoritesCalled)
        XCTAssertFalse(mockRepository.addToFavoritesCalled)
    }
    
    func testIsFavorite_ReturnsCorrectStatus() {
        // Given
        let favoritePoem = Poem(title: "Favorite", lines: ["Content"], author: "Author")
        let regularPoem = Poem(title: "Regular", lines: ["Content"], author: "Author")
        
        sut.favorites = [favoritePoem]
        
        // When & Then
        XCTAssertTrue(sut.isFavorite(poem: favoritePoem))
        XCTAssertFalse(sut.isFavorite(poem: regularPoem))
    }
}

// MARK: - Mock Repository

final class MockPoemRepository: PoemRepositoryProtocol {
    var mockDailyPoem: Poem?
    var mockRefreshedPoem: Poem?
    var mockFavorites: [Poem] = []
    var mockError: Error?
    var mockRefreshError: Error?
    var mockIsFavorite = false
    
    var getDailyPoemCalled = false
    var refreshDailyPoemCalled = false
    var addToFavoritesCalled = false
    var removeFromFavoritesCalled = false
    
    func getDailyPoem() async throws -> Poem {
        getDailyPoemCalled = true
        
        if let error = mockError {
            throw error
        }
        
        guard let poem = mockDailyPoem else {
            throw PoemError.noPoems
        }
        
        return poem
    }
    
    func refreshDailyPoem() async throws -> Poem {
        refreshDailyPoemCalled = true
        
        if let error = mockRefreshError {
            throw error
        }
        
        guard let poem = mockRefreshedPoem else {
            throw PoemError.noPoems
        }
        
        return poem
    }
    
    func getFavorites() async -> [Poem] {
        return mockFavorites
    }
    
    func addToFavorites(_ poem: Poem) async {
        addToFavoritesCalled = true
        mockFavorites.append(poem)
    }
    
    func removeFromFavorites(_ poem: Poem) async {
        removeFromFavoritesCalled = true
        mockFavorites.removeAll { $0.id == poem.id }
    }
    
    func isFavorite(_ poem: Poem) async -> Bool {
        return mockIsFavorite
    }
}
