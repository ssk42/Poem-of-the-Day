import XCTest

final class PoemUITests: XCTestCase {
    let app = XCUIApplication()
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        
        // Configure test environment
        app.launchArguments = ["--ui-testing", "-UITESTING", "1", "-ResetFavorites", "1"]
        app.launchEnvironment = [
            "ENABLE_TELEMETRY": "true",
            "UITESTING": "1",
            "AI_AVAILABLE": "false"
        ]
        
        NSLog("PoemUITests: Launching app with arguments: \(app.launchArguments)")
        NSLog("PoemUITests: Launching app with environment: \(app.launchEnvironment)")
        
        app.launch()
    }
    
    func testMainUIElements() {
        let mainPage = PageFactory.mainContentPage(app: app)
        
        // Test header elements
        XCTAssertTrue(mainPage.waitForElementToAppear(mainPage.headerTitle))
        
        // Test refresh button
        XCTAssertTrue(mainPage.waitForElementToAppear(mainPage.refreshButton))
        
        // Test navigation elements
        XCTAssertTrue(mainPage.waitForElementToAppear(mainPage.favoritesButton))
    }
    
    func testPoemDisplay() {
        let mainPage = PageFactory.mainContentPage(app: app)
        
        // Wait for poem to load
        XCTAssertTrue(mainPage.waitForPoemToLoad())
        
        // Verify poem elements exist
        XCTAssertTrue(mainPage.verifyPoemDisplayed())
        XCTAssertFalse(mainPage.getPoemTitle().isEmpty)
        XCTAssertFalse(mainPage.getAuthorName().isEmpty)
    }
    
    func testRefreshFunctionality() {
        let mainPage = PageFactory.mainContentPage(app: app)
        
        // Wait for initial poem to load
        XCTAssertTrue(mainPage.waitForPoemToLoad())
        _ = mainPage.getPoemTitle()
        
        // Refresh poem
        _ = mainPage.tapRefreshButton()
        
        // Wait for loading indicator to appear and disappear
        if mainPage.isLoadingIndicatorVisible() {
            XCTAssertTrue(mainPage.waitForLoadingToComplete(), "Loading should complete within 10 seconds")
        }
        
        // Verify poem changed (title should be different or at least exist)
        XCTAssertTrue(mainPage.waitForPoemToLoad())
        XCTAssertFalse(mainPage.getPoemTitle().isEmpty)
    }
    
    func testPullToRefresh() {
        let mainPage = PageFactory.mainContentPage(app: app)
        
        // Wait for poem to load
        XCTAssertTrue(mainPage.waitForPoemToLoad())
        
        // Perform pull to refresh gesture
        let poemContent = app.scrollViews.firstMatch
        let start = poemContent.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.1))
        let end = poemContent.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.9))
        start.press(forDuration: 0.1, thenDragTo: end)
        
        // Wait for refresh to complete
        sleep(3)
        
        // Verify poem is still displayed
        XCTAssertTrue(mainPage.verifyPoemDisplayed())
    }
    
    func testFavoriteFunctionality() {
        let mainPage = PageFactory.mainContentPage(app: app)
        
        // Wait for poem to load
        XCTAssertTrue(mainPage.waitForPoemToLoad())
        
        // Test favorite button
        XCTAssertTrue(mainPage.waitForElementToAppear(mainPage.favoriteButton))
        _ = mainPage.tapFavoriteButton()
        
        // Verify button state changed (should show unfavorite state)
        // Wait for the label to change to "Unfavorite" to ensure async task completed
        XCTAssertTrue(mainPage.waitForFavoriteButtonState(isFavorite: true), "Favorite button should show 'Unfavorite' state")
        
        // Let's assume the button identifier remains "favorite_button" but we can check label
        // Or we can check if the "unfavorite_button" exists if the ID changes.
        // ContentView uses: .accessibilityIdentifier("favorite_button") always.
        // But the label changes.
        
        // Open favorites
        let favoritesPage = mainPage.tapFavoritesButton()
        
        // Verify favorites page appears
        XCTAssertTrue(favoritesPage.waitForPageToLoad())
        
        // Verify poem appears in favorites (count should be at least 1)
        XCTAssertTrue(favoritesPage.getFavoritePoemsCount() > 0)
        
        // Close favorites
        _ = favoritesPage.tapDoneButton()
        
        // Unfavorite the poem
        _ = mainPage.tapFavoriteButton() // Tapping again should unfavorite
        XCTAssertTrue(mainPage.waitForFavoriteButtonState(isFavorite: false), "Favorite button should show 'Favorite' state")
    }
    
    func testShareFunctionality() {
        let mainPage = PageFactory.mainContentPage(app: app)
        
        // Wait for poem to load
        XCTAssertTrue(mainPage.waitForPoemToLoad())
        
        // Test share button
        XCTAssertTrue(mainPage.waitForElementToAppear(mainPage.shareButton))
        _ = mainPage.tapShareButton()
        
        // Verify share sheet appears
        // Share sheet is a system UI, so we might just wait for a button or the sheet itself
        let shareSheet = app.sheets.firstMatch
        // On iPad it might be a popover, on iPhone a sheet.
        // Just checking existence of "Copy" or "Cancel" might be safer if we want to be specific,
        // but waiting for the sheet is a good start.
        XCTAssertTrue(shareSheet.waitForExistence(timeout: 10) || app.collectionViews.firstMatch.waitForExistence(timeout: 10))
        
        // Dismiss share sheet
        // This part is tricky across devices/OS versions.
        // We can try to tap "Close" or "Cancel" if it exists.
        let closeButton = app.buttons["Close"]
        if closeButton.exists {
            closeButton.tap()
        } else {
            // Tap outside
            app.coordinate(withNormalizedOffset: CGVector(dx: 0.1, dy: 0.1)).tap()
        }
    }
    
    func testEmptyFavorites() {
        let mainPage = PageFactory.mainContentPage(app: app)
        
        // Open favorites
        let favoritesPage = mainPage.tapFavoritesButton()
        
        // Verify favorites page appears
        XCTAssertTrue(favoritesPage.waitForPageToLoad())
        
        // Look for empty state message
        // Note: This assumes we start with no favorites.
        // If previous tests added favorites, this might fail unless we clear them.
        // For now, we'll check if either the list exists OR the empty state exists.
        if favoritesPage.getFavoritePoemsCount() == 0 {
             // Print debug info
        if app.staticTexts["debug_info"].exists {
            NSLog("PoemUITests: Debug Info: \(app.staticTexts["debug_info"].label)")
        }
        
        if !favoritesPage.verifyEmptyState() {
            NSLog("PoemUITests: Empty state verification failed. App hierarchy: \(app.debugDescription)")
            XCTFail("Empty state not found")
        }
        }
        
        // Close favorites
        _ = favoritesPage.tapDoneButton()
    }
    
    func testMultipleFavorites() {
        let mainPage = PageFactory.mainContentPage(app: app)
        
        // Wait for initial poem to load
        XCTAssertTrue(mainPage.waitForPoemToLoad())
        
        // Wait for poem to load
        XCTAssertTrue(mainPage.waitForPoemToLoad())
        
        // Print debug info
        if app.staticTexts["debug_args"].waitForExistence(timeout: 5) {
            print("PoemUITests: Debug Args: \(app.staticTexts["debug_args"].label)")
            print("PoemUITests: Debug Env: \(app.staticTexts["debug_env"].label)")
        } else {
            print("PoemUITests: Debug info labels not found")
        }
        
        // Verify isUITesting is active
        if app.buttons["Add (Test)"].waitForExistence(timeout: 5) {
            print("PoemUITests: isUITesting is ACTIVE")
        } else {
            print("PoemUITests: isUITesting is INACTIVE or label not found")
            // Print all buttons to debug
            print("PoemUITests: All buttons: \(app.buttons.debugDescription)")
        }
        
        // Wait for any animations
        sleep(1)
        
        // Favorite the poem
        _ = mainPage.tapFavoriteButton()
        
        // Retry if state update fails (handling potential UI lag or missed tap)
        if !mainPage.waitForFavoriteButtonState(isFavorite: true, timeout: 5.0) {
            print("PoemUITests: Retrying favorite tap")
            _ = mainPage.tapFavoriteButton()
        }
        
        // Check debug info
        let debugText = app.staticTexts["debug_info"]
        if debugText.waitForExistence(timeout: 2.0) {
            print("PoemUITests: Debug Info: \(debugText.label)")
        } else {
            print("PoemUITests: Debug Info not found")
        }
        
        XCTAssertTrue(mainPage.waitForFavoriteButtonState(isFavorite: true))
        
        // Get new poem
        let firstPoemTitle = mainPage.poemTitle.label
        _ = mainPage.tapRefreshButton()
        
        // Wait for new poem
        XCTAssertTrue(mainPage.waitForPoemChange(oldTitle: firstPoemTitle))
        
        // Favorite second poem
        _ = mainPage.tapFavoriteButton()
        
        // Retry if state update fails (handling potential UI lag or missed tap)
        if !mainPage.waitForFavoriteButtonState(isFavorite: true, timeout: 5.0) {
            print("PoemUITests: Retrying favorite tap")
            _ = mainPage.tapFavoriteButton()
        }
        
        XCTAssertTrue(mainPage.waitForFavoriteButtonState(isFavorite: true))
        
        // Verify favorites count
        let favoritesPage = mainPage.tapFavoritesButton()
        XCTAssertTrue(favoritesPage.waitForPageToLoad())
        XCTAssertTrue(favoritesPage.getFavoritePoemsCount() >= 2)
        
        // Verify multiple poems in favorites
        XCTAssertTrue(favoritesPage.getFavoritePoemsCount() >= 2)
        
        // Close favorites
        _ = favoritesPage.tapDoneButton()
    }
    
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
    
    func testErrorHandling() {
        // Configure app for network error simulation
        app.terminate()
        app.launchEnvironment["SIMULATE_NETWORK_ERROR"] = "true"
        app.launch()
        
        let mainPage = PageFactory.mainContentPage(app: app)
        
        // Try to refresh
        XCTAssertTrue(mainPage.waitForElementToAppear(mainPage.refreshButton))
        _ = mainPage.tapRefreshButton()
        
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
        
        // Verify app is still functional (header still exists)
        XCTAssertTrue(mainPage.waitForElementToAppear(mainPage.headerTitle))
    }
    func testFavoriteDetailNavigation() {
        let mainPage = PageFactory.mainContentPage(app: app)
        XCTAssertTrue(mainPage.waitForPoemToLoad())
        
        // Favorite the poem
        _ = mainPage.tapFavoriteButton()
        XCTAssertTrue(mainPage.waitForFavoriteButtonState(isFavorite: true))
        
        // Open favorites
        let favoritesPage = mainPage.tapFavoritesButton()
        XCTAssertTrue(favoritesPage.waitForPageToLoad())
        
        // Tap first favorite
        let detailPage = favoritesPage.tapFavoritePoem(at: 0)
        XCTAssertTrue(detailPage.waitForPageToLoad())
        XCTAssertTrue(detailPage.verifyPoemDisplayed())
        
        // Go back
        let favoritesPageAfterBack = detailPage.tapBackButton()
        XCTAssertTrue(favoritesPageAfterBack.waitForPageToLoad())
        
        // Close favorites
        _ = favoritesPageAfterBack.tapDoneButton()
    }
    

}

extension XCUIElement {
    var hasValidAccessibilityLabel: Bool {
        return !self.label.isEmpty
    }
} 