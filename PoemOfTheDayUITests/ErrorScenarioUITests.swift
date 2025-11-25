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

    /*
    func testServerErrorAlert() {
        app.launchEnvironment = ["SIMULATE_SERVER_ERROR": "true"]
        app.launch()

        let refresh = app.buttons["refresh_button"].firstMatch
        XCTAssertTrue(refresh.waitForExistence(timeout: 5))
        refresh.tap()

        let alert = app.alerts.firstMatch
        XCTAssertTrue(alert.waitForExistence(timeout: 8))
        alert.buttons["OK"].firstMatch.tap()
    }
    */
}
