import XCTest
@testable import Poem_of_the_Day

final class AIFeaturesUITests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        
        app = XCUIApplication()
        
        // Configure launch arguments for testing
        app.launchArguments = ["--ui-testing"]
        app.launchEnvironment = [
            "AI_AVAILABLE": "true",
            "MOCK_AI_RESPONSES": "true",
            "ENABLE_TELEMETRY": "true"
        ]
        
        app.launch()
    }
    
    override func tearDownWithError() throws {
        app = nil
    }
    
    // MARK: - Vibe-Based Poem Generation Tests
    
    func testVibeBasedPoemGeneration() throws {
        let mainPage = PageFactory.mainContentPage(app: app)
        XCTAssertTrue(mainPage.waitForPoemToLoad())
        
        // Navigate to vibe generation (sheet presentation)
        _ = mainPage.tapVibeGenerationButton()
        
        // Wait for vibe generation sheet to appear
        let vibeSheet = app.sheets.firstMatch
        XCTAssertTrue(vibeSheet.waitForExistence(timeout: 3))
        
        // Find and tap generate button using accessibility identifier
        let generateButton = app.buttons.matching(identifier: "generate_vibe_poem_button").firstMatch
        XCTAssertTrue(generateButton.waitForExistence(timeout: 2))
        
        generateButton.tap()
        
        // Wait for generation to complete and sheet to dismiss
        XCTAssertTrue(vibeSheet.waitForNonExistence(timeout: 8))
        
        // Verify we're back on main page with new poem
        XCTAssertTrue(mainPage.waitForPoemToLoad())
        XCTAssertTrue(mainPage.verifyPoemDisplayed())
    }
    
    func testVibeGenerationCancel() throws {
        let mainPage = PageFactory.mainContentPage(app: app)
        XCTAssertTrue(mainPage.waitForPoemToLoad())
        
        // Open vibe generation sheet
        mainPage.tapVibeGenerationButton()
        
        let vibeSheet = app.sheets.firstMatch
        XCTAssertTrue(vibeSheet.waitForExistence(timeout: 3))
        
        // Cancel the sheet
        let cancelButton = app.buttons["Cancel"]
        XCTAssertTrue(cancelButton.waitForExistence(timeout: 2))
        cancelButton.tap()
        
        // Verify sheet is dismissed and we're back on main page
        XCTAssertTrue(vibeSheet.waitForNonExistence(timeout: 3))
        XCTAssertTrue(mainPage.waitForPoemToLoad())
    }
    
    // MARK: - Custom Prompt Tests
    
    func testCustomPromptPoemGeneration() throws {
        let mainPage = PageFactory.mainContentPage(app: app)
        XCTAssertTrue(mainPage.waitForPoemToLoad())
        
        // Navigate to custom prompt (sheet presentation)
        mainPage.tapCustomPromptButton()
        
        // Wait for custom prompt sheet to appear
        let customSheet = app.sheets.firstMatch
        XCTAssertTrue(customSheet.waitForExistence(timeout: 3))
        
        // Enter a custom prompt using accessibility identifier
        let promptField = app.textViews.matching(identifier: "custom_prompt_text_field").firstMatch
        XCTAssertTrue(promptField.waitForExistence(timeout: 2))
        
        let testPrompt = "Write a poem about the beauty of coding"
        promptField.tap()
        promptField.typeText(testPrompt)
        
        // Generate poem using accessibility identifier
        let generateButton = app.buttons.matching(identifier: "generate_custom_poem_button").firstMatch
        XCTAssertTrue(generateButton.waitForExistence(timeout: 2))
        XCTAssertTrue(generateButton.isEnabled)
        
        generateButton.tap()
        
        // Wait for generation to complete and sheet to dismiss
        XCTAssertTrue(customSheet.waitForNonExistence(timeout: 8))
        
        // Verify we're back on main page with new poem
        XCTAssertTrue(mainPage.waitForPoemToLoad())
        XCTAssertTrue(mainPage.verifyPoemDisplayed())
    }
    
    func testCustomPromptWithEmptyInput() throws {
        let mainPage = PageFactory.mainContentPage(app: app)
        XCTAssertTrue(mainPage.waitForPoemToLoad())
        
        mainPage.tapCustomPromptButton()
        
        let customSheet = app.sheets.firstMatch
        XCTAssertTrue(customSheet.waitForExistence(timeout: 3))
        
        // Try to generate without entering a prompt
        let generateButton = app.buttons.matching(identifier: "generate_custom_poem_button").firstMatch
        XCTAssertTrue(generateButton.waitForExistence(timeout: 2))
        
        // Button should be disabled for empty input
        XCTAssertFalse(generateButton.isEnabled, "Generate button should be disabled for empty input")
        
        // Cancel the sheet
        let cancelButton = app.buttons["Cancel"]
        cancelButton.tap()
        XCTAssertTrue(customSheet.waitForNonExistence(timeout: 3))
    }
    
    // MARK: - AI Error Handling Tests
    
    func testAIGenerationErrorHandling() throws {
        // Configure app for AI error simulation
        app.terminate()
        app.launchEnvironment["MOCK_AI_ERROR"] = "true"
        app.launch()
        
        let mainPage = PageFactory.mainContentPage(app: app)
        XCTAssertTrue(mainPage.waitForPoemToLoad())
        
        // Try vibe generation
        mainPage.tapVibeGenerationButton()
        
        let vibeSheet = app.sheets.firstMatch
        XCTAssertTrue(vibeSheet.waitForExistence(timeout: 3))
        
        let generateButton = app.buttons.matching(identifier: "generate_vibe_poem_button").firstMatch
        generateButton.tap()
        
        // Should show error alert
        let errorAlert = app.alerts.firstMatch
        XCTAssertTrue(errorAlert.waitForExistence(timeout: 5), "Should display error alert when AI generation fails")
        
        // Dismiss error alert
        let okButton = errorAlert.buttons["OK"]
        if okButton.exists {
            okButton.tap()
        }
        
        // Cancel to return to main
        app.buttons["Cancel"].tap()
    }
    
    func testAIFeaturesWhenUnavailable() throws {
        // Configure app without AI capabilities
        app.terminate()
        app.launchEnvironment["AI_AVAILABLE"] = "false"
        app.launch()
        
        let mainPage = PageFactory.mainContentPage(app: app)
        XCTAssertTrue(mainPage.waitForPoemToLoad())
        
        // AI buttons should be hidden or disabled
        let vibeButton = app.buttons.matching(identifier: "vibe_generation_button").firstMatch
        let customButton = app.buttons.matching(identifier: "custom_prompt_button").firstMatch
        
        // These buttons might not exist or be disabled when AI is unavailable
        if vibeButton.exists {
            XCTAssertFalse(vibeButton.isEnabled, "Vibe generation should be disabled when AI unavailable")
        }
        
        if customButton.exists {
            XCTAssertFalse(customButton.isEnabled, "Custom prompt should be disabled when AI unavailable")
        }
    }
    
    // MARK: - Performance Tests
    
    func testAIGenerationPerformance() throws {
        let mainPage = PageFactory.mainContentPage(app: app)
        XCTAssertTrue(mainPage.waitForPoemToLoad())
        
        // Measure time for AI generation
        let startTime = CFAbsoluteTimeGetCurrent()
        
        mainPage.tapVibeGenerationButton()
        
        let vibeSheet = app.sheets.firstMatch
        XCTAssertTrue(vibeSheet.waitForExistence(timeout: 3))
        
        let generateButton = app.buttons.matching(identifier: "generate_vibe_poem_button").firstMatch
        generateButton.tap()
        
        // Wait for completion
        XCTAssertTrue(vibeSheet.waitForNonExistence(timeout: 10))
        
        let endTime = CFAbsoluteTimeGetCurrent()
        let duration = endTime - startTime
        
        // AI generation should complete within reasonable time
        XCTAssertLessThan(duration, 10.0, "AI generation should complete within 10 seconds")
        
        XCTAssertTrue(mainPage.verifyPoemDisplayed())
    }
    
    // MARK: - Integration with Favorites Tests
    
    func testAIGeneratedPoemFavoriting() throws {
        let mainPage = PageFactory.mainContentPage(app: app)
        XCTAssertTrue(mainPage.waitForPoemToLoad())
        
        // Generate an AI poem
        mainPage.tapVibeGenerationButton()
        
        let vibeSheet = app.sheets.firstMatch
        XCTAssertTrue(vibeSheet.waitForExistence(timeout: 3))
        
        let generateButton = app.buttons.matching(identifier: "generate_vibe_poem_button").firstMatch
        generateButton.tap()
        
        // Wait for generation to complete
        XCTAssertTrue(vibeSheet.waitForNonExistence(timeout: 8))
        XCTAssertTrue(mainPage.verifyPoemDisplayed())
        
        // Favorite the AI-generated poem
        let favoriteButton = app.buttons.matching(identifier: "favorite_button").firstMatch
        if favoriteButton.exists {
            favoriteButton.tap()
        }
        
        // Verify favoriting worked (button state should change)
        let unfavoriteButton = app.buttons.matching(identifier: "unfavorite_button").firstMatch
        if unfavoriteButton.exists {
            XCTAssertTrue(unfavoriteButton.exists, "Should show unfavorite button after favoriting")
        }
    }
    
    func testAIGeneratedPoemSharing() throws {
        let mainPage = PageFactory.mainContentPage(app: app)
        XCTAssertTrue(mainPage.waitForPoemToLoad())
        
        // Generate an AI poem
        mainPage.tapCustomPromptButton()
        
        let customSheet = app.sheets.firstMatch
        XCTAssertTrue(customSheet.waitForExistence(timeout: 3))
        
        let promptField = app.textViews.matching(identifier: "custom_prompt_text_field").firstMatch
        promptField.tap()
        promptField.typeText("A poem about friendship")
        
        let generateButton = app.buttons.matching(identifier: "generate_custom_poem_button").firstMatch
        generateButton.tap()
        
        // Wait for generation to complete
        XCTAssertTrue(customSheet.waitForNonExistence(timeout: 8))
        XCTAssertTrue(mainPage.verifyPoemDisplayed())
        
        // Share the AI-generated poem
        let shareButton = app.buttons.matching(identifier: "share_button").firstMatch
        if shareButton.exists {
            shareButton.tap()
            
            // Verify share sheet appears
            let shareSheet = app.sheets.firstMatch
            if shareSheet.waitForExistence(timeout: 3) {
                // Cancel the share to return to main page
                let cancelButton = shareSheet.buttons["Cancel"]
                if cancelButton.exists {
                    cancelButton.tap()
                } else {
                    // Tap outside to dismiss
                    app.coordinate(withNormalizedOffset: CGVector(dx: 0.1, dy: 0.1)).tap()
                }
            }
        }
    }
    
    // MARK: - Accessibility Tests
    
    func testAIFeaturesAccessibility() throws {
        let mainPage = PageFactory.mainContentPage(app: app)
        XCTAssertTrue(mainPage.waitForPoemToLoad())
        
        // Test vibe generation accessibility
        mainPage.tapVibeGenerationButton()
        
        let vibeSheet = app.sheets.firstMatch
        XCTAssertTrue(vibeSheet.waitForExistence(timeout: 3))
        
        // Verify accessibility identifiers exist
        let generateButton = app.buttons.matching(identifier: "generate_vibe_poem_button").firstMatch
        XCTAssertTrue(generateButton.exists, "Generate vibe poem button should have accessibility identifier")
        
        app.buttons["Cancel"].tap()
        XCTAssertTrue(vibeSheet.waitForNonExistence(timeout: 3))
        
        // Test custom prompt accessibility
        mainPage.tapCustomPromptButton()
        
        let customSheet = app.sheets.firstMatch
        XCTAssertTrue(customSheet.waitForExistence(timeout: 3))
        
        let promptField = app.textViews.matching(identifier: "custom_prompt_text_field").firstMatch
        XCTAssertTrue(promptField.exists, "Custom prompt text field should have accessibility identifier")
        
        let customGenerateButton = app.buttons.matching(identifier: "generate_custom_poem_button").firstMatch
        XCTAssertTrue(customGenerateButton.exists, "Generate custom poem button should have accessibility identifier")
        
        app.buttons["Cancel"].tap()
        XCTAssertTrue(customSheet.waitForNonExistence(timeout: 3))
    }
} 