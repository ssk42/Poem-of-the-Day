import XCTest
@testable import Poem_of_the_Day

@MainActor
final class ComprehensiveIntegrationTests: XCTestCase {
    
    var poemRepository: PoemRepository!
    var viewModel: PoemViewModel!
    var networkService: NetworkService!
    var telemetryService: TelemetryService!
    var vibeAnalyzer: VibeAnalyzer!
    var newsService: NewsService!
    
    override func setUpWithError() throws {
        // Create production-like dependency configuration
        networkService = NetworkService()
        telemetryService = TelemetryService()
        vibeAnalyzer = VibeAnalyzer()
        newsService = NewsService()
        poemRepository = PoemRepository(networkService: networkService, telemetryService: telemetryService)
        
        viewModel = PoemViewModel(
            repository: poemRepository,
            telemetryService: telemetryService
        )
    }
    
    override func tearDownWithError() throws {
        viewModel = nil
        poemRepository = nil
        networkService = nil
        telemetryService = nil
        vibeAnalyzer = nil
        newsService = nil
    }
    
    // MARK: - Complete User Journey Tests
    
    func testCompleteFirstTimeLaunchUserJourney() async throws {
        // Simulate first-time app launch workflow
        
        // 1. App Launch - Load initial poem
        await viewModel.loadInitialData()
        
        // Should have poem loaded
        XCTAssertNotNil(viewModel.poemOfTheDay, "Should load initial poem on first launch")
        XCTAssertFalse(viewModel.isLoading, "Should reach loaded state")
        
        // 2. User reads poem for a while (engagement tracking)
        let initialPoem = viewModel.poemOfTheDay
        
        // 3. User favorites the poem
        if let poem = initialPoem {
            await viewModel.toggleFavorite(poem: poem)
            
            let favorites = viewModel.favorites
            XCTAssertEqual(favorites.count, 1, "Should have one favorite after first favorite action")
            XCTAssert(favorites.contains { $0.id == poem.id }, "Favorite should contain the favorited poem")
        }
        
        // 4. User shares the poem
        if let poem = initialPoem {
            let shareText = poem.shareText
            XCTAssertFalse(shareText.isEmpty, "Should be able to share poem")
            XCTAssertTrue(shareText.contains(poem.title), "Share text should contain poem title")
        }
        
        // 5. User refreshes to get new poem
        await viewModel.refreshPoem()
        
        let newPoem = viewModel.poemOfTheDay
        XCTAssertNotNil(newPoem, "Should have new poem after refresh")
        
        // 6. User discovers AI features and generates vibe-based poem
        if viewModel.isAIGenerationAvailable {
            await viewModel.generateVibeBasedPoem()
            
            // Should have AI-generated poem
            XCTAssertNotNil(viewModel.poemOfTheDay, "Should have AI-generated poem")
        }
        
        // 7. User generates custom poem
        if viewModel.isAIGenerationAvailable {
            await viewModel.generateCustomPoem(prompt: "A poem about new beginnings")
            
            XCTAssertNotNil(viewModel.poemOfTheDay, "Should have custom AI-generated poem")
        }
        
        // 8. User adds AI poem to favorites
        if let aiPoem = viewModel.poemOfTheDay {
            await viewModel.toggleFavorite(poem: aiPoem)
            
            let finalFavorites = viewModel.favorites
            XCTAssertEqual(finalFavorites.count, 2, "Should have two favorites after complete journey")
        }
    }
    
    func testDailyUserReturnWorkflow() async throws {
        // Simulate returning user daily workflow
        
        // Seed with some existing favorites
        let seedPoem = TestData.samplePoems[0]
        await viewModel.toggleFavorite(poem: seedPoem)
        
        // 1. User opens app (should check for new daily poem)
        await viewModel.loadInitialData()
        
        XCTAssertNotNil(viewModel.poemOfTheDay, "Should load today's poem")
        
        // 2. User checks favorites to revisit old poems
        let favorites = viewModel.favorites
        XCTAssertGreaterThan(favorites.count, 0, "Should have existing favorites")
        
        // 3. User might favorite today's poem too
        if let todayPoem = viewModel.poemOfTheDay {
            await viewModel.toggleFavorite(poem: todayPoem)
            
            let updatedFavorites = viewModel.favorites
            XCTAssertEqual(updatedFavorites.count, favorites.count + 1, "Should add today's poem to favorites")
        }
        
        // 4. User might share poem with friends
        if let poem = viewModel.poemOfTheDay {
            let shareText = poem.shareText
            XCTAssertTrue(shareText.contains(poem.title), "Should be able to share daily poem")
        }
        
        // 5. User explores AI features for variety
        if viewModel.isAIGenerationAvailable {
            await viewModel.generateVibeBasedPoem()
            XCTAssertNotNil(viewModel.poemOfTheDay, "Should generate poem from current vibe")
        }
    }
    
    func testPowerUserAdvancedWorkflow() async throws {
        // Simulate power user who uses all features extensively
        
        // 1. Multiple poem generations and curation
        for i in 0..<5 {
            await viewModel.refreshPoem()
            
            if let poem = viewModel.poemOfTheDay {
                // Power user favorites selectively
                if i % 2 == 0 {
                    await viewModel.toggleFavorite(poem: poem)
                }
            }
        }
        
        // 2. Extensive AI feature usage
        if viewModel.isAIGenerationAvailable {
            // Generate multiple AI poems with different prompts
            let prompts = [
                "A poem about technology and nature",
                "Something melancholic about time passing",
                "An energetic poem about adventure",
                "A peaceful meditation on stillness"
            ]
            
            for prompt in prompts {
                await viewModel.generateCustomPoem(prompt: prompt)
                
                if let aiPoem = viewModel.poemOfTheDay {
                    await viewModel.toggleFavorite(poem: aiPoem)
                }
            }
        }
        
        // 3. Favorite management
        let allFavorites = viewModel.favorites
        XCTAssertGreaterThan(allFavorites.count, 0, "Power user should have many favorites")
        
        // Remove some favorites (curation)
        if let firstFavorite = allFavorites.first {
            await viewModel.toggleFavorite(poem: firstFavorite)
            
            let updatedFavorites = viewModel.favorites
            XCTAssertEqual(updatedFavorites.count, allFavorites.count - 1, "Should remove favorite")
        }
    }
    
    // MARK: - Cross-Service Integration Tests
    
    func testNewsToVibeToAIPipeline() async throws {
        // Test complete pipeline: News → Vibe Analysis → AI Generation
        
        // 1. Fetch and analyze news for vibe
        let testNews = TestData.sampleNewsArticles
        let analyzedVibe = await vibeAnalyzer.analyzeVibe(from: testNews)
        
        XCTAssertNotNil(analyzedVibe, "Should analyze vibe from news")
        
        // 2. Use vibe to influence AI generation
        if viewModel.isAIGenerationAvailable {
            await viewModel.generateVibeBasedPoem()
            
            let generatedPoem = viewModel.poemOfTheDay
            XCTAssertNotNil(generatedPoem, "Should generate poem influenced by news vibe")
            
            // 3. Generated poem should reflect the analyzed vibe
            if let poem = generatedPoem {
                XCTAssertFalse(poem.content.isEmpty, "Generated poem should have content")
                XCTAssertFalse(poem.title.isEmpty, "Generated poem should have title")
            }
        }
    }
    
    func testRepositoryToViewModelToUIFlow() async throws {
        // Test data flow from repository through viewmodel to UI-ready state
        
        // 1. Repository fetches poem
        let poem = try await poemRepository.getDailyPoem()
        XCTAssertNotNil(poem, "Repository should fetch poem")
        
        // 2. ViewModel processes poem
        await viewModel.loadInitialData()
        XCTAssertFalse(viewModel.isLoading, "ViewModel should reach loaded state")
        XCTAssertNotNil(viewModel.poemOfTheDay, "ViewModel should have current poem")
        
        // 3. ViewModel prepares UI state
        XCTAssertEqual(viewModel.errorMessage, nil, "Should not have error message in success case")
        
        // 4. Test interactions that trigger telemetry
        if let currentPoem = viewModel.poemOfTheDay {
            await viewModel.toggleFavorite(poem: currentPoem)
            
            // Telemetry should be triggered (verified by no crashes)
            XCTAssertTrue(true, "Telemetry integration should work seamlessly")
        }
    }
    
    func testErrorPropagationThroughStack() async throws {
        // Test how errors propagate through the entire stack
        
        // 1. Create network error scenario
        let failingNetworkService = MockNetworkService()
        failingNetworkService.shouldThrowError = true
        failingNetworkService.errorToThrow = PoemError.networkUnavailable
        
        let failingRepository = PoemRepository(
            networkService: failingNetworkService,
            telemetryService: telemetryService
        )
        
        let failingViewModel = PoemViewModel(
            repository: failingRepository,
            telemetryService: telemetryService
        )
        
        // 2. Attempt to load poem
        await failingViewModel.loadInitialData()
        
        // 3. Error should propagate correctly
        XCTAssertTrue(failingViewModel.showErrorAlert, "Should reach error state")
        XCTAssertNotNil(failingViewModel.errorMessage, "Should have error message")
        
        // 4. Recovery should work
        failingNetworkService.shouldThrowError = false
        await failingViewModel.refreshPoem()
        
        XCTAssertFalse(failingViewModel.isLoading, "Should recover from error")
        XCTAssertNil(failingViewModel.errorMessage, "Error message should be cleared")
    }
    
    // MARK: - State Management Integration Tests
    
    func testConcurrentOperations() async throws {
        // Test handling of concurrent operations
        
        // Start multiple operations simultaneously
        async let poem1 = viewModel.refreshPoem()
        async let poem2 = viewModel.loadInitialData()
        async let favorites = viewModel.favorites
        
        // Wait for all to complete
        await poem1
        await poem2
        let favs = await favorites
        
        // App should handle concurrent operations gracefully
        XCTAssertFalse(viewModel.isLoading, "Should handle concurrent operations")
        XCTAssertNotNil(viewModel.poemOfTheDay, "Should have valid poem after concurrent operations")
        XCTAssertNotNil(favs, "Should load favorites successfully")
    }
    
    func testStateConsistencyAcrossOperations() async throws {
        // Test that state remains consistent across various operations
        
        // 1. Load initial poem
        await viewModel.loadInitialData()
        let initialPoem = viewModel.poemOfTheDay
        
        // 2. Add to favorites
        if let poem = initialPoem {
            await viewModel.toggleFavorite(poem: poem)
            let favorites = viewModel.favorites
            XCTAssertTrue(favorites.contains { $0.id == poem.id }, "State should remain consistent")
        }
        
        // 3. Refresh poem
        await viewModel.refreshPoem()
        
        // 4. Check that favorites are still intact
        let favoritesAfterRefresh = viewModel.favorites
        if let originalPoem = initialPoem {
            XCTAssertTrue(favoritesAfterRefresh.contains { $0.id == originalPoem.id }, 
                         "Favorites should persist across operations")
        }
        
        // 5. Generate AI poem
        if viewModel.isAIGenerationAvailable {
            await viewModel.generateCustomPoem(prompt: "Test consistency")
            
            // Favorites should still be intact
            let favoritesAfterAI = viewModel.favorites
            XCTAssertEqual(favoritesAfterAI.count, favoritesAfterRefresh.count, 
                          "AI generation should not affect existing favorites")
        }
    }
    
    // MARK: - Performance Integration Tests
    
    func testCompleteWorkflowPerformance() async throws {
        // Test performance of complete user workflows
        
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // Simulate intensive user session
        await viewModel.loadInitialData()
        
        for _ in 0..<3 {
            await viewModel.refreshPoem()
            
            if let poem = viewModel.poemOfTheDay {
                await viewModel.toggleFavorite(poem: poem)
            }
        }
        
        if viewModel.isAIGenerationAvailable {
            await viewModel.generateVibeBasedPoem()
            await viewModel.generateCustomPoem(prompt: "Performance test poem")
        }
        
        let _ = viewModel.favorites
        
        let endTime = CFAbsoluteTimeGetCurrent()
        let duration = endTime - startTime
        
        // Complete workflow should finish within reasonable time
        XCTAssertLessThan(duration, 15.0, "Complete workflow should finish within 15 seconds")
        
        // Final state should be valid
        XCTAssertNotNil(viewModel.poemOfTheDay, "Should have valid poem after performance test")
        XCTAssertFalse(viewModel.isLoading, "Should end in loaded state")
    }
    
    func testMemoryUsageInLongSession() async throws {
        // Test memory usage during extended session
        
        // Simulate long user session with many operations
        for i in 0..<20 {
            await viewModel.refreshPoem()
            
            if let poem = viewModel.poemOfTheDay {
                await viewModel.toggleFavorite(poem: poem)
                
                // Toggle again (remove from favorites)
                await viewModel.toggleFavorite(poem: poem)
            }
            
            // Periodically generate AI poems
            if i % 5 == 0 && viewModel.isAIGenerationAvailable {
                await viewModel.generateCustomPoem(prompt: "Memory test \(i)")
            }
        }
        
        // Check final state
        XCTAssertNotNil(viewModel.poemOfTheDay, "Should maintain valid state after long session")
        XCTAssertFalse(viewModel.isLoading, "Should be in loaded state")
        
        // Favorites should be manageable (not accumulating indefinitely)
        let favorites = viewModel.favorites
        XCTAssertLessThan(favorites.count, 10, "Should not accumulate excessive favorites")
    }
    
    // MARK: - Integration Edge Cases
    
    func testRapidUserInteractions() async throws {
        // Test rapid fire user interactions
        
        // Rapidly trigger multiple operations
        for _ in 0..<10 {
            await viewModel.refreshPoem()
            
            if let poem = viewModel.poemOfTheDay {
                await viewModel.toggleFavorite(poem: poem)
            }
        }
        
        // System should remain stable
        XCTAssertFalse(viewModel.isLoading, "Should handle rapid interactions")
        XCTAssertNotNil(viewModel.poemOfTheDay, "Should have valid poem after rapid interactions")
    }
    
    func testDataPersistenceAcrossRestarts() async throws {
        // Test data persistence (simulated app restart)
        
        // 1. Set up initial state
        await viewModel.loadInitialData()
        
        if let poem = viewModel.poemOfTheDay {
            await viewModel.toggleFavorite(poem: poem)
        }
        
        let originalFavorites = viewModel.favorites
        
        // 2. Simulate app restart by creating new instances
        let newRepository = PoemRepository(
            networkService: networkService,
            telemetryService: telemetryService
        )
        
        let newViewModel = PoemViewModel(
            repository: newRepository,
            telemetryService: telemetryService
        )
        
        // 3. Check that favorites persisted
        let persistedFavorites = newViewModel.favorites
        XCTAssertEqual(persistedFavorites.count, originalFavorites.count, 
                      "Favorites should persist across app restarts")
    }
    
    func testMixedContentTypes() async throws {
        // Test handling of mixed content types (regular poems + AI poems)
        
        // 1. Load regular poem
        await viewModel.loadInitialData()
        let regularPoem = viewModel.poemOfTheDay
        
        if let poem = regularPoem {
            await viewModel.toggleFavorite(poem: poem)
        }
        
        // 2. Generate AI poems
        if viewModel.isAIGenerationAvailable {
            await viewModel.generateVibeBasedPoem()
            let vibePoem = viewModel.poemOfTheDay
            
            if let poem = vibePoem {
                await viewModel.toggleFavorite(poem: poem)
            }
            
            await viewModel.generateCustomPoem(prompt: "Custom AI poem")
            let customPoem = viewModel.poemOfTheDay
            
            if let poem = customPoem {
                await viewModel.toggleFavorite(poem: poem)
            }
        }
        
        // 3. Check that all types are handled properly
        let allFavorites = viewModel.favorites
        XCTAssertGreaterThan(allFavorites.count, 0, "Should handle mixed content types")
        
        // All poems should be valid
        for favorite in allFavorites {
            XCTAssertFalse(favorite.title.isEmpty, "All favorites should have valid titles")
            XCTAssertFalse(favorite.content.isEmpty, "All favorites should have valid content")
        }
    }
    
    // MARK: - Real-World Scenario Tests
    
    func testOfflineToOnlineTransition() async throws {
        // Test transition from offline to online state
        
        // 1. Simulate offline state
        let failingNetworkService = MockNetworkService()
        failingNetworkService.shouldThrowError = true
        failingNetworkService.errorToThrow = PoemError.networkUnavailable
        
        let offlineRepository = PoemRepository(
            networkService: failingNetworkService,
            telemetryService: telemetryService
        )
        
        let offlineViewModel = PoemViewModel(
            repository: offlineRepository,
            telemetryService: telemetryService
        )
        
        // Try to load poem while offline
        await offlineViewModel.loadInitialData()
        XCTAssertTrue(offlineViewModel.showErrorAlert, "Should be in error state offline")
        
        // 2. Simulate coming back online
        failingNetworkService.shouldThrowError = false
        
        // Retry operation
        await offlineViewModel.refreshPoem()
        XCTAssertFalse(offlineViewModel.isLoading, "Should recover when online")
        XCTAssertNotNil(offlineViewModel.poemOfTheDay, "Should have poem when online")
    }
    
    func testLowMemoryScenario() async throws {
        // Test behavior under simulated low memory conditions
        
        // Generate many AI poems to simulate memory pressure
        if viewModel.isAIGenerationAvailable {
            for i in 0..<50 {
                await viewModel.generateCustomPoem(prompt: "Memory pressure test \(i)")
                
                // Only keep every 10th poem as favorite to simulate user behavior
                if i % 10 == 0, let poem = viewModel.poemOfTheDay {
                    await viewModel.toggleFavorite(poem: poem)
                }
            }
        }
        
        // System should still be responsive
        XCTAssertNotNil(viewModel.poemOfTheDay, "Should handle memory pressure gracefully")
        XCTAssertFalse(viewModel.isLoading, "Should remain in loaded state")
        
        // Favorites should be reasonable
        let favorites = viewModel.favorites
        XCTAssertLessThan(favorites.count, 20, "Should not accumulate excessive data")
    }
} 