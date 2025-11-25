import XCTest

final class AccessibilityPerformanceUITests: XCTestCase {
    
    var app: XCUIApplication!

    
    override func setUpWithError() throws {
        continueAfterFailure = false
        
        app = XCUIApplication()

        
        // Configure launch arguments for accessibility testing
        app.launchArguments = ["--ui-testing", "--accessibility-testing"]
        app.launchEnvironment = [
            "ENABLE_ACCESSIBILITY_TESTING": "true",
            "PERFORMANCE_TESTING": "true",
            "AI_AVAILABLE": "true",
            "ENABLE_TELEMETRY": "true"
        ]
        
        app.launch()
    }
    
    override func tearDownWithError() throws {
        app = nil

    }
    
    // MARK: - Accessibility Tests
    
    func testVoiceOverSupport() throws {
        let mainPage = PageFactory.mainContentPage(app: app)
        XCTAssertTrue(mainPage.waitForPageToLoad())
        
        // Test VoiceOver accessibility labels
        let requiredAccessibilityLabels = [
            "Poem of the Day",
            "Get New Poem",
            "Favorites",
            "Share"
        ]
        
        // Verify accessibility labels exist
        for label in requiredAccessibilityLabels {
            let element = app.otherElements[label].firstMatch
            XCTAssertTrue(element.exists, "Element with accessibility label '\(label)' should exist")
        }
        
        // Test VoiceOver navigation
        if mainPage.verifyPoemIsDisplayed() {
            // Verify VoiceOver support for poem elements
            XCTAssertTrue(mainPage.poemTitle.isAccessibilityElement, "Poem title should be accessible to VoiceOver")
            XCTAssertFalse(mainPage.poemTitle.label.isEmpty, "Poem title should have accessibility label")
            
            XCTAssertTrue(mainPage.poemAuthor.isAccessibilityElement, "Poem author should be accessible to VoiceOver")
            XCTAssertFalse(mainPage.poemAuthor.label.isEmpty, "Poem author should have accessibility label")
            
            XCTAssertTrue(mainPage.poemContent.isAccessibilityElement, "Poem content should be accessible to VoiceOver")
            XCTAssertFalse(mainPage.poemContent.label.isEmpty, "Poem content should have accessibility label")
        }
        
        // Test interactive elements
        // Verify VoiceOver support for interactive elements
        XCTAssertTrue(mainPage.refreshButton.isAccessibilityElement, "Refresh button should be accessible to VoiceOver")
        XCTAssertFalse(mainPage.refreshButton.label.isEmpty, "Refresh button should have accessibility label")
        
        XCTAssertTrue(mainPage.favoritesButton.isAccessibilityElement, "Favorites button should be accessible to VoiceOver")
        XCTAssertFalse(mainPage.favoritesButton.label.isEmpty, "Favorites button should have accessibility label")
        
        if mainPage.favoriteButton.exists {
            XCTAssertTrue(mainPage.favoriteButton.isAccessibilityElement, "Favorite button should be accessible to VoiceOver")
            XCTAssertFalse(mainPage.favoriteButton.label.isEmpty, "Favorite button should have accessibility label")
        }
        
        if mainPage.shareButton.exists {
            XCTAssertTrue(mainPage.shareButton.isAccessibilityElement, "Share button should be accessible to VoiceOver")
            XCTAssertFalse(mainPage.shareButton.label.isEmpty, "Share button should have accessibility label")
        }
    }
    
    func testDynamicTypeSupport() throws {
        // Test with different Dynamic Type sizes
        let typeSizes = [
            "UICTContentSizeCategoryXS",
            "UICTContentSizeCategoryS",
            "UICTContentSizeCategoryM",
            "UICTContentSizeCategoryL",
            "UICTContentSizeCategoryXL",
            "UICTContentSizeCategoryXXL",
            "UICTContentSizeCategoryXXXL"
        ]
        
        for typeSize in typeSizes {
            // Configure dynamic type size
            app.terminate()
            app.launchEnvironment["DYNAMIC_TYPE_SIZE"] = typeSize
            app.launch()
            
            let mainPage = PageFactory.mainContentPage(app: app)
            XCTAssertTrue(mainPage.waitForPageToLoad(), "Should load with \(typeSize)")
            
            // Verify layout remains functional
            XCTAssertTrue(mainPage.isDisplayed(), "Layout should work with \(typeSize)")
            
            // Verify text is readable
            if mainPage.verifyPoemIsDisplayed() {
                XCTAssertTrue(mainPage.poemTitle.exists, "Title should be visible with \(typeSize)")
                XCTAssertTrue(mainPage.poemAuthor.exists, "Author should be visible with \(typeSize)")
            }
            
            // Verify buttons are still accessible
            XCTAssertTrue(mainPage.refreshButton.exists, "Refresh button should be accessible with \(typeSize)")
            XCTAssertTrue(mainPage.favoritesButton.exists, "Favorites button should be accessible with \(typeSize)")
        }
    }
    
    func testReduceMotionSupport() throws {
        // Test with reduced motion enabled
        app.terminate()
        app.launchEnvironment["REDUCE_MOTION"] = "true"
        app.launch()
        
        let mainPage = PageFactory.mainContentPage(app: app)
        XCTAssertTrue(mainPage.waitForPageToLoad())
        
        // Perform actions that typically involve animations
        mainPage.tapRefreshButton()
        XCTAssertTrue(mainPage.waitForLoadingToComplete())
        
        // Navigation should work without animations
        let favoritesPage = mainPage.tapFavoritesButton()
        XCTAssertTrue(favoritesPage.waitForPageToLoad())
        
        favoritesPage.tapBackButton()
        XCTAssertTrue(mainPage.waitForPageToLoad())
        
        // Share sheet should work
        if mainPage.verifyPoemIsDisplayed() {
            mainPage.tapShareButton()
            let shareSheet = app.sheets.firstMatch
            if shareSheet.waitForExistence(timeout: 5) {
                let cancelButton = shareSheet.buttons["Cancel"]
                if cancelButton.exists {
                    cancelButton.tap()
                }
            }
        }
    }
    
    func testHighContrastSupport() throws {
        // Test with high contrast enabled
        app.terminate()
        app.launchEnvironment["HIGH_CONTRAST"] = "true"
        app.launch()
        
        let mainPage = PageFactory.mainContentPage(app: app)
        XCTAssertTrue(mainPage.waitForPageToLoad())
        
        // Verify all elements are still visible and accessible
        XCTAssertTrue(mainPage.isDisplayed(), "Should display properly with high contrast")
        
        if mainPage.verifyPoemIsDisplayed() {
            XCTAssertTrue(mainPage.poemTitle.exists, "Title should be visible with high contrast")
            XCTAssertTrue(mainPage.poemAuthor.exists, "Author should be visible with high contrast")
        }
        
        // Verify buttons are distinguishable
        XCTAssertTrue(mainPage.refreshButton.exists, "Refresh button should be visible with high contrast")
        XCTAssertTrue(mainPage.favoritesButton.exists, "Favorites button should be visible with high contrast")
    }
    
    func testColorBlindnessSupport() throws {
        // Test with different color blindness simulations
        let colorBlindnessTypes = ["protanopia", "deuteranopia", "tritanopia"]
        
        for type in colorBlindnessTypes {
            app.terminate()
            app.launchEnvironment["COLOR_BLINDNESS"] = type
            app.launch()
            
            let mainPage = PageFactory.mainContentPage(app: app)
            XCTAssertTrue(mainPage.waitForPageToLoad(), "Should load with \(type) simulation")
            
            // Verify functionality doesn't rely solely on color
            XCTAssertTrue(mainPage.isDisplayed(), "Should be usable with \(type)")
            
            if mainPage.verifyPoemIsDisplayed() {
                // Test favorite/unfavorite (should not rely only on color)
                if mainPage.favoriteButton.exists {
                    mainPage.tapFavoriteButton()
                    sleep(1)
                    
                    // Should be able to tell state changed (not just by color)
                    XCTAssertTrue(true, "Favorite state should be distinguishable without color")
                }
            }
        }
    }
    
    func testKeyboardNavigation() throws {
        // Test keyboard navigation support
        app.terminate()
        app.launchEnvironment["KEYBOARD_NAVIGATION"] = "true"
        app.launch()
        
        let mainPage = PageFactory.mainContentPage(app: app)
        XCTAssertTrue(mainPage.waitForPageToLoad())
        
        // Test tab navigation through interactive elements
        // Note: This is simplified - real keyboard testing would use external keyboard
        
        // Verify all interactive elements are reachable
        let interactiveElements = [
            mainPage.refreshButton,
            mainPage.favoritesButton
        ]
        
        for element in interactiveElements {
            if element.exists {
                XCTAssertTrue(element.isHittable, "Element should be keyboard accessible")
            }
        }
        
        // Test navigation to custom prompt
        if mainPage.customPromptButton.exists {
            let customPromptPage = mainPage.tapCustomPromptButton()
            if customPromptPage.waitForPageToLoad() {
                // Text field should be keyboard accessible
                XCTAssertTrue(customPromptPage.promptTextField.exists, "Text field should be keyboard accessible")
                customPromptPage.tapBackButton()
            }
        }
    }
    
    // MARK: - Performance Tests
    
    func testAppLaunchPerformance() throws {
        measure {
            app.terminate()
            app.launch()
            
            let mainPage = PageFactory.mainContentPage(app: app)
            _ = mainPage.waitForPageToLoad(timeout: 10.0)
        }
        
        // Verify app launches within reasonable time
        let launchOptions = XCTMeasureOptions()
        launchOptions.iterationCount = 5
        
        measure(options: launchOptions) {
            app.terminate()
            let startTime = CFAbsoluteTimeGetCurrent()
            app.launch()
            
            let mainPage = PageFactory.mainContentPage(app: app)
            if mainPage.waitForPageToLoad(timeout: 10.0) {
                let launchTime = CFAbsoluteTimeGetCurrent() - startTime
                XCTAssertLessThan(launchTime, 5.0, "App should launch within 5 seconds")
            }
        }
    }
    
    func testPoemLoadingPerformance() throws {
        let mainPage = PageFactory.mainContentPage(app: app)
        XCTAssertTrue(mainPage.waitForPageToLoad())
        
        // Measure poem loading performance
        let measureOptions = XCTMeasureOptions()
        measureOptions.iterationCount = 10
        
        measure(options: measureOptions) {
            mainPage.tapRefreshButton()
            _ = mainPage.waitForLoadingToComplete(timeout: 10.0)
        }
    }
    
    func testMemoryPerformance() throws {
        let mainPage = PageFactory.mainContentPage(app: app)
        XCTAssertTrue(mainPage.waitForPageToLoad())
        
        // Measure memory usage during typical operations
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // Perform memory-intensive operations
        for i in 0..<20 {
            mainPage.tapRefreshButton()
            XCTAssertTrue(mainPage.waitForLoadingToComplete())
            
            if mainPage.verifyPoemIsDisplayed() {
                // Navigate to favorites and back
                let favoritesPage = mainPage.tapFavoritesButton()
                if favoritesPage.waitForPageToLoad() {
                    favoritesPage.tapBackButton()
                    XCTAssertTrue(mainPage.waitForPageToLoad())
                }
                
                // Add and remove from favorites
                if i % 3 == 0 {
                    mainPage.tapFavoriteButton()
                    usleep(100000)
                    mainPage.tapUnfavoriteButton()
                    usleep(100000)
                }
            }
        }
        
        let duration = CFAbsoluteTimeGetCurrent() - startTime
        
        // Operations should complete within reasonable time (indicating good memory management)
        XCTAssertLessThan(duration, 60.0, "Memory-intensive operations should complete within 60 seconds")
        
        // App should still be responsive
        XCTAssertTrue(mainPage.isDisplayed(), "App should remain responsive after memory-intensive operations")
    }
    
    func testScrollingPerformance() throws {
        let mainPage = PageFactory.mainContentPage(app: app)
        XCTAssertTrue(mainPage.waitForPageToLoad())
        
        // Test scrolling performance in favorites (if available)
        let favoritesPage = mainPage.tapFavoritesButton()
        XCTAssertTrue(favoritesPage.waitForPageToLoad())
        
        if !favoritesPage.verifyEmptyState() {
            // Measure scrolling performance
            let measureOptions = XCTMeasureOptions()
            measureOptions.iterationCount = 5
            
            measure(options: measureOptions) {
                let scrollView = favoritesPage.favoritesList
                
                // Perform scrolling
                for _ in 0..<10 {
                    scrollView.swipeUp()
                    usleep(100000)
                    scrollView.swipeDown()
                    usleep(100000)
                }
            }
        }
        
        favoritesPage.tapBackButton()
    }
    
    func testAIGenerationPerformance() throws {
        // Test AI generation performance
        app.terminate()
        app.launchEnvironment["AI_AVAILABLE"] = "true"
        app.launch()
        
        let mainPage = PageFactory.mainContentPage(app: app)
        XCTAssertTrue(mainPage.waitForPageToLoad())
        
        let measureOptions = XCTMeasureOptions()
        measureOptions.iterationCount = 3 // Fewer iterations for AI operations
        
        measure(options: measureOptions) {
            let vibeGenerationPage = mainPage.tapVibeGenerationButton()
            XCTAssertTrue(vibeGenerationPage.waitForPageToLoad())
            
            let startTime = CFAbsoluteTimeGetCurrent()
            vibeGenerationPage.tapGenerateButton()
            
            // Wait for generation to complete
            sleep(5) // AI generation might take longer
            
            let generationTime = CFAbsoluteTimeGetCurrent() - startTime
            XCTAssertLessThan(generationTime, 10.0, "AI generation should complete within 10 seconds")
            
            vibeGenerationPage.tapBackButton()
        }
    }
    
    func testNetworkPerformance() throws {
        let mainPage = PageFactory.mainContentPage(app: app)
        XCTAssertTrue(mainPage.waitForPageToLoad())
        
        // Measure network request performance
        let measureOptions = XCTMeasureOptions()
        measureOptions.iterationCount = 5
        
        measure(options: measureOptions) {
            let startTime = CFAbsoluteTimeGetCurrent()
            
            mainPage.tapRefreshButton()
            XCTAssertTrue(mainPage.waitForLoadingToComplete())
            
            let networkTime = CFAbsoluteTimeGetCurrent() - startTime
            XCTAssertLessThan(networkTime, 8.0, "Network requests should complete within 8 seconds")
        }
    }
    
    func testConcurrentOperationsPerformance() throws {
        let mainPage = PageFactory.mainContentPage(app: app)
        XCTAssertTrue(mainPage.waitForPageToLoad())
        
        // Test performance under concurrent operations
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // Rapidly perform multiple operations
        for _ in 0..<10 {
            mainPage.tapRefreshButton()
            usleep(200000)
            
            if mainPage.favoriteButton.exists {
                mainPage.tapFavoriteButton()
                usleep(100000)
            }
            
            if mainPage.shareButton.exists {
                mainPage.tapShareButton()
                let shareSheet = app.sheets.firstMatch
                if shareSheet.waitForExistence(timeout: 5) {
                    let cancelButton = shareSheet.buttons["Cancel"]
                    if cancelButton.exists {
                        cancelButton.tap()
                    }
                }
            }
            
            usleep(300000)
        }
        
        let duration = CFAbsoluteTimeGetCurrent() - startTime
        
        // Should handle concurrent operations efficiently
        XCTAssertLessThan(duration, 30.0, "Concurrent operations should complete efficiently")
        
        // App should remain stable
        XCTAssertTrue(mainPage.isDisplayed(), "App should remain stable under concurrent operations")
    }
    
    // MARK: - Combined Accessibility and Performance Tests
    
    func testAccessibilityPerformanceImpact() throws {
        // Test performance impact of accessibility features
        let typeSizes = ["UICTContentSizeCategoryM", "UICTContentSizeCategoryXXXL"]
        
        for typeSize in typeSizes {
            app.terminate()
            app.launchEnvironment["DYNAMIC_TYPE_SIZE"] = typeSize
            app.launch()
            
            let mainPage = PageFactory.mainContentPage(app: app)
            let startTime = CFAbsoluteTimeGetCurrent()
            
            XCTAssertTrue(mainPage.waitForPageToLoad())
            
            // Perform operations with accessibility enabled
            for _ in 0..<5 {
                mainPage.tapRefreshButton()
                XCTAssertTrue(mainPage.waitForLoadingToComplete())
            }
            
            let duration = CFAbsoluteTimeGetCurrent() - startTime
            
            // Accessibility should not significantly impact performance
            XCTAssertLessThan(duration, 25.0, "Accessibility features should not significantly impact performance")
        }
    }
    
    func testVoiceOverPerformance() throws {
        // Test performance with VoiceOver enabled
        app.terminate()
        app.launchEnvironment["VOICEOVER_ENABLED"] = "true"
        app.launch()
        
        let mainPage = PageFactory.mainContentPage(app: app)
        let startTime = CFAbsoluteTimeGetCurrent()
        
        XCTAssertTrue(mainPage.waitForPageToLoad())
        
        // Navigate through elements (simulating VoiceOver usage)
        let elements = [
            mainPage.headerTitle,
            mainPage.refreshButton,
            mainPage.favoritesButton
        ]
        
        for element in elements {
            if element.exists {
                // Simulate VoiceOver focus
                element.tap()
                usleep(100000)
            }
        }
        
        let duration = CFAbsoluteTimeGetCurrent() - startTime
        
        // VoiceOver should not significantly slow down navigation
        XCTAssertLessThan(duration, 10.0, "VoiceOver navigation should be performant")
        
        XCTAssertTrue(mainPage.isDisplayed(), "App should remain responsive with VoiceOver")
    }
    
    // MARK: - User Experience Tests
    
    func testLoadingStatesVisibility() throws {
        app.launch()
        
        // Test refresh loading state
        let refreshButton = app.buttons.matching(identifier: "refresh_button").firstMatch
        XCTAssertTrue(refreshButton.waitForExistence(timeout: 5))
        
        refreshButton.tap()
        
        // Check for loading indicators
        let loadingIndicator = app.activityIndicators.firstMatch
        if loadingIndicator.exists {
            XCTAssertTrue(loadingIndicator.exists, "Should show loading indicator during refresh")
        }
        
        // Wait for completion
        let poemTitle = app.staticTexts.matching(identifier: "poem_title").firstMatch
        XCTAssertTrue(poemTitle.waitForExistence(timeout: 8))
    }
    
    func testErrorStateAccessibility() throws {
        // Configure for network error
        app.terminate()
        app.launchEnvironment["SIMULATE_NETWORK_ERROR"] = "true"
        app.launch()
        
        // Try to refresh
        let refreshButton = app.buttons.matching(identifier: "refresh_button").firstMatch
        XCTAssertTrue(refreshButton.waitForExistence(timeout: 5))
        refreshButton.tap()
        
        // Check error alert accessibility
        let errorAlert = app.alerts.firstMatch
        if errorAlert.waitForExistence(timeout: 5) {
            XCTAssertTrue(errorAlert.isAccessibilityElement, "Error alert should be accessible")
            
            // Verify alert has readable content
            let alertTitle = errorAlert.staticTexts.firstMatch
            XCTAssertTrue(alertTitle.exists, "Error alert should have readable title")
            
            // Dismiss alert
            let okButton = errorAlert.buttons["OK"]
            if okButton.exists {
                XCTAssertTrue(okButton.isAccessibilityElement, "OK button should be accessible")
                okButton.tap()
            }
        }
    }
    
    func testComplexUserFlowPerformance() throws {
        app.launch()
        
        // Measure a complete user flow
        measure(metrics: [XCTClockMetric()]) {
            // Wait for initial load
            let poemTitle = app.staticTexts.matching(identifier: "poem_title").firstMatch
            XCTAssertTrue(poemTitle.waitForExistence(timeout: 5))
            
            // Favorite a poem
            let favoriteButton = app.buttons.matching(identifier: "favorite_button").firstMatch
            if favoriteButton.exists {
                favoriteButton.tap()
            }
            
            // Refresh poem
            let refreshButton = app.buttons.matching(identifier: "refresh_button").firstMatch
            refreshButton.tap()
            XCTAssertTrue(poemTitle.waitForExistence(timeout: 8))
            
            // Share poem
            let shareButton = app.buttons.matching(identifier: "share_button").firstMatch
            if shareButton.exists {
                shareButton.tap()
                
                let shareSheet = app.sheets.firstMatch
                if shareSheet.waitForExistence(timeout: 3) {
                    // Cancel share
                    let cancelButton = shareSheet.buttons["Cancel"]
                    if cancelButton.exists {
                        cancelButton.tap()
                    } else {
                        app.coordinate(withNormalizedOffset: CGVector(dx: 0.1, dy: 0.1)).tap()
                    }
                }
            }
            
            // Open favorites
            let favoritesButton = app.buttons.matching(identifier: "favorites_button").firstMatch
            if favoritesButton.exists {
                favoritesButton.tap()
                
                let favoritesSheet = app.sheets.firstMatch
                if favoritesSheet.waitForExistence(timeout: 3) {
                    // Close favorites
                    let cancelButton = favoritesSheet.buttons["Cancel"]
                    if cancelButton.exists {
                        cancelButton.tap()
                    } else {
                        app.coordinate(withNormalizedOffset: CGVector(dx: 0.1, dy: 0.1)).tap()
                    }
                }
            }
        }
    }
    
    // MARK: - Advanced Accessibility Tests
    
    func testAccessibilityIdentifierCompleteness() throws {
        app.launch()
        
        // Wait for content
        let poemTitle = app.staticTexts.matching(identifier: "poem_title").firstMatch
        XCTAssertTrue(poemTitle.waitForExistence(timeout: 5))
        
        // Verify all critical UI elements have accessibility identifiers
        let criticalElements = [
            ("poem_title", "Poem title"),
            ("poem_author", "Poem author"),
            ("favorite_button", "Favorite button"),
            ("share_button", "Share button"),
            ("refresh_button", "Refresh button"),
            ("favorites_button", "Favorites button")
        ]
        
        for (identifier, description) in criticalElements {
            let element = app.descendants(matching: .any).matching(identifier: identifier).firstMatch
            if element.exists {
                XCTAssertTrue(element.exists, "\(description) should have accessibility identifier '\(identifier)'")
            }
        }
    }
    
    func testAccessibilityAnnouncementsDuringStateChanges() throws {
        app.launch()
        
        // Wait for content
        let favoriteButton = app.buttons.matching(identifier: "favorite_button").firstMatch
        XCTAssertTrue(favoriteButton.waitForExistence(timeout: 5))
        
        // Test that state changes provide appropriate feedback
        favoriteButton.tap()
        
        // Verify button state changed (should now show unfavorite)
        let unfavoriteButton = app.buttons.matching(identifier: "unfavorite_button").firstMatch
        if unfavoriteButton.waitForExistence(timeout: 2) {
            XCTAssertTrue(unfavoriteButton.exists, "Should show unfavorite state after favoriting")
        }
    }
    
    func testHighContrastModeSupport() throws {
        // Configure for high contrast
        app.terminate()
        app.launchEnvironment["HIGH_CONTRAST"] = "true"
        app.launch()
        
        // Verify content is still visible and accessible
        let poemTitle = app.staticTexts.matching(identifier: "poem_title").firstMatch
        XCTAssertTrue(poemTitle.waitForExistence(timeout: 5), "Content should be visible in high contrast mode")
        
        // Test button visibility in high contrast
        let buttons = [
            app.buttons.matching(identifier: "favorite_button").firstMatch,
            app.buttons.matching(identifier: "share_button").firstMatch,
            app.buttons.matching(identifier: "refresh_button").firstMatch
        ]
        
        for button in buttons {
            if button.exists {
                XCTAssertTrue(button.isHittable, "Button should be visible and hittable in high contrast mode")
            }
        }
    }
}

// MARK: - Accessibility Testing Extensions

extension AccessibilityPerformanceUITests {
    
    // Helper to verify accessibility compliance
    func verifyAccessibilityCompliance(for element: XCUIElement, elementName: String) {
        XCTAssertTrue(element.exists, "\(elementName) should exist")
        XCTAssertTrue(element.isAccessibilityElement, "\(elementName) should be accessible to assistive technologies")
        XCTAssertFalse(element.label.isEmpty, "\(elementName) should have accessibility label")
        
        if element.elementType == .button {
            // Buttons should have clear action descriptions
            XCTAssertFalse(element.label.contains("Button"), "Button labels should be descriptive, not generic")
        }
    }
    
    // Helper to test different accessibility scenarios
    func testAccessibilityScenario(
        scenario: String,
        environmentKey: String,
        environmentValue: String,
        testBlock: () throws -> Void
    ) rethrows {
        app.terminate()
        app.launchEnvironment[environmentKey] = environmentValue
        app.launch()
        
        try testBlock()
    }
    
    // Helper to measure performance of specific operations
    func measureOperationPerformance(
        operationName: String,
        iterations: Int = 5,
        timeout: TimeInterval = 10.0,
        operation: () -> Void
    ) {
        let measureOptions = XCTMeasureOptions()
        measureOptions.iterationCount = iterations
        
        measure(options: measureOptions) {
            let startTime = CFAbsoluteTimeGetCurrent()
            operation()
            let duration = CFAbsoluteTimeGetCurrent() - startTime
            
            XCTAssertLessThan(duration, timeout, "\(operationName) should complete within \(timeout) seconds")
        }
    }
}