import XCTest

final class ErrorScenarioUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--ui-testing"]
    }

    override func tearDownWithError() throws {
        app = nil
    }

    func testPullToRefreshError() {
        app.launchArguments.append("-SimulateNetworkError")
        app.launch()
        
        // Initial load should fail and show alert
        let initialAlert = app.alerts.firstMatch
        if initialAlert.waitForExistence(timeout: 10) {
            // Dismiss initial alert
            let okButton = initialAlert.buttons["OK"]
            if okButton.exists {
                okButton.tap()
            }
        }
        
        // Now perform pull to refresh
        // We specifically want to test the swipe gesture as requested by user
        // Use coordinate drag for more control than swipeDown()
        let poemContent = app.scrollViews.firstMatch
        let start = poemContent.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.2))
        let end = poemContent.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.8))
        // Drag slowly to ensure refresh trigger
        start.press(forDuration: 0.1, thenDragTo: end)
        
        // Should show error alert AGAIN
        let errorAlert = app.alerts.firstMatch
        if errorAlert.waitForExistence(timeout: 10) {
            XCTAssertTrue(errorAlert.exists, "Should show error alert for network issues")
            
            // Dismiss alert
            let okButton = errorAlert.buttons["OK"]
            if okButton.exists {
                okButton.tap()
            }
        } else {
             XCTFail("Error alert did not appear after refresh")
        }
    }
}
