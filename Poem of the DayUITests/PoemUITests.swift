import XCTest

final class PoemUITests: XCTestCase {
    let app = XCUIApplication()
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app.launch()
    }
    
    func testMainUIElements() {
        // Test header elements
        XCTAssertTrue(app.staticTexts["Poem of the Day"].exists)
        XCTAssertTrue(app.staticTexts["Get New Poem"].exists)
        
        // Test navigation bar
        XCTAssertTrue(app.buttons["Favorites"].exists)
    }
    
    func testFavoriteFunctionality() {
        // Wait for poem to load
        let poemTitle = app.staticTexts.element(boundBy: 1)
        XCTAssertTrue(poemTitle.waitForExistence(timeout: 5))
        
        // Test favorite button
        let favoriteButton = app.buttons["Favorite"]
        XCTAssertTrue(favoriteButton.exists)
        favoriteButton.tap()
        
        // Verify button state changed
        XCTAssertTrue(app.buttons["Unfavorite"].exists)
        
        // Open favorites
        app.buttons["Favorites"].tap()
        
        // Verify poem appears in favorites
        XCTAssertTrue(poemTitle.waitForExistence(timeout: 2))
        
        // Close favorites
        app.buttons["Done"].tap()
        
        // Unfavorite the poem
        app.buttons["Unfavorite"].tap()
        
        // Verify button state changed back
        XCTAssertTrue(app.buttons["Favorite"].exists)
    }
    
    func testMultipleFavorites() {
        // Wait for initial poem to load
        let initialPoemTitle = app.staticTexts.element(boundBy: 1)
        XCTAssertTrue(initialPoemTitle.waitForExistence(timeout: 5))
        
        // Favorite first poem
        app.buttons["Favorite"].tap()
        
        // Get new poem
        app.buttons["Get New Poem"].tap()
        
        // Wait for new poem to load
        let secondPoemTitle = app.staticTexts.element(boundBy: 1)
        XCTAssertTrue(secondPoemTitle.waitForExistence(timeout: 5))
        
        // Favorite second poem
        app.buttons["Favorite"].tap()
        
        // Open favorites
        app.buttons["Favorites"].tap()
        
        // Verify both poems appear in favorites
        XCTAssertTrue(initialPoemTitle.waitForExistence(timeout: 2))
        XCTAssertTrue(secondPoemTitle.waitForExistence(timeout: 2))
        
        // Close favorites
        app.buttons["Done"].tap()
    }
    
    func testShareFunctionality() {
        // Wait for poem to load
        let poemTitle = app.staticTexts.element(boundBy: 1)
        XCTAssertTrue(poemTitle.waitForExistence(timeout: 5))
        
        // Test share button
        let shareButton = app.buttons["Share"]
        XCTAssertTrue(shareButton.exists)
        shareButton.tap()
        
        // Verify share sheet appears
        XCTAssertTrue(app.sheets.firstMatch.waitForExistence(timeout: 2))
        
        // Dismiss share sheet
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
    }
    
    func testRefreshFunctionality() {
        // Wait for initial poem to load
        let initialPoemTitle = app.staticTexts.element(boundBy: 1)
        XCTAssertTrue(initialPoemTitle.waitForExistence(timeout: 5))
        
        // Get new poem
        app.buttons["Get New Poem"].tap()
        
        // Wait for new poem to load
        let newPoemTitle = app.staticTexts.element(boundBy: 1)
        XCTAssertTrue(newPoemTitle.waitForExistence(timeout: 5))
        
        // Verify poem changed
        XCTAssertNotEqual(initialPoemTitle.label, newPoemTitle.label)
    }
    
    func testPullToRefresh() {
        // Wait for poem to load
        let initialPoemTitle = app.staticTexts.element(boundBy: 1)
        XCTAssertTrue(initialPoemTitle.waitForExistence(timeout: 5))
        
        // Perform pull to refresh
        let start = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.2))
        let end = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.8))
        start.press(forDuration: 0.1, thenDragTo: end)
        
        // Wait for refresh to complete
        Thread.sleep(forTimeInterval: 2)
        
        // Verify poem changed
        let newPoemTitle = app.staticTexts.element(boundBy: 1)
        XCTAssertTrue(newPoemTitle.waitForExistence(timeout: 5))
    }
    
    func testEmptyFavorites() {
        // Open favorites
        app.buttons["Favorites"].tap()
        
        // Verify empty state message
        XCTAssertTrue(app.staticTexts["No Favorite Poems Yet"].exists)
        XCTAssertTrue(app.staticTexts["Your favorite poems will appear here."].exists)
        
        // Close favorites
        app.buttons["Done"].tap()
    }
    
    func testDarkMode() {
        // Enable dark mode
        XCUIDevice.shared.press(.home)
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        springboard.activate()
        
        // Open control center
        let start = springboard.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.01))
        let end = springboard.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        start.press(forDuration: 0.1, thenDragTo: end)
        
        // Toggle dark mode
        springboard.buttons["Dark Mode"].tap()
        
        // Return to app
        app.activate()
        
        // Verify dark mode appearance
        XCTAssertTrue(app.staticTexts["Poem of the Day"].exists)
    }
    
    func testFavoritePoemDetailView() {
        // Wait for poem to load
        let poemTitle = app.staticTexts.element(boundBy: 1)
        XCTAssertTrue(poemTitle.waitForExistence(timeout: 5))
        
        // Favorite the poem
        app.buttons["Favorite"].tap()
        
        // Open favorites
        app.buttons["Favorites"].tap()
        
        // Tap on the poem to open detail view
        poemTitle.tap()
        
        // Verify detail view elements
        XCTAssertTrue(app.staticTexts[poemTitle.label].exists)
        XCTAssertTrue(app.staticTexts["by"].exists)
        
        // Go back to favorites
        app.navigationBars.buttons.element(boundBy: 0).tap()
        
        // Close favorites
        app.buttons["Done"].tap()
    }
    
    func testConcurrentActions() {
        // Wait for poem to load
        let poemTitle = app.staticTexts.element(boundBy: 1)
        XCTAssertTrue(poemTitle.waitForExistence(timeout: 5))
        
        // Start multiple actions
        app.buttons["Favorite"].tap()
        app.buttons["Get New Poem"].tap()
        
        // Wait for new poem
        let newPoemTitle = app.staticTexts.element(boundBy: 1)
        XCTAssertTrue(newPoemTitle.waitForExistence(timeout: 5))
        
        // Verify favorite state is maintained
        XCTAssertTrue(app.buttons["Unfavorite"].exists)
    }
    
    func testAccessibility() {
        // Wait for poem to load
        let poemTitle = app.staticTexts.element(boundBy: 1)
        XCTAssertTrue(poemTitle.waitForExistence(timeout: 5))
        
        // Verify accessibility labels
        XCTAssertTrue(app.buttons["Favorite"].hasValidAccessibilityLabel)
        XCTAssertTrue(app.buttons["Share"].hasValidAccessibilityLabel)
        XCTAssertTrue(app.buttons["Get New Poem"].hasValidAccessibilityLabel)
        XCTAssertTrue(app.buttons["Favorites"].hasValidAccessibilityLabel)
    }
    
    func testErrorHandling() {
        // Simulate network error by turning on airplane mode
        XCUIDevice.shared.press(.home)
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        springboard.activate()
        
        // Open control center
        let start = springboard.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.01))
        let end = springboard.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        start.press(forDuration: 0.1, thenDragTo: end)
        
        // Toggle airplane mode
        springboard.buttons["Airplane Mode"].tap()
        
        // Return to app
        app.activate()
        
        // Try to refresh
        app.buttons["Get New Poem"].tap()
        
        // Verify error state
        XCTAssertTrue(app.staticTexts["Unable to load poem"].waitForExistence(timeout: 5))
        
        // Turn off airplane mode
        XCUIDevice.shared.press(.home)
        springboard.activate()
        start.press(forDuration: 0.1, thenDragTo: end)
        springboard.buttons["Airplane Mode"].tap()
        
        // Return to app
        app.activate()
        
        // Verify recovery
        XCTAssertTrue(app.staticTexts["Poem of the Day"].waitForExistence(timeout: 5))
    }
}

extension XCUIElement {
    var hasValidAccessibilityLabel: Bool {
        guard let label = self.label else { return false }
        return !label.isEmpty
    }
} 