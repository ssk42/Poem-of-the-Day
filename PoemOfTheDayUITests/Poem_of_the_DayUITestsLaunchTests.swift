//
//  Poem_of_the_DayUITestsLaunchTests.swift
//  Poem of the DayUITests
//
//  Created by Stephen Reitz on 11/14/24.
//

import XCTest

final class Poem_of_the_DayUITestsLaunchTests: XCTestCase {

    override class var runsForEachTargetApplicationUIConfiguration: Bool {
        false  // Disabled for faster CI execution - was causing 4-8x runs
    }

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testLaunch() throws {
        let app = XCUIApplication()
        app.launch()

        // Insert steps here to perform after app launch but before taking a screenshot,
        // such as logging into a test account or navigating somewhere in the app

        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Launch Screen"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
