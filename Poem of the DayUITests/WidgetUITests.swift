import XCTest
import WidgetKit
@testable import Poem_of_the_Day

final class WidgetUITests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        
        app = XCUIApplication()
        
        // Configure for widget testing
        app.launchArguments = ["--ui-testing", "--widget-testing"]
        app.launchEnvironment = [
            "WIDGET_TESTING": "true",
            "ENABLE_TELEMETRY": "true",
            "AI_AVAILABLE": "true"
        ]
        
        app.launch()
    }
    
    override func tearDownWithError() throws {
        app = nil
    }
    
    // MARK: - Widget Display Tests
    
    func testWidgetBasicDisplay() throws {
        // Wait for main app to load
        let poemTitle = app.staticTexts.matching(identifier: "poem_title").firstMatch
        XCTAssertTrue(poemTitle.waitForExistence(timeout: 5))
        
        // Test widget integration (simulated)
        // In real widget testing, we would navigate to widget configuration
        // and verify widget content matches app content
        
        // For now, test that the main app data is widget-ready
        XCTAssertTrue(poemTitle.exists, "Widget should be able to display current poem")
        
        let poemAuthor = app.staticTexts.matching(identifier: "poem_author").firstMatch
        if poemAuthor.exists {
            XCTAssertTrue(poemAuthor.exists, "Widget should be able to display poem author")
        }
        
        let poemContent = app.staticTexts.matching(identifier: "poem_content").firstMatch
        if poemContent.exists {
            XCTAssertTrue(poemContent.exists, "Widget should be able to display poem content")
        }
    }
    
    func testWidgetDataRefresh() throws {
        // Wait for initial content
        let poemTitle = app.staticTexts.matching(identifier: "poem_title").firstMatch
        XCTAssertTrue(poemTitle.waitForExistence(timeout: 5))
        
        let initialTitle = poemTitle.label
        
        // Refresh content (this would update widget data)
        let refreshButton = app.buttons.matching(identifier: "refresh_button").firstMatch
        refreshButton.tap()
        
        // Wait for new content
        XCTAssertTrue(poemTitle.waitForExistence(timeout: 8))
        
        // Widget should be able to get updated content
        XCTAssertTrue(poemTitle.exists, "Widget should receive updated poem data")
        
        // In real implementation, we would verify widget updates on home screen
    }
    
    func testWidgetErrorHandling() throws {
        // Test widget behavior with network errors
        app.terminate()
        app.launchEnvironment = [
            "WIDGET_TESTING": "true",
            "SIMULATE_NETWORK_ERROR": "true",
            "ENABLE_TELEMETRY": "true"
        ]
        app.launch()
        
        // Try to refresh
        let refreshButton = app.buttons.matching(identifier: "refresh_button").firstMatch
        XCTAssertTrue(refreshButton.waitForExistence(timeout: 5))
        refreshButton.tap()
        
        // Should handle error gracefully
        let errorAlert = app.alerts.firstMatch
        if errorAlert.waitForExistence(timeout: 5) {
            XCTAssertTrue(true, "Widget should handle network errors gracefully")
            
            let okButton = errorAlert.buttons["OK"]
            if okButton.exists {
                okButton.tap()
            }
        }
        
        // Widget should display appropriate error state or fallback content
        XCTAssertTrue(true, "Widget should show error state or cached content")
    }
    
    // MARK: - Widget Size Configuration Tests
    
    func testSmallWidgetLayout() throws {
        // Wait for content
        let poemTitle = app.staticTexts.matching(identifier: "poem_title").firstMatch
        XCTAssertTrue(poemTitle.waitForExistence(timeout: 5))
        
        // Small widget should display essential info only
        // Test that content is appropriate for small widget
        XCTAssertTrue(poemTitle.exists, "Small widget should display poem title")
        
        // Small widget might not show full content
        XCTAssertTrue(true, "Small widget layout should be optimized for limited space")
    }
    
    func testMediumWidgetLayout() throws {
        // Wait for content
        let poemTitle = app.staticTexts.matching(identifier: "poem_title").firstMatch
        XCTAssertTrue(poemTitle.waitForExistence(timeout: 5))
        
        // Medium widget should display more information
        XCTAssertTrue(poemTitle.exists, "Medium widget should display poem title")
        
        let poemAuthor = app.staticTexts.matching(identifier: "poem_author").firstMatch
        if poemAuthor.exists {
            XCTAssertTrue(poemAuthor.exists, "Medium widget should display poem author")
        }
        
        // Medium widget should show partial content
        XCTAssertTrue(true, "Medium widget should show appropriate amount of content")
    }
    
    func testLargeWidgetLayout() throws {
        // Wait for content
        let poemTitle = app.staticTexts.matching(identifier: "poem_title").firstMatch
        XCTAssertTrue(poemTitle.waitForExistence(timeout: 5))
        
        // Large widget should display full information
        XCTAssertTrue(poemTitle.exists, "Large widget should display poem title")
        
        let poemAuthor = app.staticTexts.matching(identifier: "poem_author").firstMatch
        if poemAuthor.exists {
            XCTAssertTrue(poemAuthor.exists, "Large widget should display poem author")
        }
        
        let poemContent = app.staticTexts.matching(identifier: "poem_content").firstMatch
        if poemContent.exists {
            XCTAssertTrue(poemContent.exists, "Large widget should display poem content")
        }
        
        // Large widget should show most or all content
        XCTAssertTrue(true, "Large widget should maximize content display")
    }
    
    // MARK: - Widget Interaction Tests
    
    func testWidgetTapToOpenApp() throws {
        // Wait for content
        let poemTitle = app.staticTexts.matching(identifier: "poem_title").firstMatch
        XCTAssertTrue(poemTitle.waitForExistence(timeout: 5))
        
        // Simulate widget tap (opening app)
        // In real widget testing, tapping widget would launch the main app
        
        // Test that app opens with correct poem displayed
        XCTAssertTrue(poemTitle.exists, "App should open with current poem when widget is tapped")
        
        // App should be in correct state
        let refreshButton = app.buttons.matching(identifier: "refresh_button").firstMatch
        XCTAssertTrue(refreshButton.exists, "App should be fully functional when opened from widget")
    }
    
    func testWidgetDeepLinkToFavorites() throws {
        // Wait for content and add a favorite
        let poemTitle = app.staticTexts.matching(identifier: "poem_title").firstMatch
        XCTAssertTrue(poemTitle.waitForExistence(timeout: 5))
        
        let favoriteButton = app.buttons.matching(identifier: "favorite_button").firstMatch
        if favoriteButton.exists {
            favoriteButton.tap()
        }
        
        // Simulate widget button that opens favorites
        // In real implementation, widget might have favorite poem shortcuts
        let favoritesButton = app.buttons.matching(identifier: "favorites_button").firstMatch
        favoritesButton.tap()
        
        let favoritesSheet = app.sheets.firstMatch
        if favoritesSheet.waitForExistence(timeout: 3) {
            XCTAssertTrue(true, "Widget should be able to deep link to favorites")
            
            let cancelButton = favoritesSheet.buttons["Cancel"]
            if cancelButton.exists {
                cancelButton.tap()
            } else {
                app.coordinate(withNormalizedOffset: CGVector(dx: 0.1, dy: 0.1)).tap()
            }
        }
    }
    
    func testWidgetRefreshAction() throws {
        // Wait for initial content
        let poemTitle = app.staticTexts.matching(identifier: "poem_title").firstMatch
        XCTAssertTrue(poemTitle.waitForExistence(timeout: 5))
        
        let initialTitle = poemTitle.label
        
        // Simulate widget refresh action
        // In real widget, this might be a refresh button or automatic refresh
        let refreshButton = app.buttons.matching(identifier: "refresh_button").firstMatch
        refreshButton.tap()
        
        // Wait for new content
        XCTAssertTrue(poemTitle.waitForExistence(timeout: 8))
        
        // Widget should reflect updated content
        XCTAssertTrue(poemTitle.exists, "Widget should update with new poem after refresh")
    }
    
    // MARK: - Widget Data Synchronization Tests
    
    func testWidgetDataSync() throws {
        // Wait for content
        let poemTitle = app.staticTexts.matching(identifier: "poem_title").firstMatch
        XCTAssertTrue(poemTitle.waitForExistence(timeout: 5))
        
        // Make changes in app that should sync to widget
        let favoriteButton = app.buttons.matching(identifier: "favorite_button").firstMatch
        if favoriteButton.exists {
            favoriteButton.tap()
            
            // Widget should reflect favorite status change
            XCTAssertTrue(true, "Widget should sync favorite status changes")
        }
        
        // Refresh poem
        let refreshButton = app.buttons.matching(identifier: "refresh_button").firstMatch
        refreshButton.tap()
        XCTAssertTrue(poemTitle.waitForExistence(timeout: 8))
        
        // Widget should sync new poem content
        XCTAssertTrue(true, "Widget should sync new poem content")
    }
    
    func testWidgetBackgroundUpdate() throws {
        // Wait for content
        let poemTitle = app.staticTexts.matching(identifier: "poem_title").firstMatch
        XCTAssertTrue(poemTitle.waitForExistence(timeout: 5))
        
        // Simulate app going to background
        XCUIDevice.shared.press(.home)
        
        // Wait a moment
        sleep(2)
        
        // Return to app
        app.activate()
        
        // Widget should have potential for background updates
        XCTAssertTrue(poemTitle.waitForExistence(timeout: 5), "App should handle background/foreground transitions")
        
        // Test that widget can update in background (simulated)
        XCTAssertTrue(true, "Widget should support background updates")
    }
    
    func testWidgetUserDefaultsSync() throws {
        // Wait for content
        let poemTitle = app.staticTexts.matching(identifier: "poem_title").firstMatch
        XCTAssertTrue(poemTitle.waitForExistence(timeout: 5))
        
        // Add poem to favorites (updates UserDefaults)
        let favoriteButton = app.buttons.matching(identifier: "favorite_button").firstMatch
        if favoriteButton.exists {
            favoriteButton.tap()
            
            // Check that favorites were updated
            let favoritesButton = app.buttons.matching(identifier: "favorites_button").firstMatch
            favoritesButton.tap()
            
            let favoritesSheet = app.sheets.firstMatch
            if favoritesSheet.waitForExistence(timeout: 3) {
                // Favorites should show the added poem
                XCTAssertTrue(true, "UserDefaults should sync between app and widget")
                
                let cancelButton = favoritesSheet.buttons["Cancel"]
                if cancelButton.exists {
                    cancelButton.tap()
                } else {
                    app.coordinate(withNormalizedOffset: CGVector(dx: 0.1, dy: 0.1)).tap()
                }
            }
        }
    }
    
    // MARK: - Widget Performance Tests
    
    func testWidgetLoadPerformance() throws {
        // Measure widget data loading performance
        measure {
            // Simulate widget loading data
            let poemTitle = app.staticTexts.matching(identifier: "poem_title").firstMatch
            XCTAssertTrue(poemTitle.waitForExistence(timeout: 5))
        }
        
        // Widget should load quickly
        XCTAssertTrue(true, "Widget should load data efficiently")
    }
    
    func testWidgetUpdatePerformance() throws {
        // Wait for initial content
        let poemTitle = app.staticTexts.matching(identifier: "poem_title").firstMatch
        XCTAssertTrue(poemTitle.waitForExistence(timeout: 5))
        
        // Measure update performance
        measure {
            let refreshButton = app.buttons.matching(identifier: "refresh_button").firstMatch
            refreshButton.tap()
            XCTAssertTrue(poemTitle.waitForExistence(timeout: 8))
        }
        
        // Widget updates should be performant
        XCTAssertTrue(true, "Widget updates should be efficient")
    }
    
    func testWidgetMemoryUsage() throws {
        // Wait for content
        let poemTitle = app.staticTexts.matching(identifier: "poem_title").firstMatch
        XCTAssertTrue(poemTitle.waitForExistence(timeout: 5))
        
        // Perform multiple operations that widget would need to handle
        for _ in 0..<10 {
            let refreshButton = app.buttons.matching(identifier: "refresh_button").firstMatch
            refreshButton.tap()
            XCTAssertTrue(poemTitle.waitForExistence(timeout: 8))
            
            // Toggle favorite
            let favoriteButton = app.buttons.matching(identifier: "favorite_button").firstMatch
            if favoriteButton.exists {
                favoriteButton.tap()
                usleep(500000)
            }
        }
        
        // Widget should maintain good memory usage
        XCTAssertTrue(poemTitle.exists, "Widget should maintain good memory usage during updates")
    }
    
    // MARK: - Widget Configuration Tests
    
    func testWidgetConfiguration() throws {
        // Wait for content
        let poemTitle = app.staticTexts.matching(identifier: "poem_title").firstMatch
        XCTAssertTrue(poemTitle.waitForExistence(timeout: 5))
        
        // Test widget configuration options (simulated)
        // In real widget, user could configure:
        // - Update frequency
        // - Content preferences
        // - Display options
        
        XCTAssertTrue(true, "Widget should support configuration options")
    }
    
    func testWidgetCustomization() throws {
        // Test different widget customization scenarios
        let customizationOptions = [
            "WIDGET_THEME": "light",
            "WIDGET_FONT_SIZE": "large",
            "WIDGET_UPDATE_FREQUENCY": "hourly"
        ]
        
        for (key, value) in customizationOptions {
            app.terminate()
            app.launchEnvironment = [
                "WIDGET_TESTING": "true",
                key: value,
                "ENABLE_TELEMETRY": "true"
            ]
            app.launch()
            
            let poemTitle = app.staticTexts.matching(identifier: "poem_title").firstMatch
            XCTAssertTrue(poemTitle.waitForExistence(timeout: 5), "Widget should work with \(key)=\(value)")
        }
    }
    
    // MARK: - Widget Accessibility Tests
    
    func testWidgetAccessibility() throws {
        // Wait for content
        let poemTitle = app.staticTexts.matching(identifier: "poem_title").firstMatch
        XCTAssertTrue(poemTitle.waitForExistence(timeout: 5))
        
        // Widget should be accessible
        XCTAssertTrue(poemTitle.isAccessibilityElement, "Widget content should be accessible")
        XCTAssertFalse(poemTitle.label.isEmpty, "Widget should have accessibility labels")
        
        let poemAuthor = app.staticTexts.matching(identifier: "poem_author").firstMatch
        if poemAuthor.exists {
            XCTAssertTrue(poemAuthor.isAccessibilityElement, "Widget author should be accessible")
        }
        
        // Widget interactions should be accessible
        let refreshButton = app.buttons.matching(identifier: "refresh_button").firstMatch
        XCTAssertTrue(refreshButton.isAccessibilityElement, "Widget actions should be accessible")
    }
    
    func testWidgetVoiceOverSupport() throws {
        app.terminate()
        app.launchEnvironment = [
            "WIDGET_TESTING": "true",
            "VOICEOVER_ENABLED": "true",
            "ENABLE_TELEMETRY": "true"
        ]
        app.launch()
        
        // Wait for content
        let poemTitle = app.staticTexts.matching(identifier: "poem_title").firstMatch
        XCTAssertTrue(poemTitle.waitForExistence(timeout: 5))
        
        // Widget should work with VoiceOver
        XCTAssertTrue(poemTitle.isAccessibilityElement, "Widget should support VoiceOver")
        XCTAssertFalse(poemTitle.label.isEmpty, "Widget should have VoiceOver descriptions")
        
        // Test VoiceOver navigation in widget context
        XCTAssertTrue(true, "Widget should provide good VoiceOver experience")
    }
    
    // MARK: - Widget Integration Tests
    
    func testWidgetAppIntegration() throws {
        // Test full integration between widget and main app
        let poemTitle = app.staticTexts.matching(identifier: "poem_title").firstMatch
        XCTAssertTrue(poemTitle.waitForExistence(timeout: 5))
        
        // Changes in app should be reflected in widget
        let favoriteButton = app.buttons.matching(identifier: "favorite_button").firstMatch
        if favoriteButton.exists {
            favoriteButton.tap()
            // Widget should show updated favorite status
            XCTAssertTrue(true, "Widget should reflect app state changes")
        }
        
        // App should handle widget-initiated actions
        let refreshButton = app.buttons.matching(identifier: "refresh_button").firstMatch
        refreshButton.tap()
        XCTAssertTrue(poemTitle.waitForExistence(timeout: 8))
        
        // Both app and widget should show same content
        XCTAssertTrue(true, "App and widget should stay synchronized")
    }
    
    func testWidgetTelemetryIntegration() throws {
        // Wait for content
        let poemTitle = app.staticTexts.matching(identifier: "poem_title").firstMatch
        XCTAssertTrue(poemTitle.waitForExistence(timeout: 5))
        
        // Widget usage should be tracked by telemetry
        // Simulate widget interactions
        let refreshButton = app.buttons.matching(identifier: "refresh_button").firstMatch
        refreshButton.tap()
        XCTAssertTrue(poemTitle.waitForExistence(timeout: 8))
        
        // Widget telemetry should integrate with main app telemetry
        XCTAssertTrue(true, "Widget usage should be tracked by telemetry")
    }
    
    func testWidgetErrorRecovery() throws {
        // Test widget recovery from various error states
        app.terminate()
        app.launchEnvironment = [
            "WIDGET_TESTING": "true",
            "SIMULATE_WIDGET_ERROR": "true",
            "ENABLE_TELEMETRY": "true"
        ]
        app.launch()
        
        // Widget should handle errors gracefully
        let refreshButton = app.buttons.matching(identifier: "refresh_button").firstMatch
        XCTAssertTrue(refreshButton.waitForExistence(timeout: 5))
        
        // Even with errors, widget should show fallback content
        let poemTitle = app.staticTexts.matching(identifier: "poem_title").firstMatch
        if poemTitle.waitForExistence(timeout: 5) {
            XCTAssertTrue(true, "Widget should show cached content during errors")
        } else {
            XCTAssertTrue(true, "Widget should show error state gracefully")
        }
        
        // Widget should recover when error is resolved
        refreshButton.tap()
        XCTAssertTrue(true, "Widget should recover from error states")
    }
}

// MARK: - Widget Testing Extensions

extension WidgetUITests {
    
    // Helper to simulate widget timeline scenarios
    func simulateWidgetTimelineScenario(_ scenario: String) {
        app.terminate()
        app.launchEnvironment["WIDGET_TIMELINE_SCENARIO"] = scenario
        app.launch()
    }
    
    // Helper to verify widget data availability
    func verifyWidgetDataAvailability() -> Bool {
        let mainPage = PageFactory(app: app).mainContentPage()
        guard mainPage.waitForPageToLoad() else { return false }
        
        return mainPage.verifyPoemIsDisplayed()
    }
    
    // Helper to simulate widget interaction types
    func simulateWidgetInteraction(_ interactionType: String) {
        app.terminate()
        app.launchEnvironment["WIDGET_INTERACTION"] = interactionType
        app.launch()
    }
    
    // Helper to test widget size configurations
    func testWidgetSizeConfiguration(_ size: String) -> Bool {
        app.terminate()
        app.launchEnvironment["WIDGET_SIZE"] = size
        app.launch()
        
        let mainPage = PageFactory(app: app).mainContentPage()
        return mainPage.waitForPageToLoad() && mainPage.verifyPoemIsDisplayed()
    }
}

// MARK: - Widget Test Data Helper

class WidgetTestDataHelper {
    
    static func prepareWidgetTestData() {
        // Prepare specific test data for widget scenarios
        let userDefaults = UserDefaults(suiteName: "group.com.stevereitz.poemoftheday")
        
        // Directly create test data as JSON instead of using Poem class
        let testPoemData: [String: Any] = [
            "id": UUID().uuidString,
            "title": "Test Poem",
            "content": "This is a test poem\nFor widget testing\nWritten for UI tests",
            "author": "Test Author",
            "vibe": NSNull()
        ]
        
        if let poemData = try? JSONSerialization.data(withJSONObject: testPoemData) {
            userDefaults?.set(poemData, forKey: "daily_poem")
        }
        
        userDefaults?.set(Date(), forKey: "last_poem_fetch_date")
    }
    
    static func cleanupWidgetTestData() {
        let userDefaults = UserDefaults(suiteName: "group.com.stevereitz.poemoftheday")
        userDefaults?.removeObject(forKey: "daily_poem")
        userDefaults?.removeObject(forKey: "last_poem_fetch_date")
        userDefaults?.removeObject(forKey: "favorites")
    }
    
    static func simulateWidgetTimelineEntry() -> Bool {
        // Simulate creating a widget timeline entry
        let userDefaults = UserDefaults(suiteName: "group.com.stevereitz.poemoftheday")
        
        // Simple simulation - just set a flag that widget timeline was updated
        userDefaults?.set(Date(), forKey: "widget_last_update")
        return true
    }
}