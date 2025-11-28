import XCTest

final class AIFeaturesUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--ui-testing", "-UITESTING", "1"]
        app.launchEnvironment = [
            "AI_AVAILABLE": "true",
            "MOCK_AI_RESPONSES": "true",
            "MOCK_AI_AVAILABLE": "true",
            "UITESTING": "1"
        ]
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    func testVibeGenerationHappyPath() {
        let mainPage = PageFactory.mainContentPage(app: app)
        XCTAssertTrue(mainPage.waitForHeaderToLoad())
        
        // Wait for vibe button to appear
        XCTAssertTrue(mainPage.waitForElementToAppear(mainPage.vibeGenerationButton))
        
        // Open vibe generation
        let vibePage = mainPage.tapVibeGenerationButton()
        XCTAssertTrue(vibePage.waitForPageToLoad())
        
        // Verify vibe details
        XCTAssertFalse(vibePage.getCurrentVibe().isEmpty)
        XCTAssertTrue(vibePage.isGenerateButtonEnabled())
        
        // Generate poem
        let mainPageAfterGen = vibePage.tapGenerateButton()
        
        // Verify back on main page and loading or poem displayed
        XCTAssertTrue(mainPageAfterGen.waitForHeaderToLoad())
    }
    
    func testCustomPromptEmptyDisablesGenerate() {
        let mainPage = PageFactory.mainContentPage(app: app)
        XCTAssertTrue(mainPage.waitForHeaderToLoad())
        
        // Wait for custom prompt button
        XCTAssertTrue(mainPage.waitForElementToAppear(mainPage.customPromptButton))
        
        // Open custom prompt
        let customPage = mainPage.tapCustomPromptButton()
        XCTAssertTrue(customPage.waitForPageToLoad())
        
        // Verify empty prompt disables generate
        XCTAssertTrue(customPage.getPromptText().isEmpty)
        XCTAssertFalse(customPage.isGenerateButtonEnabled())
        
        // Enter prompt
        _ = customPage.enterPrompt("A poem about coding")
        XCTAssertTrue(customPage.isGenerateButtonEnabled())
        
        // Clear prompt
        _ = customPage.clearPrompt()
        XCTAssertFalse(customPage.isGenerateButtonEnabled())
        
        // Close
        _ = customPage.tapCancelButton()
    }
    
    func testAIGenerationErrorShowsAlert() {
        app.terminate()
        app.launchEnvironment["MOCK_AI_ERROR"] = "true"
        app.launch()
        
        let mainPage = PageFactory.mainContentPage(app: app)
        XCTAssertTrue(mainPage.waitForHeaderToLoad())
        
        // Wait for vibe button
        XCTAssertTrue(mainPage.waitForElementToAppear(mainPage.vibeGenerationButton))
        
        // Open vibe generation
        let vibePage = mainPage.tapVibeGenerationButton()
        XCTAssertTrue(vibePage.waitForPageToLoad())
        
        // Generate poem (should fail)
        let mainPageAfterGen = vibePage.tapGenerateButton()
        
        // Verify alert appears
        let alert = app.alerts["Error"]
        XCTAssertTrue(alert.waitForExistence(timeout: 5))
        
        // Dismiss alert
        alert.buttons["OK"].tap()
    }
}
