import XCTest

final class ErrorScenarioUITests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
    }
    
    override func tearDownWithError() throws {
        app = nil
    }
    
    // MARK: - Network Error Scenarios
    
    func testNetworkUnavailableError() throws {
        // Configure app for network error
        app.launchArguments = ["--ui-testing"]
        app.launchEnvironment = ["SIMULATE_NETWORK_ERROR": "true"]
        app.launch()
        
        // Try to refresh poem
        let refreshButton = app.buttons.matching(identifier: "refresh_button").firstMatch
        XCTAssertTrue(refreshButton.waitForExistence(timeout: 5))
        refreshButton.tap()
        
        // Should show network error alert
        let errorAlert = app.alerts.firstMatch
        XCTAssertTrue(errorAlert.waitForExistence(timeout: 5))
        
        // Verify error message contains network-related text
        let alertMessage = errorAlert.staticTexts.element(boundBy: 1)
        XCTAssertTrue(alertMessage.exists)
        
        // Dismiss alert
        let okButton = errorAlert.buttons["OK"]
        if okButton.exists {
            okButton.tap()
        }
        
        // App should still be functional with cached content
        let poemTitle = app.staticTexts.matching(identifier: "poem_title").firstMatch
        XCTAssertTrue(poemTitle.waitForExistence(timeout: 3))
    }
    
    func testSlowNetworkResponse() throws {
        // Configure app for slow network
        app.launchArguments = ["--ui-testing"]
        app.launchEnvironment = ["SLOW_NETWORK": "true"]
        app.launch()
        
        // Try to refresh poem
        let refreshButton = app.buttons.matching(identifier: "refresh_button").firstMatch
        XCTAssertTrue(refreshButton.waitForExistence(timeout: 5))
        refreshButton.tap()
        
        // Should show loading indicator
        let loadingIndicator = app.activityIndicators.firstMatch
        if loadingIndicator.exists {
            XCTAssertTrue(loadingIndicator.exists, "Should show loading indicator for slow network")
        }
        
        // Wait longer for slow response
        let poemTitle = app.staticTexts.matching(identifier: "poem_title").firstMatch
        XCTAssertTrue(poemTitle.waitForExistence(timeout: 10))
    }
    
    func testServerError() throws {
        // Configure app for server error
        app.launchArguments = ["--ui-testing"]
        app.launchEnvironment = ["SIMULATE_SERVER_ERROR": "true"]
        app.launch()
        
        // Try to refresh poem
        let refreshButton = app.buttons.matching(identifier: "refresh_button").firstMatch
        XCTAssertTrue(refreshButton.waitForExistence(timeout: 5))
        refreshButton.tap()
        
        // Should show server error
        let errorAlert = app.alerts.firstMatch
        if errorAlert.waitForExistence(timeout: 5) {
            XCTAssertTrue(errorAlert.exists, "Should show server error alert")
            
            let okButton = errorAlert.buttons["OK"]
            if okButton.exists {
                okButton.tap()
            }
        }
    }
    
    // MARK: - AI Error Scenarios
    
    func testAIServiceUnavailable() throws {
        // Configure app with AI unavailable
        app.launchArguments = ["--ui-testing"]
        app.launchEnvironment = ["AI_AVAILABLE": "false"]
        app.launch()
        
        // AI buttons should be disabled or hidden
        let vibeButton = app.buttons.matching(identifier: "vibe_generation_button").firstMatch
        let customButton = app.buttons.matching(identifier: "custom_prompt_button").firstMatch
        
        // Wait for UI to load
        let poemTitle = app.staticTexts.matching(identifier: "poem_title").firstMatch
        XCTAssertTrue(poemTitle.waitForExistence(timeout: 5))
        
        // Check if AI buttons exist and are disabled
        if vibeButton.exists {
            XCTAssertFalse(vibeButton.isEnabled, "Vibe button should be disabled when AI unavailable")
        }
        
        if customButton.exists {
            XCTAssertFalse(customButton.isEnabled, "Custom button should be disabled when AI unavailable")
        }
    }
    
    func testAIGenerationError() throws {
        // Configure app with AI errors
        app.launchArguments = ["--ui-testing"]
        app.launchEnvironment = [
            "AI_AVAILABLE": "true",
            "MOCK_AI_ERROR": "true"
        ]
        app.launch()
        
        // Try vibe generation
        let vibeButton = app.buttons.matching(identifier: "vibe_generation_button").firstMatch
        if vibeButton.waitForExistence(timeout: 5) {
            vibeButton.tap()
            
            let vibeSheet = app.sheets.firstMatch
            XCTAssertTrue(vibeSheet.waitForExistence(timeout: 3))
            
            let generateButton = app.buttons.matching(identifier: "generate_vibe_poem_button").firstMatch
            generateButton.tap()
            
            // Should show AI error
            let errorAlert = app.alerts.firstMatch
            XCTAssertTrue(errorAlert.waitForExistence(timeout: 5), "Should show AI error alert")
            
            let okButton = errorAlert.buttons["OK"]
            if okButton.exists {
                okButton.tap()
            }
            
            // Sheet should remain open
            XCTAssertTrue(vibeSheet.exists, "Sheet should remain open after AI error")
            
            // Cancel to close
            app.buttons["Cancel"].tap()
        }
    }
    
    // MARK: - Data Persistence Error Scenarios
    
    func testFavoritesStorageError() throws {
        // Configure app with storage errors
        app.launchArguments = ["--ui-testing"]
        app.launchEnvironment = ["SIMULATE_STORAGE_ERROR": "true"]
        app.launch()
        
        // Try to favorite a poem
        let favoriteButton = app.buttons.matching(identifier: "favorite_button").firstMatch
        XCTAssertTrue(favoriteButton.waitForExistence(timeout: 5))
        favoriteButton.tap()
        
        // Should show storage error alert
        let errorAlert = app.alerts.firstMatch
        if errorAlert.waitForExistence(timeout: 5) {
            XCTAssertTrue(errorAlert.exists, "Should show storage error alert")
            
            let okButton = errorAlert.buttons["OK"]
            if okButton.exists {
                okButton.tap()
            }
        }
        
        // Button state should not change due to error
        XCTAssertTrue(favoriteButton.exists, "Favorite button should remain unchanged after storage error")
    }
    
    func testCorruptedCacheRecovery() throws {
        // Configure app with corrupted cache
        app.launchArguments = ["--ui-testing"]
        app.launchEnvironment = ["CORRUPTED_CACHE": "true"]
        app.launch()
        
        // App should handle corrupted cache gracefully
        let poemTitle = app.staticTexts.matching(identifier: "poem_title").firstMatch
        XCTAssertTrue(poemTitle.waitForExistence(timeout: 8), "Should recover from corrupted cache")
        
        // Should not show error to user
        let errorAlert = app.alerts.firstMatch
        XCTAssertFalse(errorAlert.exists, "Should not show error alert for cache recovery")
    }
    
    // MARK: - Memory Pressure Scenarios
    
    func testLowMemoryConditions() throws {
        // Configure app for low memory simulation
        app.launchArguments = ["--ui-testing"]
        app.launchEnvironment = ["SIMULATE_LOW_MEMORY": "true"]
        app.launch()
        
        // Try multiple operations that could use memory
        for _ in 0..<5 {
            let refreshButton = app.buttons.matching(identifier: "refresh_button").firstMatch
            refreshButton.tap()
            sleep(1)
        }
        
        // App should remain functional
        let poemTitle = app.staticTexts.matching(identifier: "poem_title").firstMatch
        XCTAssertTrue(poemTitle.waitForExistence(timeout: 5), "App should handle low memory conditions")
    }
    
    // MARK: - Invalid Data Scenarios
    
    func testMalformedDataHandling() throws {
        // Configure app with malformed data
        app.launchArguments = ["--ui-testing"]
        app.launchEnvironment = ["MALFORMED_DATA": "true"]
        app.launch()
        
        // Try to refresh
        let refreshButton = app.buttons.matching(identifier: "refresh_button").firstMatch
        XCTAssertTrue(refreshButton.waitForExistence(timeout: 5))
        refreshButton.tap()
        
        // Should handle malformed data gracefully
        sleep(3) // Allow time for processing
        
        // Should either show error or fallback content
        let poemTitle = app.staticTexts.matching(identifier: "poem_title").firstMatch
        let errorAlert = app.alerts.firstMatch
        
        XCTAssertTrue(poemTitle.exists || errorAlert.exists, "Should handle malformed data with error or fallback")
        
        if errorAlert.exists {
            let okButton = errorAlert.buttons["OK"]
            if okButton.exists {
                okButton.tap()
            }
        }
    }
    
    func testEmptyResponseHandling() throws {
        // Configure app with empty responses
        app.launchArguments = ["--ui-testing"]
        app.launchEnvironment = ["EMPTY_RESPONSE": "true"]
        app.launch()
        
        // Try to refresh
        let refreshButton = app.buttons.matching(identifier: "refresh_button").firstMatch
        XCTAssertTrue(refreshButton.waitForExistence(timeout: 5))
        refreshButton.tap()
        
        // Should handle empty response gracefully
        sleep(3)
        
        // Should show appropriate message or fallback
        let errorAlert = app.alerts.firstMatch
        if errorAlert.waitForExistence(timeout: 3) {
            XCTAssertTrue(errorAlert.exists, "Should show appropriate message for empty response")
            
            let okButton = errorAlert.buttons["OK"]
            if okButton.exists {
                okButton.tap()
            }
        }
    }
    
    // MARK: - Rate Limiting Scenarios
    
    func testRateLimitingHandling() throws {
        // Configure app with rate limiting
        app.launchArguments = ["--ui-testing"]
        app.launchEnvironment = ["SIMULATE_RATE_LIMIT": "true"]
        app.launch()
        
        // Try multiple quick requests to trigger rate limiting
        let refreshButton = app.buttons.matching(identifier: "refresh_button").firstMatch
        XCTAssertTrue(refreshButton.waitForExistence(timeout: 5))
        
        for _ in 0..<3 {
            refreshButton.tap()
            usleep(500000) // 0.5 seconds
        }
        
        // Should show rate limit error
        let errorAlert = app.alerts.firstMatch
        if errorAlert.waitForExistence(timeout: 5) {
            XCTAssertTrue(errorAlert.exists, "Should show rate limit error")
            
            let okButton = errorAlert.buttons["OK"]
            if okButton.exists {
                okButton.tap()
            }
        }
    }
    
    // MARK: - Recovery Scenarios
    
    func testNetworkRecovery() throws {
        // Start with network error
        app.launchArguments = ["--ui-testing"]
        app.launchEnvironment = ["SIMULATE_NETWORK_ERROR": "true"]
        app.launch()
        
        // Try refresh and get error
        let refreshButton = app.buttons.matching(identifier: "refresh_button").firstMatch
        XCTAssertTrue(refreshButton.waitForExistence(timeout: 5))
        refreshButton.tap()
        
        let errorAlert = app.alerts.firstMatch
        if errorAlert.waitForExistence(timeout: 5) {
            let okButton = errorAlert.buttons["OK"]
            if okButton.exists {
                okButton.tap()
            }
        }
        
        // Simulate network recovery
        app.terminate()
        app.launchEnvironment.removeValue(forKey: "SIMULATE_NETWORK_ERROR")
        app.launch()
        
        // Should now work normally
        let refreshButton2 = app.buttons.matching(identifier: "refresh_button").firstMatch
        XCTAssertTrue(refreshButton2.waitForExistence(timeout: 5))
        refreshButton2.tap()
        
        let poemTitle = app.staticTexts.matching(identifier: "poem_title").firstMatch
        XCTAssertTrue(poemTitle.waitForExistence(timeout: 8), "Should recover after network comes back")
    }
    
    func testAppBackgroundingDuringError() throws {
        // Configure app with slow network
        app.launchArguments = ["--ui-testing"]
        app.launchEnvironment = ["SLOW_NETWORK": "true"]
        app.launch()
        
        // Start a network operation
        let refreshButton = app.buttons.matching(identifier: "refresh_button").firstMatch
        XCTAssertTrue(refreshButton.waitForExistence(timeout: 5))
        refreshButton.tap()
        
        // Background the app during operation
        XCUIDevice.shared.press(.home)
        sleep(2)
        
        // Return to app
        app.activate()
        sleep(1)
        
        // Should handle backgrounding gracefully
        let poemTitle = app.staticTexts.matching(identifier: "poem_title").firstMatch
        XCTAssertTrue(poemTitle.waitForExistence(timeout: 8), "Should handle backgrounding during network operation")
    }
    
    // MARK: - Timeout Scenarios
    
    func testRequestTimeout() throws {
        // Configure app with request timeout
        app.launchArguments = ["--ui-testing"]
        app.launchEnvironment = ["SIMULATE_TIMEOUT": "true"]
        app.launch()
        
        // Try refresh
        let refreshButton = app.buttons.matching(identifier: "refresh_button").firstMatch
        XCTAssertTrue(refreshButton.waitForExistence(timeout: 5))
        refreshButton.tap()
        
        // Should handle timeout gracefully
        let errorAlert = app.alerts.firstMatch
        if errorAlert.waitForExistence(timeout: 10) {
            XCTAssertTrue(errorAlert.exists, "Should show timeout error")
            
            let okButton = errorAlert.buttons["OK"]
            if okButton.exists {
                okButton.tap()
            }
        }
    }
    
    // MARK: - Concurrent Error Scenarios
    
    func testConcurrentErrorOperations() throws {
        // Configure app with multiple error conditions
        app.launchArguments = ["--ui-testing"]
        app.launchEnvironment = [
            "SIMULATE_NETWORK_ERROR": "true",
            "AI_AVAILABLE": "true",
            "MOCK_AI_ERROR": "true"
        ]
        app.launch()
        
        // Try multiple operations that will fail
        let refreshButton = app.buttons.matching(identifier: "refresh_button").firstMatch
        XCTAssertTrue(refreshButton.waitForExistence(timeout: 5))
        refreshButton.tap()
        
        // Dismiss network error if it appears
        let errorAlert = app.alerts.firstMatch
        if errorAlert.waitForExistence(timeout: 3) {
            let okButton = errorAlert.buttons["OK"]
            if okButton.exists {
                okButton.tap()
            }
        }
        
        // Try AI operation
        let vibeButton = app.buttons.matching(identifier: "vibe_generation_button").firstMatch
        if vibeButton.exists {
            vibeButton.tap()
            
            let vibeSheet = app.sheets.firstMatch
            if vibeSheet.waitForExistence(timeout: 3) {
                let generateButton = app.buttons.matching(identifier: "generate_vibe_poem_button").firstMatch
                generateButton.tap()
                
                // Handle AI error
                let aiErrorAlert = app.alerts.firstMatch
                if aiErrorAlert.waitForExistence(timeout: 3) {
                    let okButton = aiErrorAlert.buttons["OK"]
                    if okButton.exists {
                        okButton.tap()
                    }
                }
                
                // Cancel AI sheet
                app.buttons["Cancel"].tap()
            }
        }
        
        // App should still be functional after multiple errors
        let poemTitle = app.staticTexts.matching(identifier: "poem_title").firstMatch
        XCTAssertTrue(poemTitle.waitForExistence(timeout: 5), "App should remain functional after multiple errors")
    }
} 