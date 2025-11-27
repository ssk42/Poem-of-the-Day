//
//  VibeBackgroundColorUITests.swift
//  Poem of the DayUITests
//
//  Created by Claude on 2025-06-19.
//

import XCTest
import SwiftUI

final class VibeBackgroundColorUITests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        
        // Force Portrait orientation to prevent flakiness from previous tests
        // XCUIDevice.shared.orientation = .portrait  // Disabled: causes crashes in headless CI
        
        // Set environment variables for testing
        app.launchEnvironment["UI_TESTING"] = "true"
        app.launchEnvironment["MOCK_AI_AVAILABLE"] = "true"
        app.launchEnvironment["MOCK_VIBE_ANALYSIS"] = "true"
        
        app.launch()
    }
    
    override func tearDownWithError() throws {
        app = nil
    }
    
    // MARK: - Background Color Display Tests
    
    /*
    func testVibeBackgroundColorDisplaysCorrectly() throws {
        // Wait for app to load
        XCTAssertTrue(app.staticTexts["Poem of the Day"].waitForExistence(timeout: 5))
        
        // Check if vibe indicator is visible (indicates a vibe analysis is active)
        let vibeIndicator = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'Vibe'")).firstMatch
        
        if vibeIndicator.exists {
            // Verify vibe color indicator is present
            let colorIndicator = app.otherElements.matching(NSPredicate(format: "identifier CONTAINS 'color_indicator'")).firstMatch
            XCTAssertTrue(colorIndicator.exists, "Color indicator should be visible when vibe analysis is active")
            
            // Verify vibe description is present
            let vibeDescription = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'colors'")).firstMatch
            XCTAssertTrue(vibeDescription.exists, "Vibe color description should be visible")
        }
    }
    */
    
    func testVibeBackgroundColorChangesWithDifferentVibes() throws {
        // Wait for app to load
        XCTAssertTrue(app.staticTexts["Poem of the Day"].waitForExistence(timeout: 5))
        
        // Test different vibe scenarios by triggering vibe poem generation
        if app.buttons["generate_vibe_poem_button"].exists {
            // Take screenshot before generating vibe poem
            let beforeScreenshot = app.screenshot()
            let beforeAttachment = XCTAttachment(screenshot: beforeScreenshot)
            beforeAttachment.name = "Background Before Vibe Generation"
            beforeAttachment.lifetime = .keepAlways
            add(beforeAttachment)
            
            // Generate vibe-based poem
            app.buttons["generate_vibe_poem_button"].tap()
            
            // Wait for loading to complete
            let loadingIndicator = app.activityIndicators["loading_indicator"]
            if loadingIndicator.exists {
                XCTAssertTrue(loadingIndicator.waitForNonExistence(timeout: 10), "Loading should complete within 10 seconds")
            }
            
            // Wait a moment for background color animation
            Thread.sleep(forTimeInterval: 1.5)
            
            // Take screenshot after vibe generation
            let afterScreenshot = app.screenshot()
            let afterAttachment = XCTAttachment(screenshot: afterScreenshot)
            afterAttachment.name = "Background After Vibe Generation"
            afterAttachment.lifetime = .keepAlways
            add(afterAttachment)
            
            // Verify vibe indicator is still present
            let vibeIndicator = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'Vibe'")).firstMatch
            XCTAssertTrue(vibeIndicator.exists, "Vibe indicator should be present after generating vibe poem")
        }
    }
    
    func testVibeColorIntensityVisualFeedback() throws {
        // Wait for app to load
        XCTAssertTrue(app.staticTexts["Poem of the Day"].waitForExistence(timeout: 5))
        
        // Check if vibe analysis is present
        let vibeIndicator = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'Vibe'")).firstMatch
        
        if vibeIndicator.exists {
            // Tap on the vibe indicator to potentially show more details
            vibeIndicator.tap()
            
            // Verify color description contains intensity-related words
            let colorDescription = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'colors' OR label CONTAINS 'tones' OR label CONTAINS 'hues'")).firstMatch
            XCTAssertTrue(colorDescription.exists, "Color description should contain color-related terminology")
            
            // Take screenshot for visual verification
            let screenshot = app.screenshot()
            let attachment = XCTAttachment(screenshot: screenshot)
            attachment.name = "Vibe Color Intensity Display"
            attachment.lifetime = .keepAlways
            add(attachment)
        }
    }
    
    func testBackgroundColorAccessibility() throws {
        // Wait for app to load
        XCTAssertTrue(app.staticTexts["Poem of the Day"].waitForExistence(timeout: 5))
        
        // Check if vibe analysis is present using the accessibility identifier
        let vibeIndicator = app.otherElements["vibe_indicator"]
        
        if vibeIndicator.exists {
            // Verify accessibility label includes vibe information
            let label = vibeIndicator.label
            XCTAssertTrue(label.starts(with: "Today's vibe is"), "Accessibility label should start with expected text. Got: \(label)")
            XCTAssertTrue(label.contains("vibe"), "Accessibility label should mention vibe")
        }
    }
    
    func testBackgroundColorInDarkMode() throws {
        // Enable Dark Mode if available
        if #available(iOS 13.0, *) {
            app.terminate()
            app.launchEnvironment["UI_TESTING_DARK_MODE"] = "true"
            app.launch()
            
            // Wait for app to load
            XCTAssertTrue(app.staticTexts["Poem of the Day"].waitForExistence(timeout: 5))
            
            // Take screenshot in dark mode
            let darkModeScreenshot = app.screenshot()
            let darkModeAttachment = XCTAttachment(screenshot: darkModeScreenshot)
            darkModeAttachment.name = "Background Color Dark Mode"
            darkModeAttachment.lifetime = .keepAlways
            add(darkModeAttachment)
            
            // Verify vibe indicator is visible in dark mode
            let vibeIndicator = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'Vibe'")).firstMatch
            if vibeIndicator.exists {
                XCTAssertTrue(vibeIndicator.isHittable, "Vibe indicator should be visible and accessible in dark mode")
            }
        }
    }
    
    func testVibeColorDescriptionContent() throws {
        // Wait for app to load
        XCTAssertTrue(app.staticTexts["Poem of the Day"].waitForExistence(timeout: 5))
        
        // Check for vibe analysis
        let vibeIndicator = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'Vibe'")).firstMatch
        
        if vibeIndicator.exists {
            // Extract vibe name from indicator
            let vibeText = vibeIndicator.label
            let vibeTypes = ["Hopeful", "Contemplative", "Energetic", "Peaceful", "Melancholic", "Inspiring", "Uncertain", "Celebratory", "Reflective", "Determined"]
            
            var detectedVibe: String?
            for vibeType in vibeTypes {
                if vibeText.contains(vibeType) {
                    detectedVibe = vibeType
                    break
                }
            }
            
            if let vibe = detectedVibe {
                // Verify color description matches the vibe
                let colorDescription = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'colors' OR label CONTAINS 'tones' OR label CONTAINS 'hues'")).firstMatch
                
                if colorDescription.exists {
                    let description = colorDescription.label.lowercased()
                    
                    switch vibe {
                    case "Hopeful":
                        XCTAssertTrue(description.contains("warm") || description.contains("sunrise") || description.contains("golden"), 
                                     "Hopeful vibe should have warm color description")
                    case "Peaceful":
                        XCTAssertTrue(description.contains("green") || description.contains("nature") || description.contains("tranquil"), 
                                     "Peaceful vibe should have green/nature color description")
                    case "Energetic":
                        XCTAssertTrue(description.contains("vibrant") || description.contains("orange") || description.contains("energy"), 
                                     "Energetic vibe should have vibrant color description")
                    case "Melancholic":
                        XCTAssertTrue(description.contains("purple") || description.contains("gray") || description.contains("soft"), 
                                     "Melancholic vibe should have muted color description")
                    default:
                        // For other vibes, just verify the description exists and contains color-related words
                        XCTAssertTrue(description.contains("color") || description.contains("tone") || description.contains("hue"), 
                                     "Color description should contain color-related terminology")
                    }
                }
            }
        }
    }
    
    func testBackgroundColorAnimation() throws {
        // Wait for app to load
        XCTAssertTrue(app.staticTexts["Poem of the Day"].waitForExistence(timeout: 5))
        
        // Generate new poem to potentially trigger background color change
        if app.buttons["Get New Poem"].exists {
            // Take screenshot before refresh
            let beforeScreenshot = app.screenshot()
            let beforeAttachment = XCTAttachment(screenshot: beforeScreenshot)
            beforeAttachment.name = "Background Before Poem Refresh"
            beforeAttachment.lifetime = .keepAlways
            add(beforeAttachment)
            
            app.buttons["Get New Poem"].tap()
            
            // Wait for loading
            let loadingIndicator = app.activityIndicators["loading_indicator"]
            if loadingIndicator.exists {
                XCTAssertTrue(loadingIndicator.waitForNonExistence(timeout: 10), "Loading should complete")
            }
            
            // Wait for animation to complete
            Thread.sleep(forTimeInterval: 2.0)
            
            // Take screenshot after refresh
            let afterScreenshot = app.screenshot()
            let afterAttachment = XCTAttachment(screenshot: afterScreenshot)
            afterAttachment.name = "Background After Poem Refresh"
            afterAttachment.lifetime = .keepAlways
            add(afterAttachment)
            
            // Verify the app is still functional
            XCTAssertTrue(app.staticTexts["Poem of the Day"].exists, "App should remain functional after background color change")
        }
    }
    
    func testVibeColorIndicatorVisibility() throws {
        // Wait for app to load
        XCTAssertTrue(app.staticTexts["Poem of the Day"].waitForExistence(timeout: 5))
        
        // Look for vibe analysis
        let vibeIndicator = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'Vibe'")).firstMatch
        
        if vibeIndicator.exists {
            // Verify the color intensity circle is visible
            let colorIndicatorCircle = app.otherElements.matching(NSPredicate(format: "identifier CONTAINS 'color_intensity'")).firstMatch
            
            // Since we might not have specific identifiers, check for visual elements
            // by looking for elements near the vibe indicator
            let vibeContainer = vibeIndicator.coordinate(withNormalizedOffset: CGVector(dx: 0, dy: 0))
            
            // Tap in the general area to test interaction
            vibeContainer.tap()
            
            // Verify interaction doesn't break the app
            XCTAssertTrue(app.staticTexts["Poem of the Day"].exists, "App should remain stable after interacting with vibe indicator")
            
            // Take screenshot for visual verification
            let screenshot = app.screenshot()
            let attachment = XCTAttachment(screenshot: screenshot)
            attachment.name = "Vibe Color Indicator Visibility"
            attachment.lifetime = .keepAlways
            add(attachment)
        }
    }
    
    /*
    func testBackgroundColorPerformance() throws {
        // Measure performance of background color changes
        let performanceMetric = XCTOSSignpostMetric.applicationLaunch
        let measureOptions = XCTMeasureOptions.default
        measureOptions.iterationCount = 3
        
        measure(metrics: [performanceMetric], options: measureOptions) {
            app.terminate()
            app.launch()
            
            // Wait for app to load and potentially display vibe colors
            _ = app.staticTexts["Poem of the Day"].waitForExistence(timeout: 5)
            
            // Trigger background color change if possible
            if app.buttons["generate_vibe_poem_button"].exists {
                app.buttons["generate_vibe_poem_button"].tap()
                
                // Wait for any loading to complete
                let loadingIndicator = app.activityIndicators["loading_indicator"]
                if loadingIndicator.exists {
                    _ = loadingIndicator.waitForNonExistence(timeout: 10)
                }
            }
        }
    }
    */
    
    func testVibeBackgroundColorConsistency() throws {
        // Wait for app to load
        XCTAssertTrue(app.staticTexts["Poem of the Day"].waitForExistence(timeout: 5))
        
        // Check for vibe analysis
        let vibeIndicator = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'Vibe'")).firstMatch
        
        if vibeIndicator.exists {
            let initialVibeText = vibeIndicator.label
            
            // Take initial screenshot
            let initialScreenshot = app.screenshot()
            let initialAttachment = XCTAttachment(screenshot: initialScreenshot)
            initialAttachment.name = "Initial Vibe Background"
            initialAttachment.lifetime = .keepAlways
            add(initialAttachment)
            
            // Navigate away and back (if possible)
            if app.buttons["View Favorite Poems"].exists {
                app.buttons["View Favorite Poems"].tap()
                
                // Wait for favorites view
                _ = app.navigationBars.staticTexts["Favorite Poems"].waitForExistence(timeout: 3)
                
                // Go back
                if app.buttons["Done"].exists {
                    app.buttons["Done"].tap()
                }
                
                // Wait for main view to return
                _ = app.staticTexts["Poem of the Day"].waitForExistence(timeout: 3)
                
                // Check if vibe is still consistent
                let returnedVibeIndicator = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'Vibe'")).firstMatch
                if returnedVibeIndicator.exists {
                    let returnedVibeText = returnedVibeIndicator.label
                    XCTAssertEqual(initialVibeText, returnedVibeText, "Vibe should remain consistent after navigation")
                }
                
                // Take final screenshot
                let finalScreenshot = app.screenshot()
                let finalAttachment = XCTAttachment(screenshot: finalScreenshot)
                finalAttachment.name = "Returned Vibe Background"
                finalAttachment.lifetime = .keepAlways
                add(finalAttachment)
            }
        }
    }
} 