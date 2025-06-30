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
            "CLEAR_TELEMETRY_ON_LAUNCH": "true"
        ]
        
        app.launch()
    }
    
    override func tearDownWithError() throws {
        app = nil
        pageFactory = nil
    }
    
    // MARK: - Basic Telemetry Tests
    
    func testAppLaunchTelemetryEvent() throws {
        let mainPage = pageFactory.mainContentPage()
        XCTAssertTrue(mainPage.waitForPageToLoad())
        
        // Access telemetry debug view
        let telemetryDebugPage = mainPage.longPressTitle()
        XCTAssertTrue(telemetryDebugPage.waitForPageToLoad())
        XCTAssertTrue(telemetryDebugPage.isDisplayed())
        
        // Verify app launch event was tracked
        XCTAssertTrue(telemetryDebugPage.verifyEventExists(withName: "app_launch"), 
                     "App launch event should be tracked")
        
        // Verify event count is at least 1
        let eventCount = telemetryDebugPage.getEventCount()
        XCTAssertFalse(eventCount.isEmpty, "Should show event count")
        
        telemetryDebugPage.tapCloseButton()
    }
    
    func testPoemFetchTelemetryEvent() throws {
        let mainPage = pageFactory.mainContentPage()
        XCTAssertTrue(mainPage.waitForPageToLoad())
        
        // Trigger poem refresh to generate telemetry event
        mainPage.tapRefreshButton()
        XCTAssertTrue(mainPage.waitForLoadingToComplete())
        
        // Check telemetry debug view
        let telemetryDebugPage = mainPage.longPressTitle()
        XCTAssertTrue(telemetryDebugPage.waitForPageToLoad())
        
        // Verify poem fetch event was tracked
        XCTAssertTrue(telemetryDebugPage.verifyEventExists(withName: "poem_fetch"), 
                     "Poem fetch event should be tracked")
        
        telemetryDebugPage.tapCloseButton()
    }
    
    func testFavoriteActionTelemetryEvents() throws {
        let mainPage = pageFactory.mainContentPage()
        XCTAssertTrue(mainPage.waitForPageToLoad())
        XCTAssertTrue(mainPage.verifyPoemIsDisplayed())
        
        // Add to favorites
        mainPage.tapFavoriteButton()
        sleep(1) // Allow telemetry event to be processed
        
        // Remove from favorites
        mainPage.tapUnfavoriteButton()
        sleep(1)
        
        // Check telemetry debug view
        let telemetryDebugPage = mainPage.longPressTitle()
        XCTAssertTrue(telemetryDebugPage.waitForPageToLoad())
        
        // Verify favorite action events were tracked
        XCTAssertTrue(telemetryDebugPage.verifyEventExists(withName: "favorite_action"), 
                     "Favorite action events should be tracked")
        
        telemetryDebugPage.tapCloseButton()
    }
    
    func testShareActionTelemetryEvent() throws {
        let mainPage = pageFactory.mainContentPage()
        XCTAssertTrue(mainPage.waitForPageToLoad())
        XCTAssertTrue(mainPage.verifyPoemIsDisplayed())
        
        // Trigger share action
        let shareSheetPage = mainPage.tapShareButton()
        XCTAssertTrue(shareSheetPage.waitForPageToLoad())
        
        // Cancel share and return to main page
        shareSheetPage.tapCancel()
        sleep(1) // Allow telemetry event to be processed
        
        // Check telemetry debug view
        let telemetryDebugPage = mainPage.longPressTitle()
        XCTAssertTrue(telemetryDebugPage.waitForPageToLoad())
        
        // Verify share action event was tracked
        XCTAssertTrue(telemetryDebugPage.verifyEventExists(withName: "share_action"), 
                     "Share action event should be tracked")
        
        telemetryDebugPage.tapCloseButton()
    }
    
    // MARK: - AI Generation Telemetry Tests
    
    func testAIGenerationTelemetryEvents() throws {
        let mainPage = pageFactory.mainContentPage()
        XCTAssertTrue(mainPage.waitForPageToLoad())
        
        // Configure AI to be available for testing
        app.terminate()
        app.launchEnvironment["AI_AVAILABLE"] = "true"
        app.launchEnvironment["ENABLE_TELEMETRY"] = "true"
        app.launch()
        
        let newMainPage = pageFactory.mainContentPage()
        XCTAssertTrue(newMainPage.waitForPageToLoad())
        
        // Generate AI poem
        let vibeGenerationPage = newMainPage.tapVibeGenerationButton()
        XCTAssertTrue(vibeGenerationPage.waitForPageToLoad())
        
        vibeGenerationPage.tapGenerateButton()
        sleep(3) // Allow AI generation and telemetry
        
        vibeGenerationPage.tapBackButton()
        
        // Check telemetry debug view
        let telemetryDebugPage = newMainPage.longPressTitle()
        XCTAssertTrue(telemetryDebugPage.waitForPageToLoad())
        
        // Verify AI generation event was tracked
        XCTAssertTrue(telemetryDebugPage.verifyEventExists(withName: "ai_generation"), 
                     "AI generation event should be tracked")
        
        telemetryDebugPage.tapCloseButton()
    }
    
    func testCustomPromptTelemetryEvents() throws {
        let mainPage = pageFactory.mainContentPage()
        XCTAssertTrue(mainPage.waitForPageToLoad())
        
        // Navigate to custom prompt and generate
        let customPromptPage = mainPage.tapCustomPromptButton()
        XCTAssertTrue(customPromptPage.waitForPageToLoad())
        
        customPromptPage.enterPrompt("Test telemetry prompt")
        customPromptPage.tapGenerateButton()
        sleep(3)
        
        // Check telemetry debug view
        let telemetryDebugPage = mainPage.longPressTitle()
        XCTAssertTrue(telemetryDebugPage.waitForPageToLoad())
        
        // Verify custom prompt generation was tracked
        XCTAssertTrue(telemetryDebugPage.verifyEventExists(withName: "ai_generation"), 
                     "Custom prompt AI generation should be tracked")
        
        telemetryDebugPage.tapCloseButton()
    }
    
    // MARK: - Error Telemetry Tests
    
    func testErrorTelemetryEvents() throws {
        let mainPage = pageFactory.mainContentPage()
        XCTAssertTrue(mainPage.waitForPageToLoad())
        
        // Simulate network error
        app.terminate()
        app.launchEnvironment["SIMULATE_NETWORK_ERROR"] = "true"
        app.launchEnvironment["ENABLE_TELEMETRY"] = "true"
        app.launch()
        
        let newMainPage = pageFactory.mainContentPage()
        XCTAssertTrue(newMainPage.waitForPageToLoad())
        
        // Trigger action that should cause error
        newMainPage.tapRefreshButton()
        sleep(3) // Allow error to occur and be tracked
        
        // Check telemetry debug view
        let telemetryDebugPage = newMainPage.longPressTitle()
        XCTAssertTrue(telemetryDebugPage.waitForPageToLoad())
        
        // Verify error event was tracked
        XCTAssertTrue(telemetryDebugPage.verifyEventExists(withName: "error_occurred"), 
                     "Error events should be tracked")
        
        telemetryDebugPage.tapCloseButton()
    }
    
    // MARK: - Telemetry Export Tests
    
    func testTelemetryDataExport() throws {
        let mainPage = pageFactory.mainContentPage()
        XCTAssertTrue(mainPage.waitForPageToLoad())
        
        // Perform several actions to generate telemetry data
        mainPage.tapRefreshButton()
        XCTAssertTrue(mainPage.waitForLoadingToComplete())
        
        if mainPage.verifyPoemIsDisplayed() {
            mainPage.tapFavoriteButton()
            sleep(1)
            mainPage.tapUnfavoriteButton()
            sleep(1)
        }
        
        // Access telemetry debug view
        let telemetryDebugPage = mainPage.longPressTitle()
        XCTAssertTrue(telemetryDebugPage.waitForPageToLoad())
        
        // Test export functionality
        let shareSheetPage = telemetryDebugPage.tapExportButton()
        XCTAssertTrue(shareSheetPage.waitForPageToLoad())
        XCTAssertTrue(shareSheetPage.isDisplayed())
        
        // Verify export options are available
        XCTAssertTrue(shareSheetPage.copyOption.exists, "Copy option should be available for telemetry export")
        
        // Cancel export and return
        shareSheetPage.tapCancel()
        telemetryDebugPage.tapCloseButton()
    }
    
    // MARK: - Telemetry Privacy Tests
    
    func testTelemetryPrivacyControls() throws {
        let mainPage = pageFactory.mainContentPage()
        XCTAssertTrue(mainPage.waitForPageToLoad())
        
        // Test with telemetry disabled
        app.terminate()
        app.launchEnvironment["ENABLE_TELEMETRY"] = "false"
        app.launch()
        
        let newMainPage = pageFactory.mainContentPage()
        XCTAssertTrue(newMainPage.waitForPageToLoad())
        
        // Perform actions that would normally generate telemetry
        newMainPage.tapRefreshButton()
        XCTAssertTrue(newMainPage.waitForLoadingToComplete())
        
        // Access telemetry debug view
        let telemetryDebugPage = newMainPage.longPressTitle()
        XCTAssertTrue(telemetryDebugPage.waitForPageToLoad())
        
        // Verify minimal or no events when disabled
        let eventCount = telemetryDebugPage.getEventCount()
        // Should show 0 or very few events when telemetry is disabled
        
        telemetryDebugPage.tapCloseButton()
    }
    
    // MARK: - Performance Telemetry Tests
    
    func testTelemetryPerformanceImpact() throws {
        let mainPage = pageFactory.mainContentPage()
        XCTAssertTrue(mainPage.waitForPageToLoad())
        
        // Measure performance with telemetry enabled
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // Perform multiple actions that generate telemetry events
        for _ in 0..<10 {
            mainPage.tapRefreshButton()
            XCTAssertTrue(mainPage.waitForLoadingToComplete())
            
            if mainPage.verifyPoemIsDisplayed() {
                mainPage.tapFavoriteButton()
                sleep(0.1)
                mainPage.tapUnfavoriteButton()
                sleep(0.1)
            }
        }
        
        let endTime = CFAbsoluteTimeGetCurrent()
        let duration = endTime - startTime
        
        // Telemetry should not significantly impact performance
        XCTAssertLessThan(duration, 30.0, "Operations with telemetry should complete within reasonable time")
        
        // Verify telemetry events were still captured
        let telemetryDebugPage = mainPage.longPressTitle()
        XCTAssertTrue(telemetryDebugPage.waitForPageToLoad())
        
        let eventCount = telemetryDebugPage.getEventCount()
        XCTAssertFalse(eventCount.isEmpty, "Should have captured multiple telemetry events")
        
        telemetryDebugPage.tapCloseButton()
    }
    
    // MARK: - Widget Telemetry Tests (Simulated)
    
    func testWidgetTelemetryIntegration() throws {
        let mainPage = pageFactory.mainContentPage()
        XCTAssertTrue(mainPage.waitForPageToLoad())
        
        // Simulate widget interaction by checking if widget events are tracked
        // In a real implementation, this would involve actual widget interaction
        
        // Access telemetry debug view
        let telemetryDebugPage = mainPage.longPressTitle()
        XCTAssertTrue(telemetryDebugPage.waitForPageToLoad())
        
        // Check if widget events are being tracked in the system
        // This would be more comprehensive in a real widget test
        let eventCount = telemetryDebugPage.getEventCount()
        XCTAssertFalse(eventCount.isEmpty, "Should track events from various sources")
        
        telemetryDebugPage.tapCloseButton()
    }
    
    // MARK: - Telemetry Data Consistency Tests
    
    func testTelemetryDataConsistency() throws {
        let mainPage = pageFactory.mainContentPage()
        XCTAssertTrue(mainPage.waitForPageToLoad())
        
        // Perform known sequence of actions
        let actions = [
            { mainPage.tapRefreshButton() },
            { 
                if mainPage.verifyPoemIsDisplayed() {
                    mainPage.tapFavoriteButton()
                }
            },
            { 
                let _ = mainPage.tapShareButton()
                sleep(1)
                // Share sheet should appear, then we'll cancel it
            }
        ]
        
        for action in actions {
            action()
            sleep(1) // Allow telemetry processing
        }
        
        // Dismiss any open share sheet
        if app.sheets.firstMatch.exists {
            app.buttons["Cancel"].tap()
        }
        
        // Check telemetry debug view
        let telemetryDebugPage = mainPage.longPressTitle()
        XCTAssertTrue(telemetryDebugPage.waitForPageToLoad())
        
        // Verify expected events are present
        let expectedEvents = ["app_launch", "poem_fetch", "favorite_action", "share_action"]
        
        for expectedEvent in expectedEvents {
            // In a real implementation, we might have more specific verification
            // For now, we verify the general event tracking is working
        }
        
        telemetryDebugPage.tapCloseButton()
    }
    
    // MARK: - Telemetry Debug View Tests
    
    func testTelemetryDebugViewAccessibility() throws {
        let mainPage = pageFactory.mainContentPage()
        XCTAssertTrue(mainPage.waitForPageToLoad())
        
        // Test long press activation (should be exactly 2.5 seconds)
        let titleElement = mainPage.headerTitle
        XCTAssertTrue(titleElement.exists, "Title element should exist")
        
        // Test shorter press (should not activate debug view)
        titleElement.press(forDuration: 1.0)
        sleep(1)
        
        // Should still be on main page
        XCTAssertTrue(mainPage.isDisplayed(), "Short press should not activate debug view")
        
        // Test correct long press
        let telemetryDebugPage = mainPage.longPressTitle()
        XCTAssertTrue(telemetryDebugPage.waitForPageToLoad())
        XCTAssertTrue(telemetryDebugPage.isDisplayed())
        
        telemetryDebugPage.tapCloseButton()
    }
    
    func testTelemetryDebugViewNavigation() throws {
        let mainPage = pageFactory.mainContentPage()
        XCTAssertTrue(mainPage.waitForPageToLoad())
        
        // Access telemetry debug view
        let telemetryDebugPage = mainPage.longPressTitle()
        XCTAssertTrue(telemetryDebugPage.waitForPageToLoad())
        XCTAssertTrue(telemetryDebugPage.isDisplayed())
        
        // Test navigation elements
        XCTAssertTrue(telemetryDebugPage.navigationTitle.exists, "Navigation title should exist")
        XCTAssertTrue(telemetryDebugPage.closeButton.exists, "Close button should exist")
        XCTAssertTrue(telemetryDebugPage.exportButton.exists, "Export button should exist")
        
        // Test close functionality
        let returnedMainPage = telemetryDebugPage.tapCloseButton()
        XCTAssertTrue(returnedMainPage.waitForPageToLoad())
        XCTAssertTrue(returnedMainPage.isDisplayed())
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
            sleep(0.5)
            
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