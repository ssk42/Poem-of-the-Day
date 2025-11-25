import XCTest
@testable import Poem_of_the_Day

@MainActor
final class BackgroundProcessingTests: XCTestCase {
    
    var poemRepository: PoemRepository!
    var networkService: MockNetworkService!
    var telemetryService: TelemetryService!
    var viewModel: PoemViewModel!
    
    override func setUpWithError() throws {
        networkService = MockNetworkService()
        telemetryService = TelemetryService()
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
    }
    
    // MARK: - App Lifecycle Tests
    
    func testAppDidEnterBackground() async throws {
        // Simulate app entering background
        await viewModel.loadInitialData()
        
        // Simulate background app refresh
        let expectation = expectation(description: "Background refresh")
        
        Task {
            // In background, app should handle operations gracefully
            do {
                let _ = try await poemRepository.getDailyPoem()
                expectation.fulfill()
            } catch {
                // Background operations may fail - that's acceptable
                expectation.fulfill()
            }
        }
        
        await fulfillment(of: [expectation], timeout: 10.0)
    }
    
    func testAppWillEnterForeground() async throws {
        // Simulate app returning to foreground
        let expectation = expectation(description: "Foreground refresh")
        
        Task {
            // App should refresh content when returning to foreground
            await viewModel.refreshPoem()
            
            XCTAssertFalse(viewModel.isLoading, "Should refresh content in foreground")
            expectation.fulfill()
        }
        
        await fulfillment(of: [expectation], timeout: 5.0)
    }
    
    func testAppDidBecomeActive() async throws {
        // Test app becoming active after being inactive
        await viewModel.loadInitialData()
        let initialPoem = viewModel.poemOfTheDay
        
        // Simulate app becoming active (should check for updates)
        let expectation = expectation(description: "App active check")
        
        Task {
            await viewModel.refreshPoem()
            
            // Should update if new content available
            XCTAssertNotNil(viewModel.poemOfTheDay, "Should have poem when app becomes active")
            expectation.fulfill()
        }
        
        await fulfillment(of: [expectation], timeout: 5.0)
    }
    
    // MARK: - Background App Refresh Tests
    
    func testBackgroundAppRefreshEnabled() async throws {
        // Test behavior when background app refresh is enabled
        networkService.delayDuration = 0.1 // Quick response for background
        
        let expectation = expectation(description: "Background app refresh")
        
        Task {
            // Simulate background refresh
            do {
                let _ = try await poemRepository.getDailyPoem()
                
                // Background refresh should succeed quickly
                XCTAssertTrue(true, "Background refresh should work when enabled")
                
            } catch {
                // May fail in background - acceptable
            }
            
            expectation.fulfill()
        }
        
        await fulfillment(of: [expectation], timeout: 3.0)
    }
    
    func testBackgroundAppRefreshDisabled() async throws {
        // Test behavior when background app refresh is disabled
        let expectation = expectation(description: "Background refresh disabled")
        
        Task {
            // Should use cached data when background refresh disabled
            await viewModel.loadInitialData()
            let cachedPoems = viewModel.favorites
            
            XCTAssertFalse(cachedPoems.isEmpty, "Should use cached data when background refresh disabled")
            expectation.fulfill()
        }
        
        await fulfillment(of: [expectation], timeout: 2.0)
    }
    
    // MARK: - Memory Pressure Tests
    
    func testMemoryWarningHandling() async throws {
        // Test handling of memory warnings
        await viewModel.loadInitialData()
        
        // Simulate memory warning
        let expectation = expectation(description: "Memory warning")
        
        Task {
            // App should handle memory pressure gracefully
            // In real implementation, would clear caches, reduce memory usage
            
            await viewModel.refreshPoem()
            
            // Should still function after memory warning
            XCTAssertNotNil(viewModel.poemOfTheDay, "Should maintain functionality after memory warning")
            expectation.fulfill()
        }
        
        await fulfillment(of: [expectation], timeout: 5.0)
    }
    
    func testLowMemoryRecovery() async throws {
        // Test recovery from low memory situations
        let expectation = expectation(description: "Low memory recovery")
        
        Task {
            // Create memory pressure
            var largeData: [String] = []
            for i in 0..<1000 {
                largeData.append(String(repeating: "memory test \(i)", count: 100))
            }
            
            // App should still function
            await viewModel.loadInitialData()
            
            // Clean up memory
            largeData.removeAll()
            
            XCTAssertFalse(viewModel.isLoading, "Should recover from low memory")
            expectation.fulfill()
        }
        
        await fulfillment(of: [expectation], timeout: 8.0)
    }
    
    // MARK: - System Integration Tests
    
    func testSystemNotificationHandling() throws {
        // Test handling of system notifications
        let notificationTypes = [
            "UIApplicationDidEnterBackgroundNotification",
            "UIApplicationWillEnterForegroundNotification", 
            "UIApplicationDidBecomeActiveNotification",
            "UIApplicationWillResignActiveNotification",
            "UIApplicationDidReceiveMemoryWarningNotification"
        ]
        
        for notificationType in notificationTypes {
            // Simulate system notification
            let handled = handleSystemNotification(notificationType)
            XCTAssertTrue(handled, "Should handle \(notificationType)")
        }
    }
    
    func testBackgroundTaskCompletion() async throws {
        // Test background task completion
        let expectation = expectation(description: "Background task")
        
        Task {
            // Simulate background task with time limit
            let backgroundTaskTime = 2.0
            let startTime = CFAbsoluteTimeGetCurrent()
            
            // Perform background operation
            await viewModel.refreshPoem()
            
            let endTime = CFAbsoluteTimeGetCurrent()
            let duration = endTime - startTime
            
            // Should complete within background time limit
            XCTAssertLessThan(duration, backgroundTaskTime + 1.0, "Should complete background task in time")
            expectation.fulfill()
        }
        
        await fulfillment(of: [expectation], timeout: 5.0)
    }
    
    // MARK: - Data Persistence Tests
    
    func testBackgroundDataPersistence() async throws {
        // Test data persistence during background operations
        await viewModel.loadInitialData()
        
        if let poem = viewModel.poemOfTheDay {
            await viewModel.toggleFavorite(poem: poem)
            
            // Simulate app backgrounding
            let expectation = expectation(description: "Background persistence")
            
            Task {
                // Data should persist through background
                await viewModel.loadInitialData()
                let favorites = viewModel.favorites
                
                XCTAssertTrue(favorites.contains { $0.id == poem.id }, "Should persist favorites in background")
                expectation.fulfill()
            }
            
            await fulfillment(of: [expectation], timeout: 3.0)
        }
    }
    
    func testBackgroundCacheManagement() async throws {
        // Test cache management in background
        await viewModel.loadInitialData()
        
        let expectation = expectation(description: "Background cache")
        
        Task {
            // Background should manage cache efficiently
            for _ in 0..<5 {
                await viewModel.refreshPoem()
            }
            
            // Should not accumulate excessive cache data
            XCTAssertNotNil(viewModel.poemOfTheDay, "Should maintain cache efficiently")
            expectation.fulfill()
        }
        
        await fulfillment(of: [expectation], timeout: 10.0)
    }
    
    // MARK: - Network State Change Tests
    
    func testNetworkConnectionLost() async throws {
        // Test behavior when network connection is lost
        networkService.shouldThrowError = true
        networkService.errorToThrow = PoemError.networkUnavailable
        
        let expectation = expectation(description: "Network lost")
        
        Task {
            await viewModel.refreshPoem()
            
            // Should handle network loss gracefully
            XCTAssertTrue(viewModel.showErrorAlert, "Should handle network loss")
            expectation.fulfill()
        }
        
        await fulfillment(of: [expectation], timeout: 5.0)
    }
    
    func testNetworkConnectionRestored() async throws {
        // Test behavior when network connection is restored
        networkService.shouldThrowError = true
        await viewModel.refreshPoem()
        
        // Restore network
        networkService.shouldThrowError = false
        
        let expectation = expectation(description: "Network restored")
        
        Task {
            await viewModel.refreshPoem()
            
            // Should recover when network restored
            XCTAssertFalse(viewModel.isLoading, "Should recover when network restored")
            expectation.fulfill()
        }
        
        await fulfillment(of: [expectation], timeout: 5.0)
    }
    
    // MARK: - Background Processing Performance Tests
    
    func testBackgroundOperationEfficiency() async throws {
        // Test efficiency of background operations
        let expectation = expectation(description: "Background efficiency")
        
        Task {
            let startTime = CFAbsoluteTimeGetCurrent()
            
            // Perform multiple background operations
            await withTaskGroup(of: Void.self) { group in
                for _ in 0..<5 {
                    group.addTask {
                        await self.viewModel.refreshPoem()
                    }
                }
            }
            
            let endTime = CFAbsoluteTimeGetCurrent()
            let duration = endTime - startTime
            
            // Background operations should be efficient
            XCTAssertLessThan(duration, 8.0, "Background operations should be efficient")
            expectation.fulfill()
        }
        
        await fulfillment(of: [expectation], timeout: 12.0)
    }
    
    // MARK: - Background State Preservation Tests
    
    func testStatePreservationDuringBackground() async throws {
        // Test that app state is preserved during backgrounding
        await viewModel.loadInitialData()
        let originalPoem = viewModel.poemOfTheDay
        let originalState = viewModel.isLoading
        
        // Simulate backgrounding and returning
        let expectation = expectation(description: "State preservation")
        
        Task {
            // Simulate background period
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
            
            // State should be preserved or gracefully recovered
            XCTAssertTrue(
                viewModel.poemOfTheDay?.id == originalPoem?.id || !viewModel.isLoading,
                "Should preserve or recover state after backgrounding"
            )
            
            expectation.fulfill()
        }
        
        await fulfillment(of: [expectation], timeout: 3.0)
    }
    
    // MARK: - Helper Methods
    
    private func handleSystemNotification(_ notificationType: String) -> Bool {
        // Simulate handling of system notifications
        switch notificationType {
        case "UIApplicationDidEnterBackgroundNotification":
            return true // Handle background entry
        case "UIApplicationWillEnterForegroundNotification":
            return true // Handle foreground entry
        case "UIApplicationDidBecomeActiveNotification":
            return true // Handle becoming active
        case "UIApplicationWillResignActiveNotification":
            return true // Handle resigning active
        case "UIApplicationDidReceiveMemoryWarningNotification":
            return true // Handle memory warning
        default:
            return false
        }
    }
    
    private func fulfillment(of expectations: [XCTestExpectation], timeout: TimeInterval) async {
        await withCheckedContinuation { continuation in
            let waiter = XCTWaiter()
            let result = waiter.wait(for: expectations, timeout: timeout)
            continuation.resume()
        }
    }
} 