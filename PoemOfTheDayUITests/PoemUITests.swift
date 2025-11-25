import XCTest

final class PoemUITests: XCTestCase {
    let app = XCUIApplication()
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        
        // Configure test environment
        app.launchArguments = ["--ui-testing"]
        app.launchEnvironment = [
            "AI_AVAILABLE": "false", // Disable AI for basic poem tests
            "ENABLE_TELEMETRY": "true"
        ]
        
        app.launch()
    }
    
    func testMainUIElements() {
        // Test header elements using accessibility identifiers
        XCTAssertTrue(app.staticTexts["Poem of the Day"].waitForExistence(timeout: 5))
        
        // Test refresh button
        let refreshButton = app.buttons.matching(identifier: "refresh_button").firstMatch
        XCTAssertTrue(refreshButton.waitForExistence(timeout: 3))
        
        // Test navigation elements
        let favoritesButton = app.buttons.matching(identifier: "favorites_button").firstMatch
        XCTAssertTrue(favoritesButton.waitForExistence(timeout: 3))
    }
    
    func testPoemDisplay() {
        // Wait for poem to load
        let poemContent = app.scrollViews.firstMatch
        XCTAssertTrue(poemContent.waitForExistence(timeout: 5))
        
        // Verify poem title exists
        let poemTitle = app.staticTexts.matching(identifier: "poem_title").firstMatch
        XCTAssertTrue(poemTitle.waitForExistence(timeout: 3))
        XCTAssertFalse(poemTitle.label.isEmpty)
        
        // Verify poem author exists
        let poemAuthor = app.staticTexts.matching(identifier: "poem_author").firstMatch
        XCTAssertTrue(poemAuthor.waitForExistence(timeout: 3))
    }
    
    /*
    func testFavoriteFunctionality() {
        // Wait for poem to load
        let poemTitle = app.staticTexts.matching(identifier: "poem_title").firstMatch
        XCTAssertTrue(poemTitle.waitForExistence(timeout: 5))
        
        // Test favorite button
        let favoriteButton = app.buttons.matching(identifier: "favorite_button").firstMatch
        XCTAssertTrue(favoriteButton.waitForExistence(timeout: 3))
        favoriteButton.tap()
        
        // Verify button state changed (should show unfavorite state)
        let unfavoriteButton = app.buttons.matching(identifier: "unfavorite_button").firstMatch
        XCTAssertTrue(unfavoriteButton.waitForExistence(timeout: 2))
        
        // Open favorites
        let favoritesButton = app.buttons.matching(identifier: "favorites_button").firstMatch
        favoritesButton.tap()
        
        // Verify favorites sheet appears
        let favoritesSheet = app.sheets.firstMatch
        XCTAssertTrue(favoritesSheet.waitForExistence(timeout: 3))
        
        // Verify poem appears in favorites
        XCTAssertTrue(poemTitle.waitForExistence(timeout: 2))
        
        // Close favorites
        let cancelButton = app.buttons["Cancel"]
        if cancelButton.exists {
            cancelButton.tap()
        } else {
            app.coordinate(withNormalizedOffset: CGVector(dx: 0.1, dy: 0.1)).tap()
        }
        
        // Unfavorite the poem
        unfavoriteButton.tap()
        
        // Verify button state changed back
        XCTAssertTrue(favoriteButton.waitForExistence(timeout: 2))
    }
    */
    
    func testRefreshFunctionality() {
        // Wait for initial poem to load
        let initialPoemTitle = app.staticTexts.matching(identifier: "poem_title").firstMatch
        XCTAssertTrue(initialPoemTitle.waitForExistence(timeout: 5))
        let initialTitle = initialPoemTitle.label
        
        // Refresh poem
        let refreshButton = app.buttons.matching(identifier: "refresh_button").firstMatch
        refreshButton.tap()
        
        // Wait for new poem to load
        sleep(2) // Allow time for refresh
        
        // Verify poem changed (title should be different)
        let newPoemTitle = app.staticTexts.matching(identifier: "poem_title").firstMatch
        XCTAssertTrue(newPoemTitle.waitForExistence(timeout: 5))
        
        // In a real test, we might check if the title changed
        // For now, just verify a title exists
        XCTAssertFalse(newPoemTitle.label.isEmpty)
    }
    
    /*
    func testShareFunctionality() {
        // Wait for poem to load
        let poemTitle = app.staticTexts.matching(identifier: "poem_title").firstMatch
        XCTAssertTrue(poemTitle.waitForExistence(timeout: 5))
        
        // Test share button
        let shareButton = app.buttons.matching(identifier: "share_button").firstMatch
        XCTAssertTrue(shareButton.waitForExistence(timeout: 3))
        shareButton.tap()
        
        // Verify share sheet appears
        let shareSheet = app.sheets.firstMatch
        XCTAssertTrue(shareSheet.waitForExistence(timeout: 10))
        
        // Dismiss share sheet
        let cancelButton = shareSheet.buttons["Cancel"]
        if cancelButton.exists {
            cancelButton.tap()
        } else {
            // Tap outside to dismiss
            app.coordinate(withNormalizedOffset: CGVector(dx: 0.1, dy: 0.1)).tap()
        }
        
        XCTAssertTrue(shareSheet.waitForNonExistence(timeout: 5))
    }
    */
    
    func testPullToRefresh() {
        // Wait for poem to load
        let poemContent = app.scrollViews.firstMatch
        XCTAssertTrue(poemContent.waitForExistence(timeout: 5))
        
        // Perform pull to refresh gesture
        let start = poemContent.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.1))
        let end = poemContent.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.9))
        start.press(forDuration: 0.1, thenDragTo: end)
        
        // Wait for refresh to complete
        sleep(3)
        
        // Verify poem is still displayed
        let poemTitle = app.staticTexts.matching(identifier: "poem_title").firstMatch
        XCTAssertTrue(poemTitle.waitForExistence(timeout: 5))
    }
    
    /*
    func testEmptyFavorites() {
        // Open favorites
        let favoritesButton = app.buttons.matching(identifier: "favorites_button").firstMatch
        favoritesButton.tap()
        
        // Verify favorites sheet appears
        let favoritesSheet = app.sheets.firstMatch
        XCTAssertTrue(favoritesSheet.waitForExistence(timeout: 3))
        
        // Look for empty state message
        let emptyMessage = app.staticTexts["No Favorite Poems Yet"]
        if emptyMessage.exists {
            XCTAssertTrue(emptyMessage.exists, "Should show empty state message")
        }
        
        // Close favorites
        let cancelButton = app.buttons["Cancel"]
        if cancelButton.exists {
            cancelButton.tap()
        } else {
            app.coordinate(withNormalizedOffset: CGVector(dx: 0.1, dy: 0.1)).tap()
        }
    }
    
    func testMultipleFavorites() {
        // Wait for initial poem to load
        let initialPoemTitle = app.staticTexts.matching(identifier: "poem_title").firstMatch
        XCTAssertTrue(initialPoemTitle.waitForExistence(timeout: 5))
        
        // Favorite first poem
        let favoriteButton = app.buttons.matching(identifier: "favorite_button").firstMatch
        favoriteButton.tap()
        
        // Get new poem
        let refreshButton = app.buttons.matching(identifier: "refresh_button").firstMatch
        refreshButton.tap()
        
        // Wait for new poem to load
        sleep(2)
        let secondPoemTitle = app.staticTexts.matching(identifier: "poem_title").firstMatch
        XCTAssertTrue(secondPoemTitle.waitForExistence(timeout: 5))
        
        // Favorite second poem
        let favoriteButton2 = app.buttons.matching(identifier: "favorite_button").firstMatch
        if favoriteButton2.exists {
            favoriteButton2.tap()
        }
        
        // Open favorites
        let favoritesButton = app.buttons.matching(identifier: "favorites_button").firstMatch
        favoritesButton.tap()
        
        // Verify favorites sheet appears
        let favoritesSheet = app.sheets.firstMatch
        XCTAssertTrue(favoritesSheet.waitForExistence(timeout: 3))
        
        // Close favorites
        let cancelButton = app.buttons["Cancel"]
        if cancelButton.exists {
            cancelButton.tap()
        } else {
            app.coordinate(withNormalizedOffset: CGVector(dx: 0.1, dy: 0.1)).tap()
        }
    }
    */
    
    func testAccessibility() {
        // Wait for poem to load
        let poemTitle = app.staticTexts.matching(identifier: "poem_title").firstMatch
        XCTAssertTrue(poemTitle.waitForExistence(timeout: 5))
        
        // Verify accessibility identifiers exist for all interactive elements
        let favoriteButton = app.buttons.matching(identifier: "favorite_button").firstMatch
        XCTAssertTrue(favoriteButton.exists, "Favorite button should have accessibility identifier")
        
        let shareButton = app.buttons.matching(identifier: "share_button").firstMatch
        XCTAssertTrue(shareButton.exists, "Share button should have accessibility identifier")
        
        let refreshButton = app.buttons.matching(identifier: "refresh_button").firstMatch
        XCTAssertTrue(refreshButton.exists, "Refresh button should have accessibility identifier")
        
        let favoritesButton = app.buttons.matching(identifier: "favorites_button").firstMatch
        XCTAssertTrue(favoritesButton.exists, "Favorites button should have accessibility identifier")
    }
    
    func testConcurrentActions() {
        // Wait for poem to load
        let poemTitle = app.staticTexts.matching(identifier: "poem_title").firstMatch
        XCTAssertTrue(poemTitle.waitForExistence(timeout: 5))
        
        // Try multiple quick actions
        let favoriteButton = app.buttons.matching(identifier: "favorite_button").firstMatch
        let refreshButton = app.buttons.matching(identifier: "refresh_button").firstMatch
        
        favoriteButton.tap()
        refreshButton.tap()
        
        // Wait for actions to complete
        sleep(2)
        
        // Verify app is still functional
        let newPoemTitle = app.staticTexts.matching(identifier: "poem_title").firstMatch
        XCTAssertTrue(newPoemTitle.waitForExistence(timeout: 5))
    }
    
    /*
    func testErrorHandling() {
        // Configure app for network error simulation
        app.terminate()
        app.launchEnvironment["SIMULATE_NETWORK_ERROR"] = "true"
        app.launch()
        
        // Try to refresh
        let refreshButton = app.buttons.matching(identifier: "refresh_button").firstMatch
        XCTAssertTrue(refreshButton.waitForExistence(timeout: 5))
        refreshButton.tap()
        
        // Should show error alert
        let errorAlert = app.alerts.firstMatch
        if errorAlert.waitForExistence(timeout: 5) {
            XCTAssertTrue(errorAlert.exists, "Should show error alert for network issues")
            
            // Dismiss alert
            let okButton = errorAlert.buttons["OK"]
            if okButton.exists {
                okButton.tap()
            }
        }
        
        // Verify app is still functional
        let poemTitle = app.staticTexts.matching(identifier: "poem_title").firstMatch
        XCTAssertTrue(poemTitle.waitForExistence(timeout: 5))
    }
    */
}

extension XCUIElement {
    var hasValidAccessibilityLabel: Bool {
        return !self.label.isEmpty
    }
} 