import XCTest

final class NavigationUITests: XCTestCase {
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--ui-testing", "-UITESTING", "1"]
        app.launchEnvironment = ["UITESTING": "1"]
        app.launch()
    }
    
    override func tearDownWithError() throws {
        app = nil
    }
    
    func testSettingsNavigation() {
        let mainPage = PageFactory.mainContentPage(app: app)
        XCTAssertTrue(mainPage.waitForPageToLoad())
        
        // Open menu
        _ = mainPage.tapMenuButton()
        
        // Open settings
        _ = mainPage.tapSettingsButton()
        
        let settingsPage = PageFactory.settingsPage(app: app)
        XCTAssertTrue(settingsPage.waitForPageToLoad())
        XCTAssertTrue(settingsPage.verifyPageDisplayed())
        
        // Verify notification settings button exists
        XCTAssertTrue(settingsPage.notificationSettingsButton.exists)
        
        // Close settings
        _ = settingsPage.tapDoneButton()
        
        // Verify back on main page
        XCTAssertTrue(mainPage.waitForPageToLoad())
    }
    
    func testHistoryNavigation() {
        let mainPage = PageFactory.mainContentPage(app: app)
        XCTAssertTrue(mainPage.waitForPageToLoad())
        
        // Open menu
        _ = mainPage.tapMenuButton()
        
        // Open history
        _ = mainPage.tapHistoryButton()
        
        let historyPage = PageFactory.historyPage(app: app)
        XCTAssertTrue(historyPage.waitForPageToLoad())
        XCTAssertTrue(historyPage.verifyPageDisplayed())
        
        // Verify empty state or list exists
        // Since this is a fresh launch, it might be empty or have the current poem
        // We just verify the page loaded
        
        // Close history
        _ = historyPage.tapDoneButton()
        
        // Verify back on main page
        XCTAssertTrue(mainPage.waitForPageToLoad())
    }
}
