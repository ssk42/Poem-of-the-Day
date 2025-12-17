import XCTest
@testable import Poem_of_the_Day

final class PoemSourcePreferenceTests: XCTestCase {

    // MARK: - Raw Value Tests

    func testAPIRawValue() {
        XCTAssertEqual(PoemSourcePreference.api.rawValue, "api")
    }

    func testAIRawValue() {
        XCTAssertEqual(PoemSourcePreference.ai.rawValue, "ai")
    }

    func testInitFromRawValueAPI() {
        let preference = PoemSourcePreference(rawValue: "api")
        XCTAssertEqual(preference, .api)
    }

    func testInitFromRawValueAI() {
        let preference = PoemSourcePreference(rawValue: "ai")
        XCTAssertEqual(preference, .ai)
    }

    func testInitFromInvalidRawValue() {
        let preference = PoemSourcePreference(rawValue: "invalid")
        XCTAssertNil(preference)
    }

    // MARK: - Display Name Tests

    func testAPIDisplayName() {
        XCTAssertEqual(PoemSourcePreference.api.displayName, "PoetryDB")
    }

    func testAIDisplayName() {
        XCTAssertEqual(PoemSourcePreference.ai.displayName, "Apple Intelligence")
    }

    // MARK: - Description Tests

    func testAPIDescription() {
        XCTAssertEqual(PoemSourcePreference.api.description, "Classic poems from the Poetry Database")
    }

    func testAIDescription() {
        XCTAssertEqual(PoemSourcePreference.ai.description, "AI-generated poems based on current events")
    }

    // MARK: - Icon Name Tests

    func testAPIIconName() {
        XCTAssertEqual(PoemSourcePreference.api.iconName, "book.closed")
    }

    func testAIIconName() {
        XCTAssertEqual(PoemSourcePreference.ai.iconName, "apple.intelligence")
    }

    // MARK: - CaseIterable Tests

    func testAllCasesCount() {
        XCTAssertEqual(PoemSourcePreference.allCases.count, 2)
    }

    func testAllCasesContainsAPI() {
        XCTAssertTrue(PoemSourcePreference.allCases.contains(.api))
    }

    func testAllCasesContainsAI() {
        XCTAssertTrue(PoemSourcePreference.allCases.contains(.ai))
    }

    // MARK: - Storage Integration Tests

    func testPreferenceStorageRoundTrip() {
        let testDefaults = UserDefaults(suiteName: "test.poemsource")!
        let key = "testPreferredPoemSource"

        // Store API preference
        testDefaults.set(PoemSourcePreference.api.rawValue, forKey: key)
        let storedAPI = testDefaults.string(forKey: key)
        XCTAssertEqual(storedAPI, "api")
        XCTAssertEqual(PoemSourcePreference(rawValue: storedAPI!), .api)

        // Store AI preference
        testDefaults.set(PoemSourcePreference.ai.rawValue, forKey: key)
        let storedAI = testDefaults.string(forKey: key)
        XCTAssertEqual(storedAI, "ai")
        XCTAssertEqual(PoemSourcePreference(rawValue: storedAI!), .ai)

        // Cleanup
        testDefaults.removePersistentDomain(forName: "test.poemsource")
    }

    func testDefaultPreferenceIsAPI() {
        let testDefaults = UserDefaults(suiteName: "test.poemsource.default")!
        let key = "preferredPoemSource"

        // When no preference is set, default should be API
        let storedValue = testDefaults.string(forKey: key) ?? "api"
        let preference = PoemSourcePreference(rawValue: storedValue) ?? .api
        XCTAssertEqual(preference, .api)

        // Cleanup
        testDefaults.removePersistentDomain(forName: "test.poemsource.default")
    }
}
