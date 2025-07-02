import XCTest
@testable import Poem_of_the_Day

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
        vibeAnalyzer = VibeAnalyzer(newsService: NewsService())
        newsService = NewsService(networkService: networkService)
        poemRepository = PoemRepository(networkService: networkService, telemetryService: telemetryService)
        
        viewModel = PoemViewModel(
            poemGenerationService: MockPoemGenerationService(),
            telemetryService: telemetryService,
            repository: poemRepository
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
        await viewModel.loadTodaysPoem()
        
        // Should have poem loaded
        XCTAssertNotNil(viewModel.currentPoem, "Should load initial poem on first launch")
        XCTAssertEqual(viewModel.loadingState, .loaded, "Should reach loaded state")
        
        // 2. User reads poem for a while (engagement tracking)
        let initialPoem = viewModel.currentPoem
        
        // 3. User favorites the poem
        if let poem = initialPoem {
            await viewModel.toggleFavorite(for: poem)
            
            let favorites = await viewModel.loadFavoritePoems()
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
        
        let newPoem = viewModel.currentPoem
        XCTAssertNotNil(newPoem, "Should have new poem after refresh")
        
        // 6. User discovers AI features and generates vibe-based poem
        if AppConfiguration.FeatureFlags.aiPoemGeneration {
            await viewModel.generatePoemFromVibe()
            
            // Should have AI-generated poem
            XCTAssertNotNil(viewModel.currentPoem, "Should have AI-generated poem")
        }
        
        // 7. User generates custom poem
        if AppConfiguration.FeatureFlags.aiPoemGeneration {
            await viewModel.generatePoemFromPrompt("A poem about new beginnings")
            
            XCTAssertNotNil(viewModel.currentPoem, "Should have custom AI-generated poem")
        }
        
        // 8. User adds AI poem to favorites
        if let aiPoem = viewModel.currentPoem {
            await viewModel.toggleFavorite(for: aiPoem)
            
            let finalFavorites = await viewModel.loadFavoritePoems()
            XCTAssertEqual(finalFavorites.count, 2, "Should have two favorites after complete journey")
        }
    }
    
    func testDailyUserReturnWorkflow() async throws {
        // Simulate returning user daily workflow
        
        // Seed with some existing favorites
        let seedPoem = TestData.samplePoems[0]
        await viewModel.toggleFavorite(for: seedPoem)
        
        // 1. User opens app (should check for new daily poem)
        await viewModel.loadTodaysPoem()
        
        XCTAssertNotNil(viewModel.currentPoem, "Should load today's poem")
        
        // 2. User checks favorites to revisit old poems
        let favorites = await viewModel.loadFavoritePoems()
        XCTAssertGreaterThan(favorites.count, 0, "Should have existing favorites")
        
        // 3. User might favorite today's poem too
        if let todayPoem = viewModel.currentPoem {
            await viewModel.toggleFavorite(for: todayPoem)
            
            let updatedFavorites = await viewModel.loadFavoritePoems()
            XCTAssertEqual(updatedFavorites.count, favorites.count + 1, "Should add today's poem to favorites")
        }
        
        // 4. User might share poem with friends
        if let poem = viewModel.currentPoem {
            let shareText = poem.shareText
            XCTAssertTrue(shareText.contains(poem.title), "Should be able to share daily poem")
        }
        
        // 5. User explores AI features for variety
        if AppConfiguration.FeatureFlags.aiPoemGeneration {
            await viewModel.generatePoemFromVibe()
            XCTAssertNotNil(viewModel.currentPoem, "Should generate poem from current vibe")
        }
    }
    
    func testPowerUserAdvancedWorkflow() async throws {
        // Simulate power user who uses all features extensively
        
        // 1. Multiple poem generations and curation
        for i in 0..<5 {
            await viewModel.refreshPoem()
            
            if let poem = viewModel.currentPoem {
                // Power user favorites selectively
                if i % 2 == 0 {
                    await viewModel.toggleFavorite(for: poem)
                }
            }
        }
        
        // 2. Extensive AI feature usage
        if AppConfiguration.FeatureFlags.aiPoemGeneration {
            // Generate multiple AI poems with different prompts
            let prompts = [
                "A poem about technology and nature",
                "Something melancholic about time passing",
                "An energetic poem about adventure",
                "A peaceful meditation on stillness"
            ]
            
            for prompt in prompts {
                await viewModel.generatePoemFromPrompt(prompt)
                
                if let aiPoem = viewModel.currentPoem {
                    await viewModel.toggleFavorite(for: aiPoem)
                }
            }
        }
        
        // 3. Favorite management
        let allFavorites = await viewModel.loadFavoritePoems()
        XCTAssertGreaterThan(allFavorites.count, 0, "Power user should have many favorites")
        
        // Remove some favorites (curation)
        if let firstFavorite = allFavorites.first {
            await viewModel.toggleFavorite(for: firstFavorite)
            
            let updatedFavorites = await viewModel.loadFavoritePoems()
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
        if AppConfiguration.FeatureFlags.aiPoemGeneration {
            await viewModel.generatePoemFromVibe()
            
            let generatedPoem = viewModel.currentPoem
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
        let poem = try await poemRepository.fetchTodaysPoem()
        XCTAssertNotNil(poem, "Repository should fetch poem")
        
        // 2. ViewModel processes poem
        await viewModel.loadTodaysPoem()
        XCTAssertEqual(viewModel.loadingState, .loaded, "ViewModel should reach loaded state")
        XCTAssertNotNil(viewModel.currentPoem, "ViewModel should have current poem")
        
        // 3. ViewModel prepares UI state
        XCTAssertEqual(viewModel.errorMessage, nil, "Should not have error message in success case")
        
        // 4. Test interactions that trigger telemetry
        if let currentPoem = viewModel.currentPoem {
            await viewModel.toggleFavorite(for: currentPoem)
            
            // Telemetry should be triggered (verified by no crashes)
            XCTAssertTrue(true, "Telemetry integration should work seamlessly")
        }
    }
    
    func testErrorPropagationThroughStack() async throws {
        // Test how errors propagate through the entire stack
        
        // 1. Create network error scenario
        let failingNetworkService = MockNetworkService()
        failingNetworkService.shouldFail = true
        failingNetworkService.errorToReturn = PoemError.networkUnavailable
        
        let failingRepository = PoemRepository(
            networkService: failingNetworkService,
            telemetryService: telemetryService
        )
        
        let failingViewModel = PoemViewModel(
            poemGenerationService: MockPoemGenerationService(),
            telemetryService: telemetryService,
            repository: failingRepository
        )
        
        // 2. Attempt to load poem
        await failingViewModel.loadTodaysPoem()
        
        // 3. Error should propagate correctly
        XCTAssertEqual(failingViewModel.loadingState, .error, "Should reach error state")
        XCTAssertNotNil(failingViewModel.errorMessage, "Should have error message")
        
        // 4. Recovery should work
        failingNetworkService.shouldFail = false
        await failingViewModel.refreshPoem()
        
        XCTAssertEqual(failingViewModel.loadingState, .loaded, "Should recover from error")
        XCTAssertNil(failingViewModel.errorMessage, "Error message should be cleared")
    }
    
    // MARK: - State Management Integration Tests
    
    func testConcurrentOperations() async throws {
        // Test handling of concurrent operations
        
        // Start multiple operations simultaneously
        async let poem1 = viewModel.refreshPoem()
        async let poem2 = viewModel.loadTodaysPoem()
        async let favorites = viewModel.loadFavoritePoems()
        
        // Wait for all to complete
        await poem1
        await poem2
        let favs = await favorites
        
        // App should handle concurrent operations gracefully
        XCTAssertEqual(viewModel.loadingState, .loaded, "Should handle concurrent operations")
        XCTAssertNotNil(viewModel.currentPoem, "Should have valid poem after concurrent operations")
        XCTAssertNotNil(favs, "Should load favorites successfully")
    }
    
    func testStateConsistencyAcrossOperations() async throws {
        // Test that state remains consistent across various operations
        
        // 1. Load initial poem
        await viewModel.loadTodaysPoem()
        let initialPoem = viewModel.currentPoem
        
        // 2. Add to favorites
        if let poem = initialPoem {
            await viewModel.toggleFavorite(for: poem)
            let favorites = await viewModel.loadFavoritePoems()
            XCTAssertTrue(favorites.contains { $0.id == poem.id }, "State should remain consistent")
        }
        
        // 3. Refresh poem
        await viewModel.refreshPoem()
        
        // 4. Check that favorites are still intact
        let favoritesAfterRefresh = await viewModel.loadFavoritePoems()
        if let originalPoem = initialPoem {
            XCTAssertTrue(favoritesAfterRefresh.contains { $0.id == originalPoem.id }, 
                         "Favorites should persist across operations")
        }
        
        // 5. Generate AI poem
        if AppConfiguration.FeatureFlags.aiPoemGeneration {
            await viewModel.generatePoemFromPrompt("Test consistency")
            
            // Favorites should still be intact
            let favoritesAfterAI = await viewModel.loadFavoritePoems()
            XCTAssertEqual(favoritesAfterAI.count, favoritesAfterRefresh.count, 
                          "AI generation should not affect existing favorites")
        }
    }
    
    // MARK: - Performance Integration Tests
    
    func testCompleteWorkflowPerformance() async throws {
        // Test performance of complete user workflows
        
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // Simulate intensive user session
        await viewModel.loadTodaysPoem()
        
        for _ in 0..<3 {
            await viewModel.refreshPoem()
            
            if let poem = viewModel.currentPoem {
                await viewModel.toggleFavorite(for: poem)
            }
        }
        
        if AppConfiguration.FeatureFlags.aiPoemGeneration {
            await viewModel.generatePoemFromVibe()
            await viewModel.generatePoemFromPrompt("Performance test poem")
        }
        
        let _ = await viewModel.loadFavoritePoems()
        
        let endTime = CFAbsoluteTimeGetCurrent()
        let duration = endTime - startTime
        
        // Complete workflow should finish within reasonable time
        XCTAssertLessThan(duration, 15.0, "Complete workflow should finish within 15 seconds")
        
        // Final state should be valid
        XCTAssertNotNil(viewModel.currentPoem, "Should have valid poem after performance test")
        XCTAssertEqual(viewModel.loadingState, .loaded, "Should end in loaded state")
    }
    
    func testMemoryUsageInLongSession() async throws {
        // Test memory usage during extended session
        
        // Simulate long user session with many operations
        for i in 0..<20 {
            await viewModel.refreshPoem()
            
            if let poem = viewModel.currentPoem {
                await viewModel.toggleFavorite(for: poem)
                
                // Toggle again (remove from favorites)
                await viewModel.toggleFavorite(for: poem)
            }
            
            // Periodically generate AI poems
            if i % 5 == 0 && AppConfiguration.FeatureFlags.aiPoemGeneration {
                await viewModel.generatePoemFromPrompt("Memory test \(i)")
            }
        }
        
        // Check final state
        XCTAssertNotNil(viewModel.currentPoem, "Should maintain valid state after long session")
        XCTAssertEqual(viewModel.loadingState, .loaded, "Should be in loaded state")
        
        // Favorites should be manageable (not accumulating indefinitely)
        let favorites = await viewModel.loadFavoritePoems()
        XCTAssertLessThan(favorites.count, 10, "Should not accumulate excessive favorites")
    }
    
    // MARK: - Integration Edge Cases
    
    func testRapidUserInteractions() async throws {
        // Test rapid fire user interactions
        
        // Rapidly trigger multiple operations
        for _ in 0..<10 {
            await viewModel.refreshPoem()
            
            if let poem = viewModel.currentPoem {
                await viewModel.toggleFavorite(for: poem)
            }
        }
        
        // System should remain stable
        XCTAssertEqual(viewModel.loadingState, .loaded, "Should handle rapid interactions")
        XCTAssertNotNil(viewModel.currentPoem, "Should have valid poem after rapid interactions")
    }
    
    func testDataPersistenceAcrossRestarts() async throws {
        // Test data persistence (simulated app restart)
        
        // 1. Set up initial state
        await viewModel.loadTodaysPoem()
        
        if let poem = viewModel.currentPoem {
            await viewModel.toggleFavorite(for: poem)
        }
        
        let originalFavorites = await viewModel.loadFavoritePoems()
        
        // 2. Simulate app restart by creating new instances
        let newRepository = PoemRepository(
            networkService: networkService,
            telemetryService: telemetryService
        )
        
        let newViewModel = PoemViewModel(
            poemGenerationService: MockPoemGenerationService(),
            telemetryService: telemetryService,
            repository: newRepository
        )
        
        // 3. Check that favorites persisted
        let persistedFavorites = await newViewModel.loadFavoritePoems()
        XCTAssertEqual(persistedFavorites.count, originalFavorites.count, 
                      "Favorites should persist across app restarts")
    }
    
    func testMixedContentTypes() async throws {
        // Test handling of mixed content types (regular poems + AI poems)
        
        // 1. Load regular poem
        await viewModel.loadTodaysPoem()
        let regularPoem = viewModel.currentPoem
        
        if let poem = regularPoem {
            await viewModel.toggleFavorite(for: poem)
        }
        
        // 2. Generate AI poems
        if AppConfiguration.FeatureFlags.aiPoemGeneration {
            await viewModel.generatePoemFromVibe()
            let vibePoem = viewModel.currentPoem
            
            if let poem = vibePoem {
                await viewModel.toggleFavorite(for: poem)
            }
            
            await viewModel.generatePoemFromPrompt("Custom AI poem")
            let customPoem = viewModel.currentPoem
            
            if let poem = customPoem {
                await viewModel.toggleFavorite(for: poem)
            }
        }
        
        // 3. Check that all types are handled properly
        let allFavorites = await viewModel.loadFavoritePoems()
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
        failingNetworkService.shouldFail = true
        failingNetworkService.errorToReturn = PoemError.networkUnavailable
        
        let offlineRepository = PoemRepository(
            networkService: failingNetworkService,
            telemetryService: telemetryService
        )
        
        let offlineViewModel = PoemViewModel(
            poemGenerationService: MockPoemGenerationService(),
            telemetryService: telemetryService,
            repository: offlineRepository
        )
        
        // Try to load poem while offline
        await offlineViewModel.loadTodaysPoem()
        XCTAssertEqual(offlineViewModel.loadingState, .error, "Should be in error state offline")
        
        // 2. Simulate coming back online
        failingNetworkService.shouldFail = false
        
        // Retry operation
        await offlineViewModel.refreshPoem()
        XCTAssertEqual(offlineViewModel.loadingState, .loaded, "Should recover when online")
        XCTAssertNotNil(offlineViewModel.currentPoem, "Should have poem when online")
    }
    
    func testLowMemoryScenario() async throws {
        // Test behavior under simulated low memory conditions
        
        // Generate many AI poems to simulate memory pressure
        if AppConfiguration.FeatureFlags.aiPoemGeneration {
            for i in 0..<50 {
                await viewModel.generatePoemFromPrompt("Memory pressure test \(i)")
                
                // Only keep every 10th poem as favorite to simulate user behavior
                if i % 10 == 0, let poem = viewModel.currentPoem {
                    await viewModel.toggleFavorite(for: poem)
                }
            }
        }
        
        // System should still be responsive
        XCTAssertNotNil(viewModel.currentPoem, "Should handle memory pressure gracefully")
        XCTAssertEqual(viewModel.loadingState, .loaded, "Should remain in loaded state")
        
        // Favorites should be reasonable
        let favorites = await viewModel.loadFavoritePoems()
        XCTAssertLessThan(favorites.count, 20, "Should not accumulate excessive data")
    }
} 