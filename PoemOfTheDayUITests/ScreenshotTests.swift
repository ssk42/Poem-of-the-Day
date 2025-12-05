//
//  ScreenshotTests.swift
//  PoemOfTheDayUITests
//
//  Created for App Store screenshot generation
//

import XCTest

final class ScreenshotTests: XCTestCase {
    
    var app: XCUIApplication!
    let screenshotDir = "/Users/stephenreitz/.gemini/antigravity/brain/09fa190d-2cfd-4bdd-a755-d0b127e6300a/screenshots"
    
    override func setUpWithError() throws {
        continueAfterFailure = true
        app = XCUIApplication()
        app.launchArguments = ["--ui-testing"]
        app.launch()
    }
    
    func testCaptureAllScreenshots() throws {
        // Wait for app to load
        sleep(3)
        
        // 1. Capture Home Screen
        captureScreenshot(named: "01_home_screen")
        
        // 2. Navigate to History
        let menuButton = app.buttons["line.3.horizontal"].firstMatch
        if menuButton.waitForExistence(timeout: 5) {
            menuButton.tap()
            sleep(1)
            
            // Tap History
            let historyButton = app.buttons["History"].firstMatch
            if historyButton.waitForExistence(timeout: 3) {
                historyButton.tap()
                sleep(2)
                captureScreenshot(named: "02_history_screen")
                
                // Go back
                app.navigationBars.buttons.firstMatch.tap()
                sleep(1)
            }
        }
        
        // 3. Navigate to Favorites
        let favoritesButton = app.buttons["heart.fill"].firstMatch
        if favoritesButton.waitForExistence(timeout: 5) {
            favoritesButton.tap()
            sleep(2)
            captureScreenshot(named: "03_favorites_screen")
            
            // Go back
            app.navigationBars.buttons.firstMatch.tap()
            sleep(1)
        }
        
        // 4. Navigate to Settings
        if menuButton.waitForExistence(timeout: 5) {
            menuButton.tap()
            sleep(1)
            
            let settingsButton = app.buttons["Settings"].firstMatch
            if settingsButton.waitForExistence(timeout: 3) {
                settingsButton.tap()
                sleep(2)
                captureScreenshot(named: "04_settings_screen")
            }
        }
    }
    
    private func captureScreenshot(named name: String) {
        let screenshot = XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
        
        // Also save to file system
        let data = screenshot.pngRepresentation
        let url = URL(fileURLWithPath: "\(screenshotDir)/\(name).png")
        try? data.write(to: url)
        
        print("📸 Captured screenshot: \(name)")
    }
}
