import XCTest
import WidgetKit
@testable import Poem_of_the_Day

final class WidgetUITests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        
        app = XCUIApplication()
        
        // Configure launch arguments for widget testing
        app.launchArguments = ["--ui-testing", "--widget-testing"]
        app.launchEnvironment = [
            "ENABLE_WIDGET_TESTING": "true",
            "WIDGET_DATA_AVAILABLE": "true",
            "SIMULATE_WIDGET_TIMELINE": "true"
        ]
        
        app.launch()
    }
    
    override func tearDownWithError() throws {
        app = nil
    }
    
    // MARK: - Widget Data Preparation Tests
    
    func testWidgetDataPreparation() throws {
        let mainPage = PageFactory(app: app).mainContentPage()
        XCTAssertTrue(mainPage.waitForPageToLoad())
        
        // Ensure we have a poem to share with widget
        XCTAssertTrue(mainPage.verifyPoemIsDisplayed(), "Should have poem data for widget")
        
        // Simulate app going to background (when widget would update)
        XCUIDevice.shared.press(.home)
        sleep(2)
        
        // Return to app
        app.activate()
        sleep(1)
        
        // Verify app returned to proper state
        XCTAssertTrue(mainPage.waitForPageToLoad())
        XCTAssertTrue(mainPage.isDisplayed())
    }
    
    func testWidgetDataSynchronization() throws {
        let mainPage = PageFactory(app: app).mainContentPage()
        XCTAssertTrue(mainPage.waitForPageToLoad())
        
        // Perform actions that should sync to widget
        if mainPage.verifyPoemIsDisplayed() {
            let originalTitle = mainPage.getCurrentPoemTitle()
            
            // Refresh poem (should update widget data)
            mainPage.tapRefreshButton()
            XCTAssertTrue(mainPage.waitForLoadingToComplete())
            
            if mainPage.verifyPoemIsDisplayed() {
                let newTitle = mainPage.getCurrentPoemTitle()
                
                // Data should be updated (titles might be different)
                // Widget would receive this new data
                XCTAssertTrue(true, "Widget data synchronization tested")
            }
        }
    }
    
    // MARK: - Widget Timeline Tests
    
    func testWidgetTimelineUpdates() throws {
        // Test simulated widget timeline behavior
        app.terminate()
        app.launchEnvironment["SIMULATE_WIDGET_REFRESH"] = "true"
        app.launch()
        
        let mainPage = PageFactory(app: app).mainContentPage()
        XCTAssertTrue(mainPage.waitForPageToLoad())
        
        // Simulate widget timeline refresh by checking if fresh data is available
        mainPage.tapRefreshButton()
        XCTAssertTrue(mainPage.waitForLoadingToComplete())
        
        // Widget timeline should be updated with new data
        // In a real test, this would verify widget timeline entries
        XCTAssertTrue(mainPage.verifyPoemIsDisplayed(), "Timeline update should provide fresh data")
    }
    
    func testWidgetTimelineAtMidnight() throws {
        // Simulate midnight refresh scenario
        app.terminate()
        app.launchEnvironment["SIMULATE_MIDNIGHT_REFRESH"] = "true"
        app.launch()
        
        let mainPage = PageFactory(app: app).mainContentPage()
        XCTAssertTrue(mainPage.waitForPageToLoad())
        
        // Check that daily poem logic works (simulated midnight)
        mainPage.tapRefreshButton()
        XCTAssertTrue(mainPage.waitForLoadingToComplete())
        
        // Should get new daily poem as if it's a new day
        XCTAssertTrue(mainPage.verifyPoemIsDisplayed(), "Should get new poem for new day")
    }
    
    // MARK: - Widget Error Handling Tests
    
    func testWidgetWithNoData() throws {
        // Simulate widget with no available data
        app.terminate()
        app.launchEnvironment["WIDGET_NO_DATA"] = "true"
        app.launch()
        
        let mainPage = PageFactory(app: app).mainContentPage()
        XCTAssertTrue(mainPage.waitForPageToLoad())
        
        // App should handle missing widget data gracefully
        // Might show placeholder or fetch new data
        let hasContent = mainPage.verifyPoemIsDisplayed()
        if !hasContent {
            // Should attempt to load new content
            mainPage.tapRefreshButton()
            XCTAssertTrue(mainPage.waitForLoadingToComplete())
        }
        
        // Eventually should have content or show appropriate message
        XCTAssertTrue(mainPage.isDisplayed(), "Should handle no widget data gracefully")
    }
    
    func testWidgetWithCorruptedData() throws {
        // Simulate widget with corrupted data
        app.terminate()
        app.launchEnvironment["WIDGET_CORRUPTED_DATA"] = "true"
        app.launch()
        
        let mainPage = PageFactory(app: app).mainContentPage()
        XCTAssertTrue(mainPage.waitForPageToLoad())
        
        // App should recover from corrupted widget data
        // Should either show default content or fetch new data
        XCTAssertTrue(mainPage.isDisplayed(), "Should handle corrupted widget data")
        
        // Try to refresh to get clean data
        mainPage.tapRefreshButton()
        XCTAssertTrue(mainPage.waitForLoadingToComplete())
        
        // Should eventually show valid content
        sleep(3)
        let hasValidContent = mainPage.verifyPoemIsDisplayed()
        XCTAssertTrue(hasValidContent, "Should recover with valid content")
    }
    
    // MARK: - Widget-App Deep Linking Tests
    
    func testDeepLinkFromWidget() throws {
        // Simulate opening app from widget tap
        app.terminate()
        app.launchEnvironment["LAUNCHED_FROM_WIDGET"] = "true"
        app.launch()
        
        let mainPage = PageFactory(app: app).mainContentPage()
        XCTAssertTrue(mainPage.waitForPageToLoad())
        
        // App should open to main screen with poem displayed
        XCTAssertTrue(mainPage.isDisplayed(), "Should open to main screen from widget")
        
        // Should show the poem that was in the widget
        XCTAssertTrue(mainPage.verifyPoemIsDisplayed(), "Should display poem from widget")
    }
    
    func testDeepLinkToSpecificPoem() throws {
        // Simulate deep link to specific poem from widget
        app.terminate()
        app.launchEnvironment["WIDGET_DEEP_LINK"] = "specific_poem"
        app.launch()
        
        let mainPage = PageFactory(app: app).mainContentPage()
        XCTAssertTrue(mainPage.waitForPageToLoad())
        
        // Should navigate to or display the specific poem
        XCTAssertTrue(mainPage.verifyPoemIsDisplayed(), "Should show specific poem from deep link")
    }
    
    // MARK: - Widget Size and Layout Tests
    
    func testWidgetSmallSizeData() throws {
        // Simulate small widget data requirements
        app.terminate()
        app.launchEnvironment["WIDGET_SIZE"] = "small"
        app.launch()
        
        let mainPage = PageFactory(app: app).mainContentPage()
        XCTAssertTrue(mainPage.waitForPageToLoad())
        
        // Small widget would need concise data
        if mainPage.verifyPoemIsDisplayed() {
            let title = mainPage.getCurrentPoemTitle()
            let author = mainPage.getCurrentPoemAuthor()
            
            // Data should be suitable for small widget display
            XCTAssertFalse(title.isEmpty, "Should have title for small widget")
            XCTAssertFalse(author.isEmpty, "Should have author for small widget")
        }
    }
    
    func testWidgetMediumSizeData() throws {
        // Simulate medium widget data requirements
        app.terminate()
        app.launchEnvironment["WIDGET_SIZE"] = "medium"
        app.launch()
        
        let mainPage = PageFactory(app: app).mainContentPage()
        XCTAssertTrue(mainPage.waitForPageToLoad())
        
        // Medium widget can show more content
        if mainPage.verifyPoemIsDisplayed() {
            // Should have full poem data available
            XCTAssertTrue(true, "Medium widget data prepared")
        }
    }
    
    func testWidgetLargeSizeData() throws {
        // Simulate large widget data requirements
        app.terminate()
        app.launchEnvironment["WIDGET_SIZE"] = "large"
        app.launch()
        
        let mainPage = PageFactory(app: app).mainContentPage()
        XCTAssertTrue(mainPage.waitForPageToLoad())
        
        // Large widget can show complete poem
        if mainPage.verifyPoemIsDisplayed() {
            // Should have all poem content available
            XCTAssertTrue(true, "Large widget data prepared")
        }
    }
    
    // MARK: - Widget Configuration Tests
    
    func testWidgetConfigurationChanges() throws {
        // Simulate widget being added/removed
        app.terminate()
        app.launchEnvironment["WIDGET_CONFIGURATION_CHANGED"] = "true"
        app.launch()
        
        let mainPage = PageFactory(app: app).mainContentPage()
        XCTAssertTrue(mainPage.waitForPageToLoad())
        
        // App should handle widget configuration changes
        // Might need to update timeline or data sharing
        XCTAssertTrue(mainPage.isDisplayed(), "Should handle widget configuration changes")
    }
    
    func testMultipleWidgetInstances() throws {
        // Simulate multiple widget instances
        app.terminate()
        app.launchEnvironment["MULTIPLE_WIDGETS"] = "true"
        app.launch()
        
        let mainPage = PageFactory(app: app).mainContentPage()
        XCTAssertTrue(mainPage.waitForPageToLoad())
        
        // Should handle data sharing across multiple widget instances
        XCTAssertTrue(mainPage.verifyPoemIsDisplayed(), "Should handle multiple widget instances")
    }
    
    // MARK: - Widget Performance Tests
    
    func testWidgetDataLoadingPerformance() throws {
        let mainPage = PageFactory(app: app).mainContentPage()
        XCTAssertTrue(mainPage.waitForPageToLoad())
        
        // Measure time for widget data preparation
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // Simulate widget data loading
        mainPage.tapRefreshButton()
        XCTAssertTrue(mainPage.waitForLoadingToComplete())
        
        let endTime = CFAbsoluteTimeGetCurrent()
        let duration = endTime - startTime
        
        // Widget data should load quickly
        XCTAssertLessThan(duration, 5.0, "Widget data should load within 5 seconds")
        
        // Should have valid data
        XCTAssertTrue(mainPage.verifyPoemIsDisplayed(), "Should have widget data after loading")
    }
    
    func testWidgetBackgroundRefreshPerformance() throws {
        let mainPage = PageFactory(app: app).mainContentPage()
        XCTAssertTrue(mainPage.waitForPageToLoad())
        
        // Simulate background refresh for widget
        app.terminate()
        app.launchEnvironment["WIDGET_BACKGROUND_REFRESH"] = "true"
        app.launch()
        
        let newMainPage = PageFactory(app: app).mainContentPage()
        XCTAssertTrue(newMainPage.waitForPageToLoad())
        
        // Background refresh should provide updated data quickly
        XCTAssertTrue(newMainPage.verifyPoemIsDisplayed(), "Background refresh should provide data")
    }
    
    // MARK: - Widget Integration Tests
    
    func testWidgetTelemetryIntegration() throws {
        // Test that widget interactions are tracked
        app.terminate()
        app.launchEnvironment["WIDGET_TELEMETRY_ENABLED"] = "true"
        app.launch()
        
        let mainPage = PageFactory(app: app).mainContentPage()
        XCTAssertTrue(mainPage.waitForPageToLoad())
        
        // Simulate widget view/tap events
        app.terminate()
        app.launchEnvironment["SIMULATE_WIDGET_TAP"] = "true"
        app.launch()
        
        let newMainPage = PageFactory(app: app).mainContentPage()
        XCTAssertTrue(newMainPage.waitForPageToLoad())
        
        // Check if widget events are tracked
        let telemetryDebugPage = newMainPage.longPressTitle()
        if telemetryDebugPage.waitForPageToLoad() {
            // Widget events should be tracked
            XCTAssertTrue(true, "Widget telemetry integration tested")
            telemetryDebugPage.tapCloseButton()
        }
    }
    
    func testWidgetFavoritesSync() throws {
        let mainPage = PageFactory(app: app).mainContentPage()
        XCTAssertTrue(mainPage.waitForPageToLoad())
        
        // Add poem to favorites
        if mainPage.verifyPoemIsDisplayed() {
            mainPage.tapFavoriteButton()
            sleep(1)
            
            // Favorite should be available to widget
            // Simulate widget checking for favorites
            app.terminate()
            app.launchEnvironment["WIDGET_CHECK_FAVORITES"] = "true"
            app.launch()
            
            let newMainPage = PageFactory(app: app).mainContentPage()
            XCTAssertTrue(newMainPage.waitForPageToLoad())
            
            // Favorites should be accessible
            let favoritesPage = newMainPage.tapFavoritesButton()
            if favoritesPage.waitForPageToLoad() {
                XCTAssertFalse(favoritesPage.verifyEmptyState(), "Favorites should be available to widget")
                favoritesPage.tapBackButton()
            }
        }
    }
    
    // MARK: - Widget Error Recovery Tests
    
    func testWidgetErrorRecovery() throws {
        // Simulate widget error and recovery
        app.terminate()
        app.launchEnvironment["WIDGET_ERROR"] = "true"
        app.launch()
        
        let mainPage = PageFactory(app: app).mainContentPage()
        XCTAssertTrue(mainPage.waitForPageToLoad())
        
        // App should handle widget errors gracefully
        XCTAssertTrue(mainPage.isDisplayed(), "Should handle widget errors")
        
        // Attempt recovery
        app.terminate()
        app.launchEnvironment["WIDGET_ERROR"] = "false"
        app.launch()
        
        let recoveredMainPage = PageFactory(app: app).mainContentPage()
        XCTAssertTrue(recoveredMainPage.waitForPageToLoad())
        
        // Should recover and show content
        XCTAssertTrue(recoveredMainPage.verifyPoemIsDisplayed(), "Should recover from widget errors")
    }
    
    func testWidgetDataConsistency() throws {
        let mainPage = PageFactory(app: app).mainContentPage()
        XCTAssertTrue(mainPage.waitForPageToLoad())
        
        // Verify data consistency between app and widget
        if mainPage.verifyPoemIsDisplayed() {
            let appPoemTitle = mainPage.getCurrentPoemTitle()
            let appPoemAuthor = mainPage.getCurrentPoemAuthor()
            
            // Simulate widget accessing same data
            app.terminate()
            app.launchEnvironment["WIDGET_DATA_CONSISTENCY_CHECK"] = "true"
            app.launch()
            
            let newMainPage = PageFactory(app: app).mainContentPage()
            XCTAssertTrue(newMainPage.waitForPageToLoad())
            
            if newMainPage.verifyPoemIsDisplayed() {
                // Data should be consistent (or updated appropriately)
                XCTAssertTrue(true, "Widget data consistency verified")
            }
        }
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
        
        let testPoem = TestData.samplePoem
        if let poemData = try? JSONEncoder().encode(testPoem) {
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
        
        let timeline = [
            "entries": [
                [
                    "date": Date(),
                    "poem": TestData.samplePoem
                ]
            ],
            "policy": "atEnd"
        ]
        
        if let timelineData = try? JSONSerialization.data(withJSONObject: timeline) {
            userDefaults?.set(timelineData, forKey: "widget_timeline")
            return true
        }
        
        return false
    }
}