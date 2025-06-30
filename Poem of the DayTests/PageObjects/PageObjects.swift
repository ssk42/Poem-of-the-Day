import XCTest
import Foundation

// MARK: - Base Page Object

class BasePage {
    let app: XCUIApplication
    
    init(app: XCUIApplication) {
        self.app = app
    }
    
    func waitForPageToLoad(timeout: TimeInterval = 10.0) -> Bool {
        return true // Override in subclasses
    }
    
    func isDisplayed() -> Bool {
        return true // Override in subclasses
    }
}

// MARK: - Main Content Page

class MainContentPage: BasePage {
    
    // MARK: - UI Elements
    
    var headerTitle: XCUIElement {
        app.staticTexts["Poem of the Day"]
    }
    
    var dateLabel: XCUIElement {
        app.staticTexts.matching(identifier: "date_label").firstMatch
    }
    
    var poemTitle: XCUIElement {
        app.staticTexts.matching(identifier: "poem_title").firstMatch
    }
    
    var poemAuthor: XCUIElement {
        app.staticTexts.matching(identifier: "poem_author").firstMatch
    }
    
    var poemContent: XCUIElement {
        app.textViews.matching(identifier: "poem_content").firstMatch
    }
    
    var favoriteButton: XCUIElement {
        app.buttons["Add to favorites"]
    }
    
    var unfavoriteButton: XCUIElement {
        app.buttons["Remove from favorites"]
    }
    
    var shareButton: XCUIElement {
        app.buttons["Share"]
    }
    
    var refreshButton: XCUIElement {
        app.buttons["Get New Poem"]
    }
    
    var favoritesButton: XCUIElement {
        app.buttons["Favorites"]
    }
    
    var vibeGenerationButton: XCUIElement {
        app.buttons["Generate Vibe Poem"]
    }
    
    var customPromptButton: XCUIElement {
        app.buttons["Custom Poem"]
    }
    
    var loadingIndicator: XCUIElement {
        app.activityIndicators.firstMatch
    }
    
    var errorAlert: XCUIElement {
        app.alerts["Error"]
    }
    
    // MARK: - Actions
    
    @discardableResult
    func waitForPageToLoad(timeout: TimeInterval = 10.0) -> Bool {
        return headerTitle.waitForExistence(timeout: timeout)
    }
    
    func isDisplayed() -> Bool {
        return headerTitle.exists && refreshButton.exists
    }
    
    func tapFavoriteButton() -> MainContentPage {
        favoriteButton.tap()
        return self
    }
    
    func tapUnfavoriteButton() -> MainContentPage {
        unfavoriteButton.tap()
        return self
    }
    
    func tapShareButton() -> ShareSheetPage {
        shareButton.tap()
        return ShareSheetPage(app: app)
    }
    
    func tapRefreshButton() -> MainContentPage {
        refreshButton.tap()
        return self
    }
    
    func tapFavoritesButton() -> FavoritesPage {
        favoritesButton.tap()
        return FavoritesPage(app: app)
    }
    
    func tapVibeGenerationButton() -> VibeGenerationPage {
        vibeGenerationButton.tap()
        return VibeGenerationPage(app: app)
    }
    
    func tapCustomPromptButton() -> CustomPromptPage {
        customPromptButton.tap()
        return CustomPromptPage(app: app)
    }
    
    func performPullToRefresh() -> MainContentPage {
        let startCoordinate = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.3))
        let endCoordinate = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.7))
        startCoordinate.press(forDuration: 0.1, thenDragTo: endCoordinate)
        return self
    }
    
    func longPressTitle() -> TelemetryDebugPage {
        headerTitle.press(forDuration: 2.5)
        return TelemetryDebugPage(app: app)
    }
    
    // MARK: - Verification Methods
    
    func verifyPoemIsDisplayed() -> Bool {
        return poemTitle.exists && poemAuthor.exists && poemContent.exists
    }
    
    func verifyLoadingState() -> Bool {
        return loadingIndicator.exists
    }
    
    func verifyErrorAlert() -> Bool {
        return errorAlert.exists
    }
    
    func getCurrentPoemTitle() -> String {
        return poemTitle.label
    }
    
    func getCurrentPoemAuthor() -> String {
        return poemAuthor.label
    }
    
    func isFavoriteButtonDisplayed() -> Bool {
        return favoriteButton.exists
    }
    
    func isUnfavoriteButtonDisplayed() -> Bool {
        return unfavoriteButton.exists
    }
    
    func waitForLoadingToComplete(timeout: TimeInterval = 10.0) -> Bool {
        let predicate = NSPredicate(format: "exists == false")
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: loadingIndicator)
        let result = XCTWaiter.wait(for: [expectation], timeout: timeout)
        return result == .completed
    }
}

// MARK: - Favorites Page

class FavoritesPage: BasePage {
    
    // MARK: - UI Elements
    
    var navigationTitle: XCUIElement {
        app.navigationBars["Favorites"]
    }
    
    var backButton: XCUIElement {
        app.navigationBars.buttons["Back"]
    }
    
    var emptyStateMessage: XCUIElement {
        app.staticTexts["No favorites yet"]
    }
    
    var favoritesList: XCUIElement {
        app.tables.firstMatch
    }
    
    // MARK: - Actions
    
    @discardableResult
    func waitForPageToLoad(timeout: TimeInterval = 10.0) -> Bool {
        return navigationTitle.waitForExistence(timeout: timeout)
    }
    
    func isDisplayed() -> Bool {
        return navigationTitle.exists
    }
    
    func tapBackButton() -> MainContentPage {
        backButton.tap()
        return MainContentPage(app: app)
    }
    
    func tapFavoritePoem(at index: Int) -> FavoritePoemDetailPage {
        let cell = favoritesList.cells.element(boundBy: index)
        cell.tap()
        return FavoritePoemDetailPage(app: app)
    }
    
    // MARK: - Verification Methods
    
    func verifyEmptyState() -> Bool {
        return emptyStateMessage.exists
    }
    
    func getFavoriteCount() -> Int {
        return favoritesList.cells.count
    }
    
    func verifyFavoriteExists(withTitle title: String) -> Bool {
        return favoritesList.staticTexts[title].exists
    }
}

// MARK: - Share Sheet Page

class ShareSheetPage: BasePage {
    
    // MARK: - UI Elements
    
    var shareSheet: XCUIElement {
        app.sheets.firstMatch
    }
    
    var cancelButton: XCUIElement {
        app.buttons["Cancel"]
    }
    
    var messageOption: XCUIElement {
        app.buttons["Message"]
    }
    
    var mailOption: XCUIElement {
        app.buttons["Mail"]
    }
    
    var copyOption: XCUIElement {
        app.buttons["Copy"]
    }
    
    // MARK: - Actions
    
    @discardableResult
    func waitForPageToLoad(timeout: TimeInterval = 5.0) -> Bool {
        return shareSheet.waitForExistence(timeout: timeout)
    }
    
    func isDisplayed() -> Bool {
        return shareSheet.exists
    }
    
    func tapCancel() -> MainContentPage {
        cancelButton.tap()
        return MainContentPage(app: app)
    }
    
    func tapCopy() -> MainContentPage {
        copyOption.tap()
        return MainContentPage(app: app)
    }
}

// MARK: - Vibe Generation Page

class VibeGenerationPage: BasePage {
    
    // MARK: - UI Elements
    
    var navigationTitle: XCUIElement {
        app.navigationBars["Vibe Generation"]
    }
    
    var backButton: XCUIElement {
        app.navigationBars.buttons["Back"]
    }
    
    var currentVibeLabel: XCUIElement {
        app.staticTexts.matching(identifier: "current_vibe").firstMatch
    }
    
    var generateButton: XCUIElement {
        app.buttons["Generate Vibe Poem"]
    }
    
    var loadingIndicator: XCUIElement {
        app.activityIndicators.firstMatch
    }
    
    // MARK: - Actions
    
    @discardableResult
    func waitForPageToLoad(timeout: TimeInterval = 10.0) -> Bool {
        return navigationTitle.waitForExistence(timeout: timeout)
    }
    
    func isDisplayed() -> Bool {
        return navigationTitle.exists
    }
    
    func tapBackButton() -> MainContentPage {
        backButton.tap()
        return MainContentPage(app: app)
    }
    
    func tapGenerateButton() -> VibeGenerationPage {
        generateButton.tap()
        return self
    }
    
    // MARK: - Verification Methods
    
    func getCurrentVibe() -> String {
        return currentVibeLabel.label
    }
    
    func verifyLoadingState() -> Bool {
        return loadingIndicator.exists
    }
}

// MARK: - Custom Prompt Page

class CustomPromptPage: BasePage {
    
    // MARK: - UI Elements
    
    var navigationTitle: XCUIElement {
        app.navigationBars["Custom Poem"]
    }
    
    var backButton: XCUIElement {
        app.navigationBars.buttons["Back"]
    }
    
    var promptTextField: XCUIElement {
        app.textFields["Enter your prompt"]
    }
    
    var generateButton: XCUIElement {
        app.buttons["Generate"]
    }
    
    var clearButton: XCUIElement {
        app.buttons["Clear"]
    }
    
    // MARK: - Actions
    
    @discardableResult
    func waitForPageToLoad(timeout: TimeInterval = 10.0) -> Bool {
        return navigationTitle.waitForExistence(timeout: timeout)
    }
    
    func isDisplayed() -> Bool {
        return navigationTitle.exists
    }
    
    func tapBackButton() -> MainContentPage {
        backButton.tap()
        return MainContentPage(app: app)
    }
    
    func enterPrompt(_ text: String) -> CustomPromptPage {
        promptTextField.tap()
        promptTextField.typeText(text)
        return self
    }
    
    func tapGenerateButton() -> MainContentPage {
        generateButton.tap()
        return MainContentPage(app: app)
    }
    
    func tapClearButton() -> CustomPromptPage {
        clearButton.tap()
        return self
    }
    
    // MARK: - Verification Methods
    
    func getCurrentPrompt() -> String {
        return promptTextField.value as? String ?? ""
    }
}

// MARK: - Favorite Poem Detail Page

class FavoritePoemDetailPage: BasePage {
    
    // MARK: - UI Elements
    
    var navigationTitle: XCUIElement {
        app.navigationBars.firstMatch
    }
    
    var backButton: XCUIElement {
        app.navigationBars.buttons["Back"]
    }
    
    var poemTitle: XCUIElement {
        app.staticTexts.matching(identifier: "poem_title").firstMatch
    }
    
    var poemAuthor: XCUIElement {
        app.staticTexts.matching(identifier: "poem_author").firstMatch
    }
    
    var poemContent: XCUIElement {
        app.textViews.matching(identifier: "poem_content").firstMatch
    }
    
    var shareButton: XCUIElement {
        app.buttons["Share"]
    }
    
    var removeFromFavoritesButton: XCUIElement {
        app.buttons["Remove from Favorites"]
    }
    
    // MARK: - Actions
    
    @discardableResult
    func waitForPageToLoad(timeout: TimeInterval = 10.0) -> Bool {
        return navigationTitle.waitForExistence(timeout: timeout)
    }
    
    func isDisplayed() -> Bool {
        return navigationTitle.exists && poemTitle.exists
    }
    
    func tapBackButton() -> FavoritesPage {
        backButton.tap()
        return FavoritesPage(app: app)
    }
    
    func tapShareButton() -> ShareSheetPage {
        shareButton.tap()
        return ShareSheetPage(app: app)
    }
    
    func tapRemoveFromFavoritesButton() -> FavoritePoemDetailPage {
        removeFromFavoritesButton.tap()
        return self
    }
}

// MARK: - Telemetry Debug Page

class TelemetryDebugPage: BasePage {
    
    // MARK: - UI Elements
    
    var navigationTitle: XCUIElement {
        app.navigationBars["Telemetry Debug"]
    }
    
    var closeButton: XCUIElement {
        app.buttons["Close"]
    }
    
    var exportButton: XCUIElement {
        app.buttons["Export"]
    }
    
    var eventCountLabel: XCUIElement {
        app.staticTexts.matching(identifier: "event_count").firstMatch
    }
    
    var eventsList: XCUIElement {
        app.tables.firstMatch
    }
    
    // MARK: - Actions
    
    @discardableResult
    func waitForPageToLoad(timeout: TimeInterval = 10.0) -> Bool {
        return navigationTitle.waitForExistence(timeout: timeout)
    }
    
    func isDisplayed() -> Bool {
        return navigationTitle.exists
    }
    
    func tapCloseButton() -> MainContentPage {
        closeButton.tap()
        return MainContentPage(app: app)
    }
    
    func tapExportButton() -> ShareSheetPage {
        exportButton.tap()
        return ShareSheetPage(app: app)
    }
    
    // MARK: - Verification Methods
    
    func getEventCount() -> String {
        return eventCountLabel.label
    }
    
    func verifyEventExists(withName name: String) -> Bool {
        return eventsList.staticTexts[name].exists
    }
}

// MARK: - Page Factory

class PageFactory {
    let app: XCUIApplication
    
    init(app: XCUIApplication) {
        self.app = app
    }
    
    func mainContentPage() -> MainContentPage {
        return MainContentPage(app: app)
    }
    
    func favoritesPage() -> FavoritesPage {
        return FavoritesPage(app: app)
    }
    
    func shareSheetPage() -> ShareSheetPage {
        return ShareSheetPage(app: app)
    }
    
    func vibeGenerationPage() -> VibeGenerationPage {
        return VibeGenerationPage(app: app)
    }
    
    func customPromptPage() -> CustomPromptPage {
        return CustomPromptPage(app: app)
    }
    
    func favoritePoemDetailPage() -> FavoritePoemDetailPage {
        return FavoritePoemDetailPage(app: app)
    }
    
    func telemetryDebugPage() -> TelemetryDebugPage {
        return TelemetryDebugPage(app: app)
    }
}