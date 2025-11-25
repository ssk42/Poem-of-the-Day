import XCTest

final class AIFeaturesUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--ui-testing"]
        app.launchEnvironment = [
            "AI_AVAILABLE": "true",
            "MOCK_AI_RESPONSES": "true"
        ]
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    /*
    func testVibeGenerationHappyPath() {
        let mainPage = PageFactory.mainContentPage(app: app)
        XCTAssertTrue(mainPage.waitForPageToLoad())
        let vibePage = mainPage.tapVibeGenerationButton()
        XCTAssertTrue(vibePage.waitForPageToLoad())
        _ = vibePage.tapGenerateButton()
        XCTAssertTrue(mainPage.waitForPageToLoad())
        XCTAssertTrue(mainPage.verifyPoemIsDisplayed())
    }

    func testCustomPromptEmptyDisablesGenerate() {
        let mainPage = PageFactory.mainContentPage(app: app)
        XCTAssertTrue(mainPage.waitForPageToLoad())
        let customPage = mainPage.tapCustomPromptButton()
        XCTAssertTrue(customPage.waitForPageToLoad())
        XCTAssertFalse(customPage.isGenerateButtonEnabled())
        _ = customPage.tapBackButton()
        XCTAssertTrue(mainPage.waitForPageToLoad())
    }
    */

    /*
    func testAIGenerationErrorShowsAlert() {
        app.terminate()
        app.launchEnvironment["MOCK_AI_ERROR"] = "true"
        app.launch()

        let mainPage = PageFactory.mainContentPage(app: app)
        XCTAssertTrue(mainPage.waitForPageToLoad())
        let vibePage = mainPage.tapVibeGenerationButton()
        XCTAssertTrue(vibePage.waitForPageToLoad())
        _ = vibePage.tapGenerateButton()

        let errorAlert = app.alerts.firstMatch
        XCTAssertTrue(errorAlert.waitForExistence(timeout: 8))
        errorAlert.buttons["OK"].firstMatch.tap()
        XCTAssertTrue(mainPage.waitForPageToLoad())
    }
    */
}
