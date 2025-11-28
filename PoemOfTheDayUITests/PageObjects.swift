import XCTest

// MARK: - Page Factory

class PageFactory {
    static func mainContentPage(app: XCUIApplication) -> MainContentPage {
        return MainContentPage(app: app)
    }
    
    static func vibeGenerationPage(app: XCUIApplication) -> VibeGenerationPage {
        return VibeGenerationPage(app: app)
    }
    
    static func customPromptPage(app: XCUIApplication) -> CustomPromptPage {
        return CustomPromptPage(app: app)
    }
    
    static func favoritesPage(app: XCUIApplication) -> FavoritesPage {
        return FavoritesPage(app: app)
    }
    
    static func telemetryDebugPage(app: XCUIApplication) -> TelemetryDebugPage {
        return TelemetryDebugPage(app: app)
    }
    
    static func settingsPage(app: XCUIApplication) -> SettingsPage {
        return SettingsPage(app: app)
    }
    
    static func historyPage(app: XCUIApplication) -> HistoryPage {
        return HistoryPage(app: app)
    }
}

// MARK: - Base Page

class BasePage {
    let app: XCUIApplication
    
    init(app: XCUIApplication) {
        self.app = app
    }
    
    func waitForElementToAppear(_ element: XCUIElement, timeout: TimeInterval = 10) -> Bool {
        let predicate = NSPredicate(format: "exists == true")
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: element)
        let result = XCTWaiter.wait(for: [expectation], timeout: timeout)
        return result == .completed
    }
    
    func waitForElementToDisappear(_ element: XCUIElement, timeout: TimeInterval = 10) -> Bool {
        let predicate = NSPredicate(format: "exists == false")
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: element)
        let result = XCTWaiter.wait(for: [expectation], timeout: timeout)
        return result == .completed
    }
}

// MARK: - Main Content Page

class MainContentPage: BasePage {
    
    // Elements
    var poemTitle: XCUIElement { app.staticTexts["poem_title"] }
    var poemContent: XCUIElement { app.staticTexts["poem_content"] }
    var poemAuthor: XCUIElement { app.staticTexts["poem_author"] }
    var refreshButton: XCUIElement { app.buttons["refresh_button"] }
    var favoritesButton: XCUIElement { app.buttons["favorites_button"] }
    var vibeGenerationSheet: XCUIElement { app.staticTexts["current_vibe"] }
    var customPromptSheet: XCUIElement { app.textViews["custom_prompt_text_field"] }
    var vibeGenerationButton: XCUIElement { app.buttons["top_vibe_poem_button"] }
    var customPromptButton: XCUIElement { app.buttons["top_custom_poem_button"] }
    var favoriteButton: XCUIElement { app.buttons["favorite_button"] }
    var unfavoriteButton: XCUIElement { app.buttons["unfavorite_button"] }
    var shareButton: XCUIElement { app.buttons["share_button"] }
    var loadingIndicator: XCUIElement { app.activityIndicators.firstMatch }
    var headerTitle: XCUIElement { app.staticTexts["Poem of the Day"] }
    var menuButton: XCUIElement { app.buttons["menu_button"] }
    var historyButton: XCUIElement { app.buttons["History"] }
    var settingsButton: XCUIElement { app.buttons["Settings"] }
    
    override init(app: XCUIApplication) {
        super.init(app: app)
    }
    
    // MARK: - Actions
    
    func waitForHeaderToLoad() -> Bool {
        return waitForElementToAppear(headerTitle)
    }
    
    func waitForPoemToLoad() -> Bool {
        return waitForElementToAppear(poemTitle)
    }
    
    func tapRefreshButton() -> MainContentPage {
        _ = waitForElementToAppear(refreshButton)
        refreshButton.tap()
        return self
    }
    
    func tapFavoriteButton() -> MainContentPage {
        _ = waitForElementToAppear(favoriteButton)
        favoriteButton.tap()
        return self
    }
    
    func tapUnfavoriteButton() -> MainContentPage {
        unfavoriteButton.tap()
        return self
    }
    
    func tapShareButton() -> MainContentPage {
        _ = waitForElementToAppear(shareButton)
        shareButton.tap()
        return self
    }
    
    func tapFavoritesButton() -> FavoritesPage {
        _ = waitForElementToAppear(favoritesButton)
        favoritesButton.tap()
        return PageFactory.favoritesPage(app: app)
    }
    
    func tapVibeGenerationButton() -> VibeGenerationPage {
        _ = waitForElementToAppear(vibeGenerationButton)
        vibeGenerationButton.tap()
        return PageFactory.vibeGenerationPage(app: app)
    }
    
    func tapCustomPromptButton() -> CustomPromptPage {
        _ = waitForElementToAppear(customPromptButton)
        customPromptButton.tap()
        return PageFactory.customPromptPage(app: app)
    }
    
    func tapMenuButton() -> MainContentPage {
        if waitForElementToAppear(menuButton) {
            if menuButton.isHittable {
                menuButton.tap()
            } else {
                // Fallback to coordinate tap if not hittable (e.g. XCTest thinks it's off screen)
                menuButton.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
            }
        }
        return self
    }
    
    func tapHistoryButton() -> MainContentPage { // Should return HistoryPage eventually
        _ = waitForElementToAppear(historyButton)
        historyButton.tap()
        return self
    }
    
    func tapSettingsButton() -> MainContentPage { // Should return SettingsPage eventually
        _ = waitForElementToAppear(settingsButton)
        settingsButton.tap()
        return self
    }
    
    // MARK: - Getters
    
    func getPoemTitle() -> String {
        return poemTitle.label
    }
    
    func getPoemContent() -> String {
        return poemContent.label
    }
    
    func getAuthorName() -> String {
        return poemAuthor.label
    }
    
    func isFavoriteButtonSelected() -> Bool {
        return favoriteButton.isSelected
    }
    
    func isLoadingIndicatorVisible() -> Bool {
        return loadingIndicator.exists && loadingIndicator.isHittable
    }
    
    // MARK: - Verifications
    
    func verifyPoemDisplayed() -> Bool {
        return poemTitle.exists && poemContent.exists && poemAuthor.exists
    }
    
    func verifyNavigationButtonsDisplayed() -> Bool {
        return vibeGenerationButton.exists && customPromptButton.exists && favoritesButton.exists
    }
    
    // MARK: - Missing Methods for Tests
    
    func waitForLoadingToComplete(timeout: TimeInterval = 10) -> Bool {
        return waitForElementToDisappear(loadingIndicator, timeout: timeout)
    }
    
    func verifyPoemIsDisplayed() -> Bool {
        return verifyPoemDisplayed()
    }
    
    func waitForPageToLoad(timeout: TimeInterval = 5) -> Bool {
        return waitForPoemToLoad()
    }
    
    func isDisplayed() -> Bool {
        return verifyPoemDisplayed()
    }
    
    func waitForFavoriteButtonState(isFavorite: Bool, timeout: TimeInterval = 5.0) -> Bool {
        let expectedLabel = isFavorite ? "Unfavorite" : "Favorite"
        let predicate = NSPredicate(format: "label == %@", expectedLabel)
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: favoriteButton)
        return XCTWaiter().wait(for: [expectation], timeout: timeout) == .completed
    }
}

// MARK: - Vibe Generation Page

class VibeGenerationPage: BasePage {
    
    // MARK: - UI Elements
    
    var navigationTitle: XCUIElement {
        app.navigationBars["Today's Vibe"]
    }
    
    var cancelButton: XCUIElement {
        app.buttons["Cancel"]
    }
    
    var currentVibeLabel: XCUIElement {
        app.staticTexts.matching(identifier: "current_vibe").firstMatch
    }
    
    var generateButton: XCUIElement {
        app.buttons.matching(identifier: "generate_vibe_poem_button").firstMatch
    }
    
    var loadingIndicator: XCUIElement {
        app.activityIndicators.firstMatch
    }
    
    var errorMessage: XCUIElement {
        app.staticTexts.matching(identifier: "error_message").firstMatch
    }
    
    // MARK: - Actions
    
    func waitForPageToLoad() -> Bool {
        return waitForElementToAppear(currentVibeLabel)
    }
    
    func tapCancelButton() -> MainContentPage {
        cancelButton.tap()
        return MainContentPage(app: app)
    }
    
    func tapBackButton() -> MainContentPage {
        return tapCancelButton()
    }
    
    func tapGenerateButton() -> MainContentPage {
        generateButton.tap()
        // Wait a moment for the sheet to dismiss and return to main
        usleep(500000)
        return MainContentPage(app: app)
    }
    
    // MARK: - Getters
    
    func getCurrentVibe() -> String {
        return currentVibeLabel.label
    }
    
    func isGenerateButtonEnabled() -> Bool {
        return generateButton.isEnabled
    }
    
    func isLoadingIndicatorVisible() -> Bool {
        return loadingIndicator.exists && loadingIndicator.isHittable
    }
    
    // MARK: - Verifications
    
    func verifyPageDisplayed() -> Bool {
        return currentVibeLabel.exists && generateButton.exists
    }
}

// MARK: - Custom Prompt Page

class CustomPromptPage: BasePage {
    
    // MARK: - UI Elements
    
    var navigationTitle: XCUIElement {
        app.navigationBars["Custom Poem"]
    }
    
    var cancelButton: XCUIElement {
        app.buttons["Cancel"]
    }
    
    var promptTextField: XCUIElement {
        app.textViews.matching(identifier: "custom_prompt_text_field").firstMatch
    }
    
    var generateButton: XCUIElement {
        app.buttons.matching(identifier: "generate_custom_poem_button").firstMatch
    }
    
    var clearButton: XCUIElement {
        app.buttons["Clear"]
    }
    
    var loadingIndicator: XCUIElement {
        app.activityIndicators.firstMatch
    }
    
    var errorMessage: XCUIElement {
        app.staticTexts.matching(identifier: "error_message").firstMatch
    }
    
    // MARK: - Actions
    
    func waitForPageToLoad() -> Bool {
        return waitForElementToAppear(promptTextField)
    }
    
    func tapCancelButton() -> MainContentPage {
        cancelButton.tap()
        return MainContentPage(app: app)
    }
    
    func tapBackButton() -> MainContentPage {
        return tapCancelButton()
    }
    
    func enterPrompt(_ prompt: String) -> CustomPromptPage {
        promptTextField.tap()
        promptTextField.typeText(prompt)
        return self
    }
    
    func clearPrompt() -> CustomPromptPage {
        clearButton.tap()
        return self
    }
    
    func tapGenerateButton() -> MainContentPage {
        generateButton.tap()
        // Wait a moment for the sheet to dismiss and return to main
        usleep(500000)
        return MainContentPage(app: app)
    }
    
    // MARK: - Getters
    
    func getPromptText() -> String {
        return promptTextField.value as? String ?? ""
    }
    
    func isGenerateButtonEnabled() -> Bool {
        return generateButton.isEnabled
    }
    
    func isLoadingIndicatorVisible() -> Bool {
        return loadingIndicator.exists && loadingIndicator.isHittable
    }
    
    // MARK: - Verifications
    
    func verifyPageDisplayed() -> Bool {
        return promptTextField.exists && generateButton.exists
    }
    

}

// MARK: - Favorites Page

class FavoritesPage: BasePage {
    
    // MARK: - UI Elements
    
    var navigationTitle: XCUIElement {
        app.navigationBars["Favorite Poems"]
    }
    
    var doneButton: XCUIElement {
        app.buttons["Done"]
    }
    
    var favoritesTable: XCUIElement {
        app.tables.firstMatch
    }
    
    var favoritesList: XCUIElement {
        return favoritesTable
    }
    
    var emptyStateMessage: XCUIElement {
        app.staticTexts["No Favorite Poems Yet"]
    }
    
    // MARK: - Actions
    
    func waitForPageToLoad() -> Bool {
        return waitForElementToAppear(navigationTitle)
    }
    
    func tapDoneButton() -> MainContentPage {
        doneButton.tap()
        return MainContentPage(app: app)
    }
    
    func tapFavoritePoem(at index: Int) -> FavoritesPage {
        let cells = favoritesTable.cells
        if cells.count > index {
            cells.element(boundBy: index).tap()
        }
        return self
    }
    
    // MARK: - Getters
    
    func getFavoritePoemsCount() -> Int {
        return favoritesTable.cells.count
    }
    
    func isEmptyStateVisible() -> Bool {
        return emptyStateMessage.exists
    }
    
    func verifyEmptyState() -> Bool {
        return isEmptyStateVisible()
    }
    
    // MARK: - Verifications
    
    func verifyPageDisplayed() -> Bool {
        return navigationTitle.exists
    }
}

// MARK: - Telemetry Debug Page

class TelemetryDebugPage: BasePage {
    
    // MARK: - UI Elements
    
    var navigationTitle: XCUIElement {
        app.navigationBars["Telemetry Debug"]
    }
    
    var backButton: XCUIElement {
        app.navigationBars.buttons["Back"]
    }
    
    var eventsList: XCUIElement {
        app.tables.firstMatch
    }
    
    var exportButton: XCUIElement {
        app.buttons["Export Data"]
    }
    
    var clearButton: XCUIElement {
        app.buttons["Clear Data"]
    }
    
    // MARK: - Actions
    
    func waitForPageToLoad() -> Bool {
        return waitForElementToAppear(navigationTitle)
    }
    
    func tapBackButton() -> MainContentPage {
        backButton.tap()
        return MainContentPage(app: app)
    }
    
    func tapExportButton() -> TelemetryDebugPage {
        exportButton.tap()
        return self
    }
    
    func tapClearButton() -> TelemetryDebugPage {
        clearButton.tap()
        return self
    }
    
    // MARK: - Getters
    
    func getEventsCount() -> Int {
        return eventsList.cells.count
    }
    
    // MARK: - Verifications
    
    func verifyPageDisplayed() -> Bool {
        return navigationTitle.exists && eventsList.exists
    }
    
    func verifyEventExists(withName name: String) -> Bool {
        return eventsList.staticTexts[name].exists
    }
}

// MARK: - Settings Page

class SettingsPage: BasePage {
    
    // MARK: - UI Elements
    
    var navigationTitle: XCUIElement {
        app.navigationBars["Settings"]
    }
    
    var doneButton: XCUIElement {
        app.buttons["Done"]
    }
    
    var notificationSettingsButton: XCUIElement {
        app.buttons["notification_settings_button"]
    }
    
    // MARK: - Actions
    
    func waitForPageToLoad() -> Bool {
        return waitForElementToAppear(navigationTitle)
    }
    
    func tapDoneButton() -> MainContentPage {
        doneButton.tap()
        return MainContentPage(app: app)
    }
    
    // MARK: - Verifications
    
    func verifyPageDisplayed() -> Bool {
        return navigationTitle.exists
    }
}

// MARK: - History Page

class HistoryPage: BasePage {
    
    // MARK: - UI Elements
    
    var navigationTitle: XCUIElement {
        app.navigationBars["Poem History"]
    }
    
    var doneButton: XCUIElement {
        app.buttons["Done"]
    }
    
    var emptyStateMessage: XCUIElement {
        app.staticTexts["No Poem History Yet"]
    }
    
    var menuButton: XCUIElement {
        app.buttons["history_menu_button"]
    }
    
    var clearHistoryButton: XCUIElement {
        app.buttons["Clear History"]
    }
    
    var clearAllConfirmationButton: XCUIElement {
        app.buttons["Clear All"]
    }
    
    // MARK: - Actions
    
    func waitForPageToLoad() -> Bool {
        return waitForElementToAppear(navigationTitle)
    }
    
    func tapDoneButton() -> MainContentPage {
        doneButton.tap()
        return MainContentPage(app: app)
    }
    
    func tapMenuButton() -> HistoryPage {
        menuButton.tap()
        return self
    }
    
    func tapClearHistoryButton() -> HistoryPage {
        clearHistoryButton.tap()
        return self
    }
    
    func tapClearAllConfirmationButton() -> HistoryPage {
        clearAllConfirmationButton.tap()
        return self
    }
    
    // MARK: - Verifications
    
    func verifyPageDisplayed() -> Bool {
        return navigationTitle.exists
    }
    
    func verifyEmptyState() -> Bool {
        return waitForElementToAppear(emptyStateMessage)
    }
}