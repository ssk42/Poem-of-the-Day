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
}

// MARK: - Base Page

class BasePage {
    let app: XCUIApplication
    
    init(app: XCUIApplication) {
        self.app = app
    }
    
    func waitForElementToAppear(_ element: XCUIElement, timeout: TimeInterval = 5) -> Bool {
        let predicate = NSPredicate(format: "exists == true")
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: element)
        let result = XCTWaiter.wait(for: [expectation], timeout: timeout)
        return result == .completed
    }
    
    func waitForElementToDisappear(_ element: XCUIElement, timeout: TimeInterval = 5) -> Bool {
        let predicate = NSPredicate(format: "exists == false")
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: element)
        let result = XCTWaiter.wait(for: [expectation], timeout: timeout)
        return result == .completed
    }
}

// MARK: - Main Content Page

class MainContentPage: BasePage {
    
    private let poemTitle: XCUIElement
    private let poemContent: XCUIElement
    private let authorLabel: XCUIElement
    private let favoriteButton: XCUIElement
    private let shareButton: XCUIElement
    private let refreshButton: XCUIElement
    private let favoritesButton: XCUIElement
    private let vibeGenerationButton: XCUIElement
    private let customPromptButton: XCUIElement
    private let loadingIndicator: XCUIElement
    
    override init(app: XCUIApplication) {
        self.poemTitle = app.staticTexts.matching(identifier: "poem_title").firstMatch
        self.poemContent = app.staticTexts.matching(identifier: "poem_content").firstMatch
        self.authorLabel = app.staticTexts.matching(identifier: "poem_author").firstMatch
        self.favoriteButton = app.buttons.matching(identifier: "favorite_button").firstMatch
        self.shareButton = app.buttons.matching(identifier: "share_button").firstMatch
        self.refreshButton = app.buttons.matching(identifier: "refresh_button").firstMatch
        self.favoritesButton = app.buttons.matching(identifier: "favorites_button").firstMatch
        self.vibeGenerationButton = app.buttons["Vibe Poem"]
        self.customPromptButton = app.buttons["Custom"]
        self.loadingIndicator = app.activityIndicators.firstMatch
        
        super.init(app: app)
    }
    
    // MARK: - Actions
    
    func waitForPoemToLoad() -> Bool {
        return waitForElementToAppear(poemTitle)
    }
    
    func tapRefreshButton() -> MainContentPage {
        refreshButton.tap()
        return self
    }
    
    func tapFavoriteButton() -> MainContentPage {
        favoriteButton.tap()
        return self
    }
    
    func tapShareButton() {
        shareButton.tap()
    }
    
    func tapFavoritesButton() -> FavoritesPage {
        favoritesButton.tap()
        return PageFactory.favoritesPage(app: app)
    }
    
    func tapVibeGenerationButton() -> VibeGenerationPage {
        vibeGenerationButton.tap()
        return PageFactory.vibeGenerationPage(app: app)
    }
    
    func tapCustomPromptButton() -> CustomPromptPage {
        customPromptButton.tap()
        return PageFactory.customPromptPage(app: app)
    }
    
    // MARK: - Getters
    
    func getPoemTitle() -> String {
        return poemTitle.label
    }
    
    func getPoemContent() -> String {
        return poemContent.label
    }
    
    func getAuthorName() -> String {
        return authorLabel.label
    }
    
    func isFavoriteButtonSelected() -> Bool {
        return favoriteButton.isSelected
    }
    
    func isLoadingIndicatorVisible() -> Bool {
        return loadingIndicator.exists && loadingIndicator.isHittable
    }
    
    // MARK: - Verifications
    
    func verifyPoemDisplayed() -> Bool {
        return poemTitle.exists && poemContent.exists && authorLabel.exists
    }
    
    func verifyNavigationButtonsDisplayed() -> Bool {
        return vibeGenerationButton.exists && customPromptButton.exists && favoritesButton.exists
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
        app.staticTexts.matching(identifier: "current_vibe_label").firstMatch
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
        app.navigationBars["Favorites"]
    }
    
    var backButton: XCUIElement {
        app.navigationBars.buttons["Back"]
    }
    
    var favoritesTable: XCUIElement {
        app.tables.firstMatch
    }
    
    var emptyStateMessage: XCUIElement {
        app.staticTexts["No favorite poems yet"]
    }
    
    // MARK: - Actions
    
    func waitForPageToLoad() -> Bool {
        return waitForElementToAppear(navigationTitle)
    }
    
    func tapBackButton() -> MainContentPage {
        backButton.tap()
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
}