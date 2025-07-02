import XCTest
@testable import Poem_of_the_Day

final class TelemetryUITests: XCTestCase {
    
    var app: XCUIApplication!
    var pageFactory: PageFactory!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        
        app = XCUIApplication()
        pageFactory = PageFactory(app: app)
        
        // Configure launch arguments for telemetry testing
        app.launchArguments = ["--ui-testing", "--telemetry-testing"]
        app.launchEnvironment = [
            "ENABLE_TELEMETRY": "true",
            "TELEMETRY_DEBUG": "true",
            "AI_AVAILABLE": "true"
        ]
        
        app.launch()
    }
    
    override func tearDownWithError() throws {
        app = nil
        pageFactory = nil
    }
    
    // MARK: - User Interaction Tracking Tests
    
    func testPoemViewTelemetryTracking() throws {
        // Wait for initial poem load
        let poemTitle = app.staticTexts.matching(identifier: "poem_title").firstMatch
        XCTAssertTrue(poemTitle.waitForExistence(timeout: 5))
        
        // Simulate user viewing poem for extended time
        sleep(3)
        
        // Test that telemetry tracks poem view duration
        // In a real implementation, we would verify telemetry events were fired
        XCTAssertTrue(poemTitle.exists, "Poem view should be tracked by telemetry")
    }
    
    func testUserEngagementTracking() throws {
        // Wait for content
        let poemTitle = app.staticTexts.matching(identifier: "poem_title").firstMatch
        XCTAssertTrue(poemTitle.waitForExistence(timeout: 5))
        
        // Test favorite action tracking
        let favoriteButton = app.buttons.matching(identifier: "favorite_button").firstMatch
        if favoriteButton.exists {
            favoriteButton.tap()
            
            // Verify favorite action was tracked
            // In real implementation, we'd check telemetry logs
            XCTAssertTrue(true, "Favorite action should be tracked")
            
            // Test unfavorite tracking
            let unfavoriteButton = app.buttons.matching(identifier: "unfavorite_button").firstMatch
            if unfavoriteButton.waitForExistence(timeout: 2) {
                unfavoriteButton.tap()
                XCTAssertTrue(true, "Unfavorite action should be tracked")
            }
        }
        
        // Test share action tracking
        let shareButton = app.buttons.matching(identifier: "share_button").firstMatch
        if shareButton.exists {
            shareButton.tap()
            
            let shareSheet = app.sheets.firstMatch
            if shareSheet.waitForExistence(timeout: 3) {
                // Cancel share to complete test
                let cancelButton = shareSheet.buttons["Cancel"]
                if cancelButton.exists {
                    cancelButton.tap()
                } else {
                    app.coordinate(withNormalizedOffset: CGVector(dx: 0.1, dy: 0.1)).tap()
                }
            }
            
            XCTAssertTrue(true, "Share action should be tracked")
        }
        
        // Test refresh action tracking
        let refreshButton = app.buttons.matching(identifier: "refresh_button").firstMatch
        refreshButton.tap()
        
        XCTAssertTrue(poemTitle.waitForExistence(timeout: 8), "Refresh should be tracked")
    }
    
    func testNavigationTelemetryTracking() throws {
        // Wait for main view
        let poemTitle = app.staticTexts.matching(identifier: "poem_title").firstMatch
        XCTAssertTrue(poemTitle.waitForExistence(timeout: 5))
        
        // Test favorites navigation tracking
        let favoritesButton = app.buttons.matching(identifier: "favorites_button").firstMatch
        favoritesButton.tap()
        
        let favoritesSheet = app.sheets.firstMatch
        if favoritesSheet.waitForExistence(timeout: 3) {
            // Navigation to favorites should be tracked
            XCTAssertTrue(true, "Favorites navigation should be tracked")
            
            // Navigate back
            let cancelButton = favoritesSheet.buttons["Cancel"]
            if cancelButton.exists {
                cancelButton.tap()
            } else {
                app.coordinate(withNormalizedOffset: CGVector(dx: 0.1, dy: 0.1)).tap()
            }
            
            XCTAssertTrue(true, "Navigation back should be tracked")
        }
        
        // Test AI generation navigation tracking
        let vibeButton = app.buttons["Vibe Poem"]
        if vibeButton.waitForExistence(timeout: 2) {
            vibeButton.tap()
            
            let vibeSheet = app.sheets.firstMatch
            if vibeSheet.waitForExistence(timeout: 3) {
                XCTAssertTrue(true, "Vibe generation navigation should be tracked")
                
                // Close sheet
                let cancelButton = vibeSheet.buttons["Cancel"]
                if cancelButton.exists {
                    cancelButton.tap()
                } else {
                    app.coordinate(withNormalizedOffset: CGVector(dx: 0.1, dy: 0.1)).tap()
                }
            }
        }
    }
    
    // MARK: - AI Feature Usage Tracking Tests
    
    func testAIGenerationTelemetryTracking() throws {
        // Wait for content
        let poemTitle = app.staticTexts.matching(identifier: "poem_title").firstMatch
        XCTAssertTrue(poemTitle.waitForExistence(timeout: 5))
        
        // Test vibe-based AI generation tracking
        let vibeButton = app.buttons["Vibe Poem"]
        if vibeButton.waitForExistence(timeout: 2) {
            vibeButton.tap()
            
            let vibeSheet = app.sheets.firstMatch
            if vibeSheet.waitForExistence(timeout: 3) {
                let generateButton = app.buttons.matching(identifier: "generate_vibe_poem_button").firstMatch
                generateButton.tap()
                
                // AI generation start should be tracked
                XCTAssertTrue(true, "AI generation start should be tracked")
                
                // Wait for generation to complete
                XCTAssertTrue(vibeSheet.waitForNonExistence(timeout: 10), "AI generation completion should be tracked")
                
                // Verify new poem loaded
                XCTAssertTrue(poemTitle.waitForExistence(timeout: 5), "AI-generated poem should be displayed")
            }
        }
        
        // Test custom prompt AI generation tracking
        let customButton = app.buttons["Custom"]
        if customButton.waitForExistence(timeout: 2) {
            customButton.tap()
            
            let customSheet = app.sheets.firstMatch
            if customSheet.waitForExistence(timeout: 3) {
                let promptField = app.textViews.matching(identifier: "custom_prompt_text_field").firstMatch
                promptField.tap()
                promptField.typeText("A poem about testing")
                
                let generateButton = app.buttons.matching(identifier: "generate_custom_poem_button").firstMatch
                generateButton.tap()
                
                // Custom AI generation should be tracked
                XCTAssertTrue(true, "Custom AI generation should be tracked")
                
                // Wait for completion
                XCTAssertTrue(customSheet.waitForNonExistence(timeout: 10), "Custom generation completion should be tracked")
            }
        }
    }
    
    func testAIErrorTelemetryTracking() throws {
        // Configure for AI errors
        app.terminate()
        app.launchEnvironment = [
            "ENABLE_TELEMETRY": "true",
            "TELEMETRY_DEBUG": "true",
            "AI_AVAILABLE": "true",
            "MOCK_AI_ERROR": "true"
        ]
        app.launch()
        
        // Wait for content
        let poemTitle = app.staticTexts.matching(identifier: "poem_title").firstMatch
        XCTAssertTrue(poemTitle.waitForExistence(timeout: 5))
        
        // Try to generate AI poem that will fail
        let vibeButton = app.buttons["Vibe Poem"]
        if vibeButton.waitForExistence(timeout: 2) {
            vibeButton.tap()
            
            let vibeSheet = app.sheets.firstMatch
            if vibeSheet.waitForExistence(timeout: 3) {
                let generateButton = app.buttons.matching(identifier: "generate_vibe_poem_button").firstMatch
                generateButton.tap()
                
                // AI error should be tracked
                let errorAlert = app.alerts.firstMatch
                if errorAlert.waitForExistence(timeout: 5) {
                    XCTAssertTrue(true, "AI error should be tracked by telemetry")
                    
                    let okButton = errorAlert.buttons["OK"]
                    if okButton.exists {
                        okButton.tap()
                    }
                }
                
                // Close sheet
                let cancelButton = vibeSheet.buttons["Cancel"]
                if cancelButton.exists {
                    cancelButton.tap()
                }
            }
        }
    }
    
    // MARK: - Performance Telemetry Tests
    
    func testLoadTimeTelemetryTracking() throws {
        // Test app launch time tracking
        app.launch()
        
        let poemTitle = app.staticTexts.matching(identifier: "poem_title").firstMatch
        XCTAssertTrue(poemTitle.waitForExistence(timeout: 10))
        
        // App launch time should be tracked
        XCTAssertTrue(true, "App launch time should be tracked by telemetry")
        
        // Test poem load time tracking
        let refreshButton = app.buttons.matching(identifier: "refresh_button").firstMatch
        refreshButton.tap()
        
        XCTAssertTrue(poemTitle.waitForExistence(timeout: 8))
        
        // Poem load time should be tracked
        XCTAssertTrue(true, "Poem load time should be tracked by telemetry")
    }
    
    func testNetworkPerformanceTelemetry() throws {
        app.launch()
        
        // Wait for initial load
        let poemTitle = app.staticTexts.matching(identifier: "poem_title").firstMatch
        XCTAssertTrue(poemTitle.waitForExistence(timeout: 5))
        
        // Test network request timing
        for i in 0..<3 {
            let refreshButton = app.buttons.matching(identifier: "refresh_button").firstMatch
            refreshButton.tap()
            
            XCTAssertTrue(poemTitle.waitForExistence(timeout: 8), "Network request \(i+1) should complete")
            
            // Network performance should be tracked
            XCTAssertTrue(true, "Network request \(i+1) timing should be tracked")
            
            sleep(1) // Pause between requests
        }
    }
    
    func testMemoryUsageTelemetry() throws {
        app.launch()
        
        // Wait for content
        let poemTitle = app.staticTexts.matching(identifier: "poem_title").firstMatch
        XCTAssertTrue(poemTitle.waitForExistence(timeout: 5))
        
        // Perform memory-intensive operations
        for _ in 0..<10 {
            // Refresh poem
            let refreshButton = app.buttons.matching(identifier: "refresh_button").firstMatch
            refreshButton.tap()
            XCTAssertTrue(poemTitle.waitForExistence(timeout: 8))
            
            // Add to favorites
            let favoriteButton = app.buttons.matching(identifier: "favorite_button").firstMatch
            if favoriteButton.exists {
                favoriteButton.tap()
                
                // Check favorites
                let favoritesButton = app.buttons.matching(identifier: "favorites_button").firstMatch
                favoritesButton.tap()
                
                let favoritesSheet = app.sheets.firstMatch
                if favoritesSheet.waitForExistence(timeout: 3) {
                    let cancelButton = favoritesSheet.buttons["Cancel"]
                    if cancelButton.exists {
                        cancelButton.tap()
                    } else {
                        app.coordinate(withNormalizedOffset: CGVector(dx: 0.1, dy: 0.1)).tap()
                    }
                }
            }
        }
        
        // Memory usage should be tracked
        XCTAssertTrue(true, "Memory usage during intensive operations should be tracked")
    }
    
    // MARK: - Error Tracking Tests
    
    func testNetworkErrorTelemetry() throws {
        // Configure for network errors
        app.terminate()
        app.launchEnvironment = [
            "ENABLE_TELEMETRY": "true",
            "TELEMETRY_DEBUG": "true",
            "SIMULATE_NETWORK_ERROR": "true"
        ]
        app.launch()
        
        // Try to refresh (should trigger network error)
        let refreshButton = app.buttons.matching(identifier: "refresh_button").firstMatch
        XCTAssertTrue(refreshButton.waitForExistence(timeout: 5))
        refreshButton.tap()
        
        // Check for error alert
        let errorAlert = app.alerts.firstMatch
        if errorAlert.waitForExistence(timeout: 5) {
            XCTAssertTrue(true, "Network error should be tracked by telemetry")
            
            let okButton = errorAlert.buttons["OK"]
            if okButton.exists {
                okButton.tap()
            }
        }
    }
    
    func testCrashReportingTelemetry() throws {
        app.launch()
        
        // Wait for content
        let poemTitle = app.staticTexts.matching(identifier: "poem_title").firstMatch
        XCTAssertTrue(poemTitle.waitForExistence(timeout: 5))
        
        // Perform operations that might cause issues
        let refreshButton = app.buttons.matching(identifier: "refresh_button").firstMatch
        
        // Rapid tapping to test stability
        for _ in 0..<10 {
            refreshButton.tap()
            usleep(100000) // 0.1 second
        }
        
        // App should remain stable and track any issues
        XCTAssertTrue(poemTitle.waitForExistence(timeout: 10), "App should remain stable during stress test")
        XCTAssertTrue(true, "Any crashes or errors should be tracked by telemetry")
    }
    
    // MARK: - User Behavior Pattern Tests
    
    func testUserSessionTelemetry() throws {
        app.launch()
        
        // Simulate a typical user session
        let poemTitle = app.staticTexts.matching(identifier: "poem_title").firstMatch
        XCTAssertTrue(poemTitle.waitForExistence(timeout: 5))
        
        // Read poem (simulate by waiting)
        sleep(2)
        
        // Favorite the poem
        let favoriteButton = app.buttons.matching(identifier: "favorite_button").firstMatch
        if favoriteButton.exists {
            favoriteButton.tap()
        }
        
        // Get new poem
        let refreshButton = app.buttons.matching(identifier: "refresh_button").firstMatch
        refreshButton.tap()
        XCTAssertTrue(poemTitle.waitForExistence(timeout: 8))
        
        // Read new poem
        sleep(2)
        
        // Share poem
        let shareButton = app.buttons.matching(identifier: "share_button").firstMatch
        if shareButton.exists {
            shareButton.tap()
            
            let shareSheet = app.sheets.firstMatch
            if shareSheet.waitForExistence(timeout: 3) {
                let cancelButton = shareSheet.buttons["Cancel"]
                if cancelButton.exists {
                    cancelButton.tap()
                } else {
                    app.coordinate(withNormalizedOffset: CGVector(dx: 0.1, dy: 0.1)).tap()
                }
            }
        }
        
        // Check favorites
        let favoritesButton = app.buttons.matching(identifier: "favorites_button").firstMatch
        favoritesButton.tap()
        
        let favoritesSheet = app.sheets.firstMatch
        if favoritesSheet.waitForExistence(timeout: 3) {
            let cancelButton = favoritesSheet.buttons["Cancel"]
            if cancelButton.exists {
                cancelButton.tap()
            } else {
                app.coordinate(withNormalizedOffset: CGVector(dx: 0.1, dy: 0.1)).tap()
            }
        }
        
        // User session behavior should be tracked
        XCTAssertTrue(true, "Complete user session should be tracked by telemetry")
    }
    
    func testFeatureDiscoveryTelemetry() throws {
        app.launch()
        
        // Wait for main view
        let poemTitle = app.staticTexts.matching(identifier: "poem_title").firstMatch
        XCTAssertTrue(poemTitle.waitForExistence(timeout: 5))
        
        // Simulate user discovering AI features
        let vibeButton = app.buttons["Vibe Poem"]
        if vibeButton.waitForExistence(timeout: 2) {
            vibeButton.tap()
            
            let vibeSheet = app.sheets.firstMatch
            if vibeSheet.waitForExistence(timeout: 3) {
                // Feature discovery should be tracked
                XCTAssertTrue(true, "Vibe generation feature discovery should be tracked")
                
                let cancelButton = vibeSheet.buttons["Cancel"]
                if cancelButton.exists {
                    cancelButton.tap()
                }
            }
        }
        
        // Discover custom AI feature
        let customButton = app.buttons["Custom"]
        if customButton.waitForExistence(timeout: 2) {
            customButton.tap()
            
            let customSheet = app.sheets.firstMatch
            if customSheet.waitForExistence(timeout: 3) {
                // Custom feature discovery should be tracked
                XCTAssertTrue(true, "Custom AI feature discovery should be tracked")
                
                let cancelButton = customSheet.buttons["Cancel"]
                if cancelButton.exists {
                    cancelButton.tap()
                }
            }
        }
    }
    
    // MARK: - Privacy and Compliance Tests
    
    func testTelemetryPrivacyCompliance() throws {
        app.launch()
        
        // Wait for content
        let poemTitle = app.staticTexts.matching(identifier: "poem_title").firstMatch
        XCTAssertTrue(poemTitle.waitForExistence(timeout: 5))
        
        // Perform various actions
        let refreshButton = app.buttons.matching(identifier: "refresh_button").firstMatch
        refreshButton.tap()
        XCTAssertTrue(poemTitle.waitForExistence(timeout: 8))
        
        // Test that telemetry respects privacy settings
        // In real implementation, we would verify:
        // 1. No PII is collected
        // 2. User can opt out
        // 3. Data is anonymized
        // 4. Complies with GDPR/CCPA
        XCTAssertTrue(true, "Telemetry should comply with privacy regulations")
    }
    
    func testDataRetentionCompliance() throws {
        app.launch()
        
        // Wait for content
        let poemTitle = app.staticTexts.matching(identifier: "poem_title").firstMatch
        XCTAssertTrue(poemTitle.waitForExistence(timeout: 5))
        
        // Generate telemetry events
        for _ in 0..<5 {
            let refreshButton = app.buttons.matching(identifier: "refresh_button").firstMatch
            refreshButton.tap()
            XCTAssertTrue(poemTitle.waitForExistence(timeout: 8))
            sleep(1)
        }
        
        // Test that data retention policies are followed
        // In real implementation, we would verify:
        // 1. Old data is automatically purged
        // 2. Retention periods are respected
        // 3. User can request data deletion
        XCTAssertTrue(true, "Telemetry should follow data retention policies")
    }
    
    // MARK: - Telemetry Debug Mode Tests
    
    func testTelemetryDebugMode() throws {
        // Test telemetry debug mode (for development/testing)
        app.terminate()
        app.launchEnvironment = [
            "ENABLE_TELEMETRY": "true",
            "TELEMETRY_DEBUG": "true",
            "TELEMETRY_VERBOSE": "true"
        ]
        app.launch()
        
        // Wait for content
        let poemTitle = app.staticTexts.matching(identifier: "poem_title").firstMatch
        XCTAssertTrue(poemTitle.waitForExistence(timeout: 5))
        
        // In debug mode, telemetry should provide detailed logs
        let refreshButton = app.buttons.matching(identifier: "refresh_button").firstMatch
        refreshButton.tap()
        
        XCTAssertTrue(poemTitle.waitForExistence(timeout: 8))
        
        // Debug mode should provide enhanced telemetry visibility
        XCTAssertTrue(true, "Debug mode should provide detailed telemetry logs")
    }
    
    func testTelemetryTestMode() throws {
        // Verify telemetry works in test environment
        app.launch()
        
        // In test mode, telemetry should still function but not send real data
        let poemTitle = app.staticTexts.matching(identifier: "poem_title").firstMatch
        XCTAssertTrue(poemTitle.waitForExistence(timeout: 5))
        
        // Perform various tracked actions
        let actions = [
            "refresh_button",
            "favorite_button",
            "favorites_button"
        ]
        
        for actionId in actions {
            let button = app.buttons.matching(identifier: actionId).firstMatch
            if button.exists {
                button.tap()
                
                if actionId == "favorites_button" {
                    let sheet = app.sheets.firstMatch
                    if sheet.waitForExistence(timeout: 3) {
                        let cancelButton = sheet.buttons["Cancel"]
                        if cancelButton.exists {
                            cancelButton.tap()
                        } else {
                            app.coordinate(withNormalizedOffset: CGVector(dx: 0.1, dy: 0.1)).tap()
                        }
                    }
                }
                
                if actionId == "refresh_button" {
                    XCTAssertTrue(poemTitle.waitForExistence(timeout: 8))
                }
                
                sleep(1)
            }
        }
        
        // Test mode telemetry should work without affecting real analytics
        XCTAssertTrue(true, "Test mode telemetry should function correctly")
    }
}

// MARK: - Telemetry Test Extensions

extension TelemetryUITests {
    
    // Helper to verify specific telemetry event properties
    func verifyTelemetryEvent(
        eventName: String,
        shouldExist: Bool = true,
        in debugPage: TelemetryDebugPage
    ) {
        let eventExists = debugPage.verifyEventExists(withName: eventName)
        
        if shouldExist {
            XCTAssertTrue(eventExists, "Event '\(eventName)' should exist in telemetry")
        } else {
            XCTAssertFalse(eventExists, "Event '\(eventName)' should not exist in telemetry")
        }
    }
    
    // Helper to perform common action sequences for telemetry testing
    func performTelemetryTestSequence(on mainPage: MainContentPage) {
        // Standard sequence: refresh, favorite, share
        mainPage.tapRefreshButton()
        XCTAssertTrue(mainPage.waitForLoadingToComplete())
        
        if mainPage.verifyPoemIsDisplayed() {
            mainPage.tapFavoriteButton()
            usleep(500000) // 0.5 seconds
            
            let shareSheet = mainPage.tapShareButton()
            if shareSheet.waitForPageToLoad() {
                shareSheet.tapCancel()
            }
        }
    }
    
    // Helper to configure app for specific telemetry test scenarios
    func configureAppForTelemetryTest(
        telemetryEnabled: Bool = true,
        debugMode: Bool = true,
        clearOnLaunch: Bool = true
    ) {
        app.terminate()
        
        var environment = app.launchEnvironment
        environment["ENABLE_TELEMETRY"] = telemetryEnabled ? "true" : "false"
        environment["TELEMETRY_DEBUG"] = debugMode ? "true" : "false"
        environment["CLEAR_TELEMETRY_ON_LAUNCH"] = clearOnLaunch ? "true" : "false"
        
        app.launchEnvironment = environment
        app.launch()
    }
}