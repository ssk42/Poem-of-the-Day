import XCTest
@testable import Poem_of_the_Day

final class PoemTests: XCTestCase {
    
    func testPoemInitialization() {
        let poem = Poem(
            title: "Test Poem",
            lines: ["Line 1", "Line 2"],
            author: "Test Author",
            vibe: .hopeful
        )
        
        XCTAssertEqual(poem.title, "Test Poem")
        XCTAssertEqual(poem.content, "Line 1\nLine 2")
        XCTAssertEqual(poem.author, "Test Author")
        XCTAssertEqual(poem.vibe, .hopeful)
        XCTAssertNotNil(poem.id)
    }
    
    func testPoemWithoutAuthor() {
        let poem = Poem(
            title: "Anonymous Poem",
            lines: ["Line 1"],
            author: nil
        )
        
        XCTAssertEqual(poem.title, "Anonymous Poem")
        XCTAssertNil(poem.author)
        XCTAssertNil(poem.vibe)
    }
    
    func testPoemContent() {
        let poem = TestData.samplePoem
        
        XCTAssertFalse(poem.content.isEmpty)
        XCTAssertTrue(poem.content.contains("Two roads diverged"))
    }
    
    func testPoemShareText() {
        let poem = Poem(
            title: "Test",
            lines: ["Line 1", "Line 2"],
            author: "Author"
        )
        
        let shareText = poem.shareText
        XCTAssertTrue(shareText.contains("Test"))
        XCTAssertTrue(shareText.contains("Line 1"))
        XCTAssertTrue(shareText.contains("Author"))
    }
    
    func testPoemEquality() {
        let poem1 = Poem(title: "Same", lines: ["Line"], author: "Author")
        let poem2 = Poem(title: "Same", lines: ["Line"], author: "Author")
        
        // Different IDs, so should not be equal
        XCTAssertNotEqual(poem1.id, poem2.id)
    }
    
    func testPoemCoding() throws {
        let originalPoem = TestData.samplePoem
        
        let encoded = try JSONEncoder().encode(originalPoem)
        let decoded = try JSONDecoder().decode(Poem.self, from: encoded)
        
        XCTAssertEqual(decoded.title, originalPoem.title)
        XCTAssertEqual(decoded.content, originalPoem.content)
        XCTAssertEqual(decoded.author, originalPoem.author)
        XCTAssertEqual(decoded.id, originalPoem.id)
    }
    
    func testPoemResponseConversion() {
        let poemResponse = PoemResponse(
            title: "Response Poem",
            lines: ["Line 1", "Line 2", "Line 3"],
            author: "Response Author"
        )
        
        let poem = poemResponse.toPoem()
        
        XCTAssertEqual(poem.title, "Response Poem")
        XCTAssertEqual(poem.content, "Line 1\nLine 2\nLine 3")
        XCTAssertEqual(poem.author, "Response Author")
    }
    
    func testEmptyAuthorHandling() {
        let poem = Poem(
            title: "Test",
            lines: ["Line"],
            author: ""  // Empty string should be converted to nil
        )
        
        XCTAssertNil(poem.author)
    }
} 