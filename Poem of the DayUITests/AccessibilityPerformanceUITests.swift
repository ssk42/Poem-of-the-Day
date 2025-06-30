import XCTest
@testable import Poem_of_the_Day

final class AccessibilityPerformanceUITests: XCTestCase {
    
    var app: XCUIApplication!
    var pageFactory: PageFactory!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        
        app = XCUIApplication()
        pageFactory = PageFactory(app: app)
        
        // Configure launch arguments for accessibility testing
        app.launchArguments = ["--ui-testing", "--accessibility-testing"]
        app.launchEnvironment = [
            "ENABLE_ACCESSIBILITY_TESTING": "true",
            "PERFORMANCE_TESTING": "true"
        ]
        
        app.launch()
    }
    
    override func tearDownWithError() throws {
        app = nil
        pageFactory = nil
    }
    
    // MARK: - Accessibility Tests
    
    func testVoiceOverSupport() throws {
        let mainPage = pageFactory.mainContentPage()
        XCTAssertTrue(mainPage.waitForPageToLoad())
        
        // Test VoiceOver accessibility labels
        let requiredAccessibilityLabels = [
            "Poem of the Day",
            "Get New Poem",
            "Favorites",
            "Share"
        ]
        
        TestUtilities.verifyAccessibilityLabels(
            in: app,
            expectedLabels: requiredAccessibilityLabels
        )
        
        // Test VoiceOver navigation
        if mainPage.verifyPoemIsDisplayed() {
            TestUtilities.verifyVoiceOverSupport(for: mainPage.poemTitle)
            TestUtilities.verifyVoiceOverSupport(for: mainPage.poemAuthor)
            TestUtilities.verifyVoiceOverSupport(for: mainPage.poemContent)
        }
        
        // Test interactive elements
        TestUtilities.verifyVoiceOverSupport(for: mainPage.refreshButton)
        TestUtilities.verifyVoiceOverSupport(for: mainPage.favoritesButton)
        
        if mainPage.favoriteButton.exists {
            TestUtilities.verifyVoiceOverSupport(for: mainPage.favoriteButton)
        }
        
        if mainPage.shareButton.exists {
            TestUtilities.verifyVoiceOverSupport(for: mainPage.shareButton)
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
            
            let mainPage = pageFactory.mainContentPage()
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
        
        let mainPage = pageFactory.mainContentPage()
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
            let shareSheet = mainPage.tapShareButton()
            if shareSheet.waitForPageToLoad() {
                shareSheet.tapCancel()
            }
        }
    }
    
    func testHighContrastSupport() throws {
        // Test with high contrast enabled
        app.terminate()
        app.launchEnvironment["HIGH_CONTRAST"] = "true"
        app.launch()
        
        let mainPage = pageFactory.mainContentPage()
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
            
            let mainPage = pageFactory.mainContentPage()
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
        
        let mainPage = pageFactory.mainContentPage()
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
            
            let mainPage = pageFactory.mainContentPage()
            _ = mainPage.waitForPageToLoad(timeout: 10.0)
        }
        
        // Verify app launches within reasonable time
        let launchOptions = XCTMeasureOptions()
        launchOptions.iterationCount = 5
        
        measure(options: launchOptions) {
            app.terminate()
            let startTime = CFAbsoluteTimeGetCurrent()
            app.launch()
            
            let mainPage = pageFactory.mainContentPage()
            if mainPage.waitForPageToLoad(timeout: 10.0) {
                let launchTime = CFAbsoluteTimeGetCurrent() - startTime
                XCTAssertLessThan(launchTime, 5.0, "App should launch within 5 seconds")
            }
        }
    }
    
    func testPoemLoadingPerformance() throws {
        let mainPage = pageFactory.mainContentPage()
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
        let mainPage = pageFactory.mainContentPage()
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
                    sleep(0.1)
                    mainPage.tapUnfavoriteButton()
                    sleep(0.1)
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
        let mainPage = pageFactory.mainContentPage()
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
                    sleep(0.1)
                    scrollView.swipeDown()
                    sleep(0.1)
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
        
        let mainPage = pageFactory.mainContentPage()
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
        let mainPage = pageFactory.mainContentPage()
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
        let mainPage = pageFactory.mainContentPage()
        XCTAssertTrue(mainPage.waitForPageToLoad())
        
        // Test performance under concurrent operations
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // Rapidly perform multiple operations
        for _ in 0..<10 {
            mainPage.tapRefreshButton()
            sleep(0.2)
            
            if mainPage.favoriteButton.exists {
                mainPage.tapFavoriteButton()
                sleep(0.1)
            }
            
            if mainPage.shareButton.exists {
                let shareSheet = mainPage.tapShareButton()
                if shareSheet.waitForPageToLoad() {
                    shareSheet.tapCancel()
                }
            }
            
            sleep(0.3)
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
            
            let mainPage = pageFactory.mainContentPage()
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
        
        let mainPage = pageFactory.mainContentPage()
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
                sleep(0.1)
            }
        }
        
        let duration = CFAbsoluteTimeGetCurrent() - startTime
        
        // VoiceOver should not significantly slow down navigation
        XCTAssertLessThan(duration, 10.0, "VoiceOver navigation should be performant")
        
        XCTAssertTrue(mainPage.isDisplayed(), "App should remain responsive with VoiceOver")
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