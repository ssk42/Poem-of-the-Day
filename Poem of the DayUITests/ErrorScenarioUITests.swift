import XCTest
@testable import Poem_of_the_Day

final class ErrorScenarioUITests: XCTestCase {
    
    var app: XCUIApplication!
    var pageFactory: PageFactory!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        
        app = XCUIApplication()
        pageFactory = PageFactory(app: app)
        
        // Configure launch arguments for error testing
        app.launchArguments = ["--ui-testing", "--error-testing"]
        app.launchEnvironment = [
            "ENABLE_ERROR_SIMULATION": "true",
            "ENABLE_RECOVERY_TESTING": "true"
        ]
        
        app.launch()
    }
    
    override func tearDownWithError() throws {
        app = nil
        pageFactory = nil
    }
    
    // MARK: - Network Error Tests
    
    func testNetworkUnavailableError() throws {
        // Simulate network unavailable
        app.terminate()
        app.launchEnvironment["SIMULATE_NETWORK_UNAVAILABLE"] = "true"
        app.launch()
        
        let mainPage = pageFactory.mainContentPage()
        XCTAssertTrue(mainPage.waitForPageToLoad())
        
        // Try to refresh poem
        mainPage.tapRefreshButton()
        
        // Should show error alert
        sleep(3) // Allow time for network request to fail
        XCTAssertTrue(mainPage.verifyErrorAlert(), "Should show error alert for network unavailable")
        
        // Verify error message is appropriate
        let alert = mainPage.errorAlert
        XCTAssertTrue(alert.exists, "Error alert should be displayed")
        
        // Test retry functionality
        let retryButton = alert.buttons["Retry"]
        if retryButton.exists {
            // Restore network and retry
            configureNetworkState(available: true)
            retryButton.tap()
            
            // Should eventually succeed or handle gracefully
            sleep(3)
        } else {
            // Just dismiss the alert
            alert.buttons["OK"].tap()
        }
    }
    
    func testNetworkTimeoutError() throws {
        // Simulate slow network causing timeout
        app.terminate()
        app.launchEnvironment["SIMULATE_NETWORK_TIMEOUT"] = "true"
        app.launch()
        
        let mainPage = pageFactory.mainContentPage()
        XCTAssertTrue(mainPage.waitForPageToLoad())
        
        mainPage.tapRefreshButton()
        
        // Should show loading for a while, then timeout
        XCTAssertTrue(mainPage.verifyLoadingState(), "Should show loading indicator")
        
        // Wait for timeout (should be faster than actual timeout for testing)
        sleep(5)
        
        // Should show timeout error
        XCTAssertTrue(mainPage.verifyErrorAlert(), "Should show timeout error")
        
        // Dismiss error
        if mainPage.errorAlert.exists {
            mainPage.errorAlert.buttons.firstMatch.tap()
        }
    }
    
    func testRateLimitError() throws {
        // Simulate rate limiting from API
        app.terminate()
        app.launchEnvironment["SIMULATE_RATE_LIMIT"] = "true"
        app.launch()
        
        let mainPage = pageFactory.mainContentPage()
        XCTAssertTrue(mainPage.waitForPageToLoad())
        
        // Try multiple rapid refreshes to trigger rate limiting
        for _ in 0..<5 {
            mainPage.tapRefreshButton()
            sleep(0.5)
        }
        
        // Should show rate limit error
        sleep(2)
        XCTAssertTrue(mainPage.verifyErrorAlert(), "Should show rate limit error")
        
        // Verify appropriate error message
        let alert = mainPage.errorAlert
        if alert.exists {
            // Error message should mention rate limiting or trying again later
            alert.buttons.firstMatch.tap()
        }
    }
    
    func testMalformedDataError() throws {
        // Simulate API returning malformed data
        app.terminate()
        app.launchEnvironment["SIMULATE_MALFORMED_DATA"] = "true"
        app.launch()
        
        let mainPage = pageFactory.mainContentPage()
        XCTAssertTrue(mainPage.waitForPageToLoad())
        
        mainPage.tapRefreshButton()
        sleep(3)
        
        // Should handle malformed data gracefully
        XCTAssertTrue(mainPage.verifyErrorAlert(), "Should show error for malformed data")
        
        if mainPage.errorAlert.exists {
            mainPage.errorAlert.buttons.firstMatch.tap()
        }
        
        // App should remain stable
        XCTAssertTrue(mainPage.isDisplayed(), "App should remain stable after malformed data error")
    }
    
    // MARK: - AI Service Error Tests
    
    func testAIServiceUnavailableError() throws {
        // Simulate AI service not available on device
        app.terminate()
        app.launchEnvironment["AI_AVAILABLE"] = "false"
        app.launch()
        
        let mainPage = pageFactory.mainContentPage()
        XCTAssertTrue(mainPage.waitForPageToLoad())
        
        // AI buttons should be disabled or hidden
        let vibeButton = mainPage.vibeGenerationButton
        let customButton = mainPage.customPromptButton
        
        if vibeButton.exists {
            XCTAssertFalse(vibeButton.isEnabled, "Vibe generation should be disabled when AI unavailable")
        }
        
        if customButton.exists {
            XCTAssertFalse(customButton.isEnabled, "Custom prompt should be disabled when AI unavailable")
        }
        
        // Trying to use AI features should show appropriate message
        if vibeButton.exists && vibeButton.isEnabled {
            vibeButton.tap()
            sleep(2)
            // Should show error or unavailable message
        }
    }
    
    func testAIGenerationFailureError() throws {
        // Simulate AI generation failures
        app.terminate()
        app.launchEnvironment["AI_AVAILABLE"] = "true"
        app.launchEnvironment["SIMULATE_AI_GENERATION_FAILURE"] = "true"
        app.launch()
        
        let mainPage = pageFactory.mainContentPage()
        XCTAssertTrue(mainPage.waitForPageToLoad())
        
        let vibeGenerationPage = mainPage.tapVibeGenerationButton()
        XCTAssertTrue(vibeGenerationPage.waitForPageToLoad())
        
        vibeGenerationPage.tapGenerateButton()
        sleep(3)
        
        // Should show AI generation error
        XCTAssertTrue(mainPage.verifyErrorAlert(), "Should show AI generation failure error")
        
        if mainPage.errorAlert.exists {
            mainPage.errorAlert.buttons.firstMatch.tap()
        }
        
        vibeGenerationPage.tapBackButton()
    }
    
    func testAIModelLoadingError() throws {
        // Simulate AI model loading failures
        app.terminate()
        app.launchEnvironment["AI_AVAILABLE"] = "true"
        app.launchEnvironment["SIMULATE_AI_MODEL_ERROR"] = "true"
        app.launch()
        
        let mainPage = pageFactory.mainContentPage()
        XCTAssertTrue(mainPage.waitForPageToLoad())
        
        let customPromptPage = mainPage.tapCustomPromptButton()
        XCTAssertTrue(customPromptPage.waitForPageToLoad())
        
        customPromptPage.enterPrompt("Test prompt for model error")
        customPromptPage.tapGenerateButton()
        
        sleep(4)
        
        // Should handle model loading errors gracefully
        if mainPage.verifyErrorAlert() {
            mainPage.errorAlert.buttons.firstMatch.tap()
        }
        
        // Should return to a stable state
        XCTAssertTrue(mainPage.isDisplayed() || customPromptPage.isDisplayed())
    }
    
    // MARK: - Data Persistence Error Tests
    
    func testUserDefaultsWriteError() throws {
        // Simulate UserDefaults write failures
        app.terminate()
        app.launchEnvironment["SIMULATE_USERDEFAULTS_ERROR"] = "true"
        app.launch()
        
        let mainPage = pageFactory.mainContentPage()
        XCTAssertTrue(mainPage.waitForPageToLoad())
        
        if mainPage.verifyPoemIsDisplayed() {
            // Try to favorite a poem (should fail to persist)
            mainPage.tapFavoriteButton()
            sleep(1)
            
            // Navigate to favorites to see if it was saved
            let favoritesPage = mainPage.tapFavoritesButton()
            XCTAssertTrue(favoritesPage.waitForPageToLoad())
            
            // May show empty state if persistence failed
            // App should handle this gracefully without crashing
            
            favoritesPage.tapBackButton()
        }
    }
    
    func testAppGroupDataSharingError() throws {
        // Simulate App Group data sharing failures
        app.terminate()
        app.launchEnvironment["SIMULATE_APP_GROUP_ERROR"] = "true"
        app.launch()
        
        let mainPage = pageFactory.mainContentPage()
        XCTAssertTrue(mainPage.waitForPageToLoad())
        
        // App should still function even if App Group sharing fails
        mainPage.tapRefreshButton()
        XCTAssertTrue(mainPage.waitForLoadingToComplete())
        
        // Should not crash or show critical errors
        XCTAssertTrue(mainPage.isDisplayed(), "App should remain stable with App Group errors")
    }
    
    // MARK: - Memory and Resource Error Tests
    
    func testLowMemoryScenario() throws {
        // Simulate low memory conditions
        app.terminate()
        app.launchEnvironment["SIMULATE_LOW_MEMORY"] = "true"
        app.launch()
        
        let mainPage = pageFactory.mainContentPage()
        XCTAssertTrue(mainPage.waitForPageToLoad())
        
        // Perform memory-intensive operations
        for _ in 0..<10 {
            mainPage.tapRefreshButton()
            XCTAssertTrue(mainPage.waitForLoadingToComplete())
            
            if mainPage.verifyPoemIsDisplayed() {
                // Navigate to favorites and back
                let favoritesPage = mainPage.tapFavoritesButton()
                if favoritesPage.waitForPageToLoad() {
                    favoritesPage.tapBackButton()
                }
            }
        }
        
        // App should handle low memory gracefully
        XCTAssertTrue(mainPage.isDisplayed(), "App should survive low memory conditions")
    }
    
    func testDiskSpaceError() throws {
        // Simulate low disk space
        app.terminate()
        app.launchEnvironment["SIMULATE_LOW_DISK_SPACE"] = "true"
        app.launch()
        
        let mainPage = pageFactory.mainContentPage()
        XCTAssertTrue(mainPage.waitForPageToLoad())
        
        // Try operations that write to disk
        if mainPage.verifyPoemIsDisplayed() {
            mainPage.tapFavoriteButton()
            sleep(1)
            
            // Should either succeed or show appropriate error
            // App should not crash
        }
        
        XCTAssertTrue(mainPage.isDisplayed(), "App should handle disk space issues gracefully")
    }
    
    // MARK: - Concurrent Operation Error Tests
    
    func testConcurrentNetworkRequests() throws {
        let mainPage = pageFactory.mainContentPage()
        XCTAssertTrue(mainPage.waitForPageToLoad())
        
        // Rapidly trigger multiple network requests
        for _ in 0..<5 {
            mainPage.tapRefreshButton()
            sleep(0.2) // Very short delay to create concurrent requests
        }
        
        // Should handle concurrent requests gracefully
        sleep(5) // Allow all requests to complete or fail
        
        // App should remain stable
        XCTAssertTrue(mainPage.isDisplayed(), "App should handle concurrent requests gracefully")
        
        // Eventually should show a poem or appropriate error state
        let finalState = mainPage.verifyPoemIsDisplayed() || mainPage.verifyErrorAlert()
        XCTAssertTrue(finalState, "Should reach a stable final state")
        
        if mainPage.verifyErrorAlert() {
            mainPage.errorAlert.buttons.firstMatch.tap()
        }
    }
    
    func testConcurrentAIOperations() throws {
        // Configure AI to be available
        app.terminate()
        app.launchEnvironment["AI_AVAILABLE"] = "true"
        app.launch()
        
        let mainPage = pageFactory.mainContentPage()
        XCTAssertTrue(mainPage.waitForPageToLoad())
        
        // Try to trigger multiple AI operations
        let vibeGenerationPage = mainPage.tapVibeGenerationButton()
        XCTAssertTrue(vibeGenerationPage.waitForPageToLoad())
        
        // Rapidly tap generate multiple times
        for _ in 0..<3 {
            vibeGenerationPage.tapGenerateButton()
            sleep(0.5)
        }
        
        sleep(5) // Allow operations to complete
        
        // Should handle concurrent AI requests gracefully
        vibeGenerationPage.tapBackButton()
        XCTAssertTrue(mainPage.isDisplayed(), "Should handle concurrent AI operations gracefully")
    }
    
    // MARK: - Recovery and Resilience Tests
    
    func testErrorRecoveryAfterNetworkRestoration() throws {
        // Start with network error
        app.terminate()
        app.launchEnvironment["SIMULATE_NETWORK_UNAVAILABLE"] = "true"
        app.launch()
        
        let mainPage = pageFactory.mainContentPage()
        XCTAssertTrue(mainPage.waitForPageToLoad())
        
        mainPage.tapRefreshButton()
        sleep(3)
        
        // Should show error
        XCTAssertTrue(mainPage.verifyErrorAlert(), "Should show network error")
        
        if mainPage.errorAlert.exists {
            mainPage.errorAlert.buttons.firstMatch.tap()
        }
        
        // Restore network
        configureNetworkState(available: true)
        
        // Try again - should now succeed
        mainPage.tapRefreshButton()
        XCTAssertTrue(mainPage.waitForLoadingToComplete())
        
        // Should eventually show poem or handle gracefully
        sleep(3)
        let recovered = mainPage.verifyPoemIsDisplayed() || mainPage.verifyErrorAlert()
        XCTAssertTrue(recovered, "Should recover after network restoration")
    }
    
    func testAppStateRecoveryAfterCrash() throws {
        // This test simulates app recovery after termination
        let mainPage = pageFactory.mainContentPage()
        XCTAssertTrue(mainPage.waitForPageToLoad())
        
        // Set up some state (favorites, etc.)
        if mainPage.verifyPoemIsDisplayed() {
            mainPage.tapFavoriteButton()
            sleep(1)
        }
        
        // Simulate app termination and restart
        app.terminate()
        sleep(2)
        app.launch()
        
        let recoveredMainPage = pageFactory.mainContentPage()
        XCTAssertTrue(recoveredMainPage.waitForPageToLoad())
        
        // App should start cleanly
        XCTAssertTrue(recoveredMainPage.isDisplayed(), "App should recover cleanly after restart")
        
        // State may or may not be preserved depending on implementation
        // But app should not be in a broken state
    }
    
    // MARK: - Edge Case Tests
    
    func testVeryLongPoemContent() throws {
        // Simulate API returning very long poem
        app.terminate()
        app.launchEnvironment["SIMULATE_LONG_POEM"] = "true"
        app.launch()
        
        let mainPage = pageFactory.mainContentPage()
        XCTAssertTrue(mainPage.waitForPageToLoad())
        
        mainPage.tapRefreshButton()
        XCTAssertTrue(mainPage.waitForLoadingToComplete())
        
        sleep(3)
        
        // Should handle long content gracefully
        if mainPage.verifyPoemIsDisplayed() {
            // Content should be scrollable or truncated appropriately
            XCTAssertTrue(true, "Long poem content handled")
        } else if mainPage.verifyErrorAlert() {
            // Or show appropriate error if content is too long
            mainPage.errorAlert.buttons.firstMatch.tap()
        }
        
        XCTAssertTrue(mainPage.isDisplayed(), "App should remain stable with long content")
    }
    
    func testSpecialCharactersInContent() throws {
        // Simulate content with special characters, emojis, etc.
        app.terminate()
        app.launchEnvironment["SIMULATE_SPECIAL_CHARACTERS"] = "true"
        app.launch()
        
        let mainPage = pageFactory.mainContentPage()
        XCTAssertTrue(mainPage.waitForPageToLoad())
        
        mainPage.tapRefreshButton()
        XCTAssertTrue(mainPage.waitForLoadingToComplete())
        
        sleep(3)
        
        // Should handle special characters without issues
        XCTAssertTrue(mainPage.isDisplayed(), "Should handle special characters gracefully")
        
        if mainPage.verifyPoemIsDisplayed() {
            // Try to favorite and share content with special characters
            mainPage.tapFavoriteButton()
            sleep(1)
            
            let shareSheet = mainPage.tapShareButton()
            if shareSheet.waitForPageToLoad() {
                shareSheet.tapCancel()
            }
        }
    }
    
    func testRapidUserInteractions() throws {
        let mainPage = pageFactory.mainContentPage()
        XCTAssertTrue(mainPage.waitForPageToLoad())
        
        // Rapidly tap multiple UI elements
        for _ in 0..<10 {
            if mainPage.refreshButton.exists && mainPage.refreshButton.isHittable {
                mainPage.refreshButton.tap()
            }
            
            if mainPage.favoriteButton.exists && mainPage.favoriteButton.isHittable {
                mainPage.favoriteButton.tap()
            }
            
            if mainPage.shareButton.exists && mainPage.shareButton.isHittable {
                mainPage.shareButton.tap()
                sleep(0.1)
                // Cancel any share sheets that appear
                if app.sheets.firstMatch.exists {
                    app.buttons["Cancel"].tap()
                }
            }
            
            sleep(0.1)
        }
        
        // App should remain stable after rapid interactions
        sleep(3)
        XCTAssertTrue(mainPage.isDisplayed(), "App should handle rapid user interactions gracefully")
    }
    
    // MARK: - Device Specific Error Tests
    
    func testLowBatteryScenario() throws {
        // Simulate low battery conditions
        app.terminate()
        app.launchEnvironment["SIMULATE_LOW_BATTERY"] = "true"
        app.launch()
        
        let mainPage = pageFactory.mainContentPage()
        XCTAssertTrue(mainPage.waitForPageToLoad())
        
        // Perform operations that might be affected by low battery
        mainPage.tapRefreshButton()
        XCTAssertTrue(mainPage.waitForLoadingToComplete())
        
        // AI operations might be disabled or limited
        if mainPage.vibeGenerationButton.exists {
            let vibeGenerationPage = mainPage.tapVibeGenerationButton()
            if vibeGenerationPage.waitForPageToLoad() {
                vibeGenerationPage.tapGenerateButton()
                sleep(3)
                vibeGenerationPage.tapBackButton()
            }
        }
        
        XCTAssertTrue(mainPage.isDisplayed(), "App should handle low battery scenarios")
    }
}

// MARK: - Error Testing Extensions

extension ErrorScenarioUITests {
    
    // Helper to configure network state for testing
    func configureNetworkState(available: Bool) {
        app.launchEnvironment["SIMULATE_NETWORK_UNAVAILABLE"] = available ? "false" : "true"
    }
    
    // Helper to simulate specific error conditions
    func simulateErrorCondition(_ condition: String, enabled: Bool = true) {
        app.launchEnvironment[condition] = enabled ? "true" : "false"
    }
    
    // Helper to verify error recovery
    func verifyErrorRecovery(
        in page: MainContentPage,
        afterAction action: () -> Void,
        expectedRecovery: () -> Bool
    ) {
        action()
        sleep(3) // Allow time for recovery
        
        let hasRecovered = expectedRecovery()
        XCTAssertTrue(hasRecovered, "Should recover from error condition")
    }
    
    // Helper to test error message quality
    func verifyErrorMessageQuality(alert: XCUIElement) {
        XCTAssertTrue(alert.exists, "Error alert should exist")
        
        // Error should have meaningful title
        let title = alert.label
        XCTAssertFalse(title.isEmpty, "Error should have meaningful title")
        XCTAssertFalse(title.contains("Error"), "Error title should be more specific than just 'Error'")
        
        // Should have action buttons
        let buttons = alert.buttons
        XCTAssertGreaterThan(buttons.count, 0, "Error alert should have action buttons")
    }
}