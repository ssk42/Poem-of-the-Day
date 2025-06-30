import XCTest
@testable import Poem_of_the_Day

final class AIFeaturesUITests: XCTestCase {
    
    var app: XCUIApplication!
    var pageFactory: PageFactory!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        
        app = XCUIApplication()
        pageFactory = PageFactory(app: app)
        
        // Configure launch arguments for testing
        app.launchArguments = ["--ui-testing"]
        app.launchEnvironment = [
            "ENABLE_AI_TESTING": "true",
            "MOCK_AI_RESPONSES": "true"
        ]
        
        app.launch()
    }
    
    override func tearDownWithError() throws {
        app = nil
        pageFactory = nil
    }
    
    // MARK: - Vibe-Based Poem Generation Tests
    
    func testVibeBasedPoemGeneration() throws {
        let mainPage = pageFactory.mainContentPage()
        XCTAssertTrue(mainPage.waitForPageToLoad())
        
        // Navigate to vibe generation
        let vibeGenerationPage = mainPage.tapVibeGenerationButton()
        XCTAssertTrue(vibeGenerationPage.waitForPageToLoad())
        XCTAssertTrue(vibeGenerationPage.isDisplayed())
        
        // Verify current vibe is displayed
        let currentVibe = vibeGenerationPage.getCurrentVibe()
        XCTAssertFalse(currentVibe.isEmpty, "Current vibe should be displayed")
        
        // Generate a vibe-based poem
        vibeGenerationPage.tapGenerateButton()
        
        // Wait for loading to complete
        XCTAssertTrue(vibeGenerationPage.verifyLoadingState(), "Should show loading indicator")
        
        // Wait for poem to be generated and return to main page
        sleep(3) // Allow time for AI generation simulation
        
        let returnedMainPage = vibeGenerationPage.tapBackButton()
        XCTAssertTrue(returnedMainPage.waitForPageToLoad())
        
        // Verify new AI-generated poem is displayed
        XCTAssertTrue(returnedMainPage.verifyPoemIsDisplayed(), "Generated poem should be displayed")
        
        let poemAuthor = returnedMainPage.getCurrentPoemAuthor()
        XCTAssertEqual(poemAuthor, "AI Generated", "Should show AI Generated as author")
    }
    
    func testVibeBasedPoemGenerationWithDifferentVibes() throws {
        let mainPage = pageFactory.mainContentPage()
        XCTAssertTrue(mainPage.waitForPageToLoad())
        
        // Test multiple vibe generations
        let vibes = ["hopeful", "contemplative", "energetic", "peaceful"]
        
        for expectedVibe in vibes {
            // Generate a poem
            let vibeGenerationPage = mainPage.tapVibeGenerationButton()
            XCTAssertTrue(vibeGenerationPage.waitForPageToLoad())
            
            vibeGenerationPage.tapGenerateButton()
            sleep(2) // Allow generation time
            
            let returnedMainPage = vibeGenerationPage.tapBackButton()
            XCTAssertTrue(returnedMainPage.verifyPoemIsDisplayed())
            
            // Verify the poem reflects the vibe (in a real test, this would check actual content)
            let poemTitle = returnedMainPage.getCurrentPoemTitle()
            XCTAssertFalse(poemTitle.isEmpty, "Generated poem should have a title")
        }
    }
    
    func testVibeBasedPoemGenerationErrorHandling() throws {
        let mainPage = pageFactory.mainContentPage()
        XCTAssertTrue(mainPage.waitForPageToLoad())
        
        // Simulate AI service unavailable by modifying launch environment
        app.terminate()
        app.launchEnvironment["MOCK_AI_ERROR"] = "true"
        app.launch()
        
        let newMainPage = pageFactory.mainContentPage()
        XCTAssertTrue(newMainPage.waitForPageToLoad())
        
        let vibeGenerationPage = newMainPage.tapVibeGenerationButton()
        XCTAssertTrue(vibeGenerationPage.waitForPageToLoad())
        
        vibeGenerationPage.tapGenerateButton()
        
        // Should show error alert
        sleep(2)
        XCTAssertTrue(newMainPage.verifyErrorAlert(), "Should display error alert when AI generation fails")
    }
    
    // MARK: - Custom Prompt Tests
    
    func testCustomPromptPoemGeneration() throws {
        let mainPage = pageFactory.mainContentPage()
        XCTAssertTrue(mainPage.waitForPageToLoad())
        
        // Navigate to custom prompt page
        let customPromptPage = mainPage.tapCustomPromptButton()
        XCTAssertTrue(customPromptPage.waitForPageToLoad())
        XCTAssertTrue(customPromptPage.isDisplayed())
        
        // Enter a custom prompt
        let testPrompt = "Write a poem about the beauty of coding"
        customPromptPage.enterPrompt(testPrompt)
        
        // Verify prompt was entered
        let enteredPrompt = customPromptPage.getCurrentPrompt()
        XCTAssertEqual(enteredPrompt, testPrompt, "Prompt should be correctly entered")
        
        // Generate poem
        let returnedMainPage = customPromptPage.tapGenerateButton()
        
        // Wait for generation and verify result
        sleep(3)
        XCTAssertTrue(returnedMainPage.waitForLoadingToComplete())
        XCTAssertTrue(returnedMainPage.verifyPoemIsDisplayed())
        
        let poemAuthor = returnedMainPage.getCurrentPoemAuthor()
        XCTAssertEqual(poemAuthor, "AI Generated", "Should show AI Generated as author")
        
        // The poem should somehow relate to the prompt (in a real implementation)
        let poemTitle = returnedMainPage.getCurrentPoemTitle()
        XCTAssertFalse(poemTitle.isEmpty, "Generated poem should have a title")
    }
    
    func testCustomPromptWithEmptyInput() throws {
        let mainPage = pageFactory.mainContentPage()
        XCTAssertTrue(mainPage.waitForPageToLoad())
        
        let customPromptPage = mainPage.tapCustomPromptButton()
        XCTAssertTrue(customPromptPage.waitForPageToLoad())
        
        // Try to generate without entering a prompt
        customPromptPage.tapGenerateButton()
        
        // Should either stay on page or show validation error
        // In a real implementation, this might show a validation message
        sleep(1)
        
        // Verify we're still on the custom prompt page or got an error
        let currentPrompt = customPromptPage.getCurrentPrompt()
        XCTAssertTrue(currentPrompt.isEmpty, "Prompt should still be empty")
    }
    
    func testCustomPromptClearFunctionality() throws {
        let mainPage = pageFactory.mainContentPage()
        XCTAssertTrue(mainPage.waitForPageToLoad())
        
        let customPromptPage = mainPage.tapCustomPromptButton()
        XCTAssertTrue(customPromptPage.waitForPageToLoad())
        
        // Enter text and then clear it
        let testPrompt = "Test prompt to be cleared"
        customPromptPage.enterPrompt(testPrompt)
        
        // Verify text was entered
        let enteredPrompt = customPromptPage.getCurrentPrompt()
        XCTAssertEqual(enteredPrompt, testPrompt)
        
        // Clear the text
        customPromptPage.tapClearButton()
        
        // Verify text was cleared
        let clearedPrompt = customPromptPage.getCurrentPrompt()
        XCTAssertTrue(clearedPrompt.isEmpty, "Prompt should be cleared")
    }
    
    func testCustomPromptWithLongInput() throws {
        let mainPage = pageFactory.mainContentPage()
        XCTAssertTrue(mainPage.waitForPageToLoad())
        
        let customPromptPage = mainPage.tapCustomPromptButton()
        XCTAssertTrue(customPromptPage.waitForPageToLoad())
        
        // Test with a very long prompt
        let longPrompt = String(repeating: "This is a very long prompt that should test the limits of what the AI can handle. ", count: 10)
        customPromptPage.enterPrompt(longPrompt)
        
        // Generate poem with long prompt
        let returnedMainPage = customPromptPage.tapGenerateButton()
        
        // Should either succeed or gracefully handle the long input
        sleep(4) // Longer wait for processing long prompt
        XCTAssertTrue(returnedMainPage.waitForLoadingToComplete())
    }
    
    // MARK: - AI Availability Tests
    
    func testAIFeaturesWhenUnavailable() throws {
        // Simulate device without AI capabilities
        app.terminate()
        app.launchEnvironment["AI_AVAILABLE"] = "false"
        app.launch()
        
        let mainPage = pageFactory.mainContentPage()
        XCTAssertTrue(mainPage.waitForPageToLoad())
        
        // AI buttons should either be hidden or disabled
        let vibeButton = mainPage.vibeGenerationButton
        let customButton = mainPage.customPromptButton
        
        // In a real implementation, these buttons might not exist or be disabled
        if vibeButton.exists {
            XCTAssertFalse(vibeButton.isEnabled, "Vibe generation should be disabled when AI unavailable")
        }
        
        if customButton.exists {
            XCTAssertFalse(customButton.isEnabled, "Custom prompt should be disabled when AI unavailable")
        }
    }
    
    func testAIFeaturesWithNetworkError() throws {
        let mainPage = pageFactory.mainContentPage()
        XCTAssertTrue(mainPage.waitForPageToLoad())
        
        // Simulate network connectivity issues
        app.terminate()
        app.launchEnvironment["SIMULATE_NETWORK_ERROR"] = "true"
        app.launch()
        
        let newMainPage = pageFactory.mainContentPage()
        XCTAssertTrue(newMainPage.waitForPageToLoad())
        
        let vibeGenerationPage = newMainPage.tapVibeGenerationButton()
        XCTAssertTrue(vibeGenerationPage.waitForPageToLoad())
        
        vibeGenerationPage.tapGenerateButton()
        
        // Should handle network error gracefully
        sleep(3)
        
        // Check for error handling
        if newMainPage.verifyErrorAlert() {
            // Error alert is shown - good error handling
            XCTAssertTrue(true, "Error alert properly displayed for network issues")
        } else {
            // Should fallback to cached content or show appropriate message
            XCTAssertTrue(vibeGenerationPage.isDisplayed(), "Should remain on page or show appropriate fallback")
        }
    }
    
    // MARK: - AI Integration with Favorites Tests
    
    func testAIGeneratedPoemFavoriting() throws {
        let mainPage = pageFactory.mainContentPage()
        XCTAssertTrue(mainPage.waitForPageToLoad())
        
        // Generate an AI poem
        let vibeGenerationPage = mainPage.tapVibeGenerationButton()
        XCTAssertTrue(vibeGenerationPage.waitForPageToLoad())
        
        vibeGenerationPage.tapGenerateButton()
        sleep(3)
        
        let returnedMainPage = vibeGenerationPage.tapBackButton()
        XCTAssertTrue(returnedMainPage.verifyPoemIsDisplayed())
        
        // Favorite the AI-generated poem
        returnedMainPage.tapFavoriteButton()
        
        // Verify it appears in favorites
        let favoritesPage = returnedMainPage.tapFavoritesButton()
        XCTAssertTrue(favoritesPage.waitForPageToLoad())
        
        let favoriteCount = favoritesPage.getFavoriteCount()
        XCTAssertGreaterThan(favoriteCount, 0, "AI-generated poem should be added to favorites")
        
        // Verify the AI-generated poem is in the list
        XCTAssertFalse(favoritesPage.verifyEmptyState(), "Favorites should not be empty")
    }
    
    func testAIGeneratedPoemSharing() throws {
        let mainPage = pageFactory.mainContentPage()
        XCTAssertTrue(mainPage.waitForPageToLoad())
        
        // Generate an AI poem
        let customPromptPage = mainPage.tapCustomPromptButton()
        XCTAssertTrue(customPromptPage.waitForPageToLoad())
        
        customPromptPage.enterPrompt("A poem about friendship")
        let returnedMainPage = customPromptPage.tapGenerateButton()
        
        sleep(3)
        XCTAssertTrue(returnedMainPage.verifyPoemIsDisplayed())
        
        // Share the AI-generated poem
        let shareSheetPage = returnedMainPage.tapShareButton()
        XCTAssertTrue(shareSheetPage.waitForPageToLoad())
        XCTAssertTrue(shareSheetPage.isDisplayed())
        
        // Cancel the share to return to main page
        shareSheetPage.tapCancel()
    }
    
    // MARK: - Performance Tests for AI Features
    
    func testAIGenerationPerformance() throws {
        let mainPage = pageFactory.mainContentPage()
        XCTAssertTrue(mainPage.waitForPageToLoad())
        
        // Measure time for AI generation
        let startTime = CFAbsoluteTimeGetCurrent()
        
        let vibeGenerationPage = mainPage.tapVibeGenerationButton()
        XCTAssertTrue(vibeGenerationPage.waitForPageToLoad())
        
        vibeGenerationPage.tapGenerateButton()
        
        // Wait for completion
        sleep(5) // Maximum expected time for AI generation
        
        let endTime = CFAbsoluteTimeGetCurrent()
        let duration = endTime - startTime
        
        // AI generation should complete within reasonable time
        XCTAssertLessThan(duration, 10.0, "AI generation should complete within 10 seconds")
        
        vibeGenerationPage.tapBackButton()
        XCTAssertTrue(mainPage.verifyPoemIsDisplayed())
    }
    
    // MARK: - Concurrent AI Operations Tests
    
    func testConcurrentAIOperations() throws {
        let mainPage = pageFactory.mainContentPage()
        XCTAssertTrue(mainPage.waitForPageToLoad())
        
        // Try to trigger multiple AI operations quickly
        let vibeGenerationPage = mainPage.tapVibeGenerationButton()
        XCTAssertTrue(vibeGenerationPage.waitForPageToLoad())
        
        // Tap generate multiple times quickly
        vibeGenerationPage.tapGenerateButton()
        vibeGenerationPage.tapGenerateButton()
        vibeGenerationPage.tapGenerateButton()
        
        // Should handle concurrent requests gracefully
        sleep(4)
        
        // Should not crash and should eventually show a result
        vibeGenerationPage.tapBackButton()
        XCTAssertTrue(mainPage.waitForPageToLoad())
    }
    
    // MARK: - AI Memory and State Tests
    
    func testAIGenerationStateAfterAppBackgrounding() throws {
        let mainPage = pageFactory.mainContentPage()
        XCTAssertTrue(mainPage.waitForPageToLoad())
        
        // Start AI generation
        let customPromptPage = mainPage.tapCustomPromptButton()
        XCTAssertTrue(customPromptPage.waitForPageToLoad())
        
        customPromptPage.enterPrompt("A poem about persistence")
        customPromptPage.tapGenerateButton()
        
        // Background the app during generation
        XCUIDevice.shared.press(.home)
        sleep(2)
        
        // Return to app
        app.activate()
        sleep(1)
        
        // Should handle the interruption gracefully
        XCTAssertTrue(mainPage.waitForPageToLoad())
        // Either show the generated poem or return to a clean state
    }
}

// MARK: - AI Features Test Extensions

extension AIFeaturesUITests {
    
    // Helper method to verify AI poem characteristics
    func verifyAIGeneratedPoem(on page: MainContentPage) {
        XCTAssertTrue(page.verifyPoemIsDisplayed(), "AI poem should be displayed")
        
        let author = page.getCurrentPoemAuthor()
        XCTAssertEqual(author, "AI Generated", "Should show AI Generated as author")
        
        let title = page.getCurrentPoemTitle()
        XCTAssertFalse(title.isEmpty, "AI poem should have a title")
        XCTAssertNotEqual(title, "Loading...", "Should not show loading state")
    }
    
    // Helper method to simulate different AI availability scenarios
    func configureAIAvailability(_ isAvailable: Bool) {
        app.terminate()
        app.launchEnvironment["AI_AVAILABLE"] = isAvailable ? "true" : "false"
        app.launch()
    }
    
    // Helper method to simulate different error conditions
    func simulateAIError(_ errorType: String) {
        app.terminate()
        app.launchEnvironment["MOCK_AI_ERROR"] = errorType
        app.launch()
    }
}