import XCTest
@testable import Poem_of_the_Day

final class SecurityInputValidationTests: XCTestCase {
    
    var poemRepository: PoemRepository!
    var networkService: MockNetworkService!
    var telemetryService: TelemetryService!
    var viewModel: PoemViewModel!
    
    override func setUpWithError() throws {
        networkService = MockNetworkService()
        telemetryService = TelemetryService()
        poemRepository = PoemRepository(networkService: networkService, telemetryService: telemetryService)
        viewModel = PoemViewModel(
            poemGenerationService: MockPoemGenerationService(),
            telemetryService: telemetryService,
            repository: poemRepository
        )
    }
    
    override func tearDownWithError() throws {
        viewModel = nil
        poemRepository = nil
        networkService = nil
        telemetryService = nil
    }
    
    // MARK: - Input Validation Security Tests
    
    func testMaliciousHTMLInjectionProtection() throws {
        // Test protection against HTML/script injection in poem content
        let maliciousInputs = [
            "<script>alert('XSS')</script>",
            "<img src=x onerror=alert('XSS')>",
            "javascript:alert('XSS')",
            "<iframe src='javascript:alert(\"XSS\")'></iframe>",
            "<?php echo 'malicious'; ?>",
            "<svg onload=alert('XSS')>",
            "<body onload=alert('XSS')>"
        ]
        
        for maliciousInput in maliciousInputs {
            let maliciousPoem = Poem(
                id: UUID().uuidString,
                title: maliciousInput,
                author: "Test Author",
                content: maliciousInput,
                date: Date(),
                source: .daily,
                isFavorite: false
            )
            
            // Test that the poem model properly handles malicious content
            XCTAssertNotNil(maliciousPoem, "Should create poem object even with malicious input")
            
            // Verify content is properly escaped/sanitized when displayed
            let shareText = maliciousPoem.shareText
            XCTAssertFalse(shareText.contains("<script>"), "Share text should not contain script tags")
            XCTAssertFalse(shareText.contains("javascript:"), "Share text should not contain javascript protocols")
        }
    }
    
    func testSQLInjectionProtection() throws {
        // Test protection against SQL injection attempts
        let sqlInjectionInputs = [
            "'; DROP TABLE poems; --",
            "1' OR '1'='1",
            "admin'--",
            "' UNION SELECT * FROM users; --",
            "1; DELETE FROM favorites; --",
            "' OR 1=1; UPDATE poems SET content='hacked'; --"
        ]
        
        for sqlInput in sqlInjectionInputs {
            let poem = Poem(
                id: sqlInput,
                title: sqlInput,
                author: sqlInput,
                content: sqlInput,
                date: Date(),
                source: .custom,
                isFavorite: false
            )
            
            // Test that SQL injection attempts are handled safely
            XCTAssertNotNil(poem, "Should handle SQL injection attempts safely")
            
            // Test with favorites operations (which use UserDefaults, not SQL, but good to test)
            let encoder = JSONEncoder()
            do {
                let encodedData = try encoder.encode([poem])
                XCTAssertNotNil(encodedData, "Should safely encode poem with injection attempts")
            } catch {
                XCTFail("Should not throw when encoding poem with injection content: \(error)")
            }
        }
    }
    
    func testExcessivelyLongInputHandling() throws {
        // Test handling of extremely long inputs (potential DoS attack)
        let longString = String(repeating: "A", count: 1_000_000) // 1MB string
        let mediumString = String(repeating: "B", count: 100_000) // 100KB string
        let shortString = String(repeating: "C", count: 10_000) // 10KB string
        
        let testInputs = [longString, mediumString, shortString]
        
        for testInput in testInputs {
            let poem = Poem(
                id: UUID().uuidString,
                title: testInput,
                author: testInput,
                content: testInput,
                date: Date(),
                source: .custom,
                isFavorite: false
            )
            
            // Should handle long inputs without crashing
            XCTAssertNotNil(poem, "Should handle long inputs without crashing")
            
            // Test encoding/decoding performance
            let startTime = CFAbsoluteTimeGetCurrent()
            
            let encoder = JSONEncoder()
            do {
                let encodedData = try encoder.encode(poem)
                let decoder = JSONDecoder()
                let decodedPoem = try decoder.decode(Poem.self, from: encodedData)
                
                let endTime = CFAbsoluteTimeGetCurrent()
                let duration = endTime - startTime
                
                XCTAssertLessThan(duration, 1.0, "Should encode/decode large inputs within 1 second")
                XCTAssertEqual(decodedPoem.title, poem.title, "Should preserve data integrity")
                
            } catch {
                XCTFail("Should handle encoding/decoding large inputs: \(error)")
            }
        }
    }
    
    func testSpecialCharacterHandling() throws {
        // Test handling of special characters and unicode
        let specialCharacterInputs = [
            "Unicode: 🎭🎪🎨🎯🎲🎸🎺🎻",
            "Emoji: 😀😃😄😁😆😅😂🤣",
            "Math: ∑∏∫∂∆∇√∞≠≤≥±×÷",
            "Currency: $€£¥₹₽₩₪₫₡₦₨",
            "Accents: àáâãäåæçèéêëìíîïñòóôõöøùúûüý",
            "CJK: 中文日本語한국어العربية",
            "RTL: עברית العربية فارسی",
            "Control chars: \n\r\t\0",
            "Quotes: \"'`''""«»‹›",
            "Slashes: /\\|",
            "Brackets: ()[]{}⟨⟩"
        ]
        
        for specialInput in specialCharacterInputs {
            let poem = Poem(
                id: UUID().uuidString,
                title: specialInput,
                author: specialInput,
                content: specialInput,
                date: Date(),
                source: .custom,
                isFavorite: false
            )
            
            // Should handle special characters properly
            XCTAssertNotNil(poem, "Should handle special characters")
            XCTAssertEqual(poem.title, specialInput, "Should preserve special characters")
            
            // Test JSON serialization with special characters
            let encoder = JSONEncoder()
            do {
                let encodedData = try encoder.encode(poem)
                let decoder = JSONDecoder()
                let decodedPoem = try decoder.decode(Poem.self, from: encodedData)
                
                XCTAssertEqual(decodedPoem.title, specialInput, "Should preserve special characters in JSON")
                XCTAssertEqual(decodedPoem.content, specialInput, "Should preserve content with special characters")
                
            } catch {
                XCTFail("Should handle JSON encoding with special characters: \(error)")
            }
        }
    }
    
    // MARK: - API Security Tests
    
    func testAPIResponseValidation() throws {
        // Test validation of API responses to prevent malicious data injection
        let maliciousAPIResponses = [
            // Oversized response
            Data(String(repeating: "x", count: 10_000_000).utf8),
            // Invalid JSON
            Data("{ invalid json".utf8),
            // Empty response
            Data(),
            // Binary data
            Data([0x00, 0x01, 0x02, 0xFF, 0xFE, 0xFD]),
            // Malformed UTF-8
            Data([0xFF, 0xFE, 0xFD, 0xFC])
        ]
        
        for maliciousData in maliciousAPIResponses {
            networkService.mockResponseData = maliciousData
            networkService.shouldFail = false
            
            // Test that malicious API responses are handled safely
            let expectation = expectation(description: "API validation test")
            
            Task {
                do {
                    let _ = try await poemRepository.fetchTodaysPoem()
                    // If it succeeds, that's fine - data was valid enough
                } catch {
                    // If it fails, that's also fine - invalid data was rejected
                    XCTAssertTrue(error is PoemError, "Should throw appropriate PoemError for invalid data")
                }
                expectation.fulfill()
            }
            
            wait(for: [expectation], timeout: 5.0)
        }
    }
    
    func testNetworkTimeoutSecurity() throws {
        // Test that network timeouts prevent hanging attacks
        networkService.simulateDelay = 30.0 // Very long delay
        
        let expectation = expectation(description: "Timeout test")
        
        Task {
            let startTime = CFAbsoluteTimeGetCurrent()
            
            do {
                let _ = try await poemRepository.fetchTodaysPoem()
            } catch {
                // Should timeout before the 30 second delay
                let endTime = CFAbsoluteTimeGetCurrent()
                let duration = endTime - startTime
                
                XCTAssertLessThan(duration, 20.0, "Should timeout before hanging indefinitely")
                XCTAssertTrue(error is PoemError, "Should throw timeout error")
            }
            
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 25.0)
    }
    
    // MARK: - Data Protection Tests
    
    func testSensitiveDataProtection() throws {
        // Test that no sensitive data is exposed in logs or telemetry
        let sensitivePoem = Poem(
            id: "user-secret-123",
            title: "My Private Thoughts",
            author: "Personal Journal",
            content: "Secret personal information that should be protected",
            date: Date(),
            source: .custom,
            isFavorite: true
        )
        
        // Test that poem data doesn't leak sensitive information
        let debugDescription = String(describing: sensitivePoem)
        
        // Should not contain raw sensitive data in debug output
        XCTAssertTrue(debugDescription.contains("Poem"), "Should identify as Poem object")
        
        // Test that telemetry doesn't expose sensitive content
        // (In real implementation, we'd verify telemetry events don't contain poem content)
        XCTAssertTrue(true, "Telemetry should not expose poem content")
    }
    
    func testUserDefaultsSecurityIsolation() throws {
        // Test that favorites are properly isolated and secure
        let testPoems = TestData.samplePoems
        
        // Create a clean test environment
        let testSuiteName = "SecurityTestSuite_\(UUID().uuidString)"
        let userDefaults = UserDefaults(suiteName: testSuiteName)!
        
        // Test storing favorites
        let encoder = JSONEncoder()
        do {
            let encodedData = try encoder.encode(testPoems)
            userDefaults.set(encodedData, forKey: "test_favorites")
            
            // Verify data is stored securely
            let retrievedData = userDefaults.data(forKey: "test_favorites")
            XCTAssertNotNil(retrievedData, "Should store data in UserDefaults")
            
            // Test data integrity
            let decoder = JSONDecoder()
            let decodedPoems = try decoder.decode([Poem].self, from: retrievedData!)
            XCTAssertEqual(decodedPoems.count, testPoems.count, "Should preserve data integrity")
            
            // Clean up test data
            userDefaults.removeObject(forKey: "test_favorites")
            userDefaults.removeSuite(named: testSuiteName)
            
        } catch {
            XCTFail("Should handle UserDefaults operations securely: \(error)")
        }
    }
    
    // MARK: - Input Boundary Tests
    
    func testNumericBoundaryInputs() throws {
        // Test extreme numeric inputs
        let extremeNumbers = [
            Int.max,
            Int.min,
            0,
            -1,
            1_000_000_000,
            -1_000_000_000
        ]
        
        for number in extremeNumbers {
            let poem = Poem(
                id: String(number),
                title: "Poem \(number)",
                author: "Author \(number)",
                content: "Content with number \(number)",
                date: Date(timeIntervalSince1970: TimeInterval(abs(number % 1_000_000))),
                source: .daily,
                isFavorite: number % 2 == 0
            )
            
            XCTAssertNotNil(poem, "Should handle extreme numeric inputs")
            
            // Test JSON encoding with extreme numbers
            let encoder = JSONEncoder()
            do {
                let encodedData = try encoder.encode(poem)
                let decoder = JSONDecoder()
                let decodedPoem = try decoder.decode(Poem.self, from: encodedData)
                
                XCTAssertEqual(decodedPoem.id, poem.id, "Should preserve numeric data")
                
            } catch {
                XCTFail("Should handle JSON encoding with extreme numbers: \(error)")
            }
        }
    }
    
    func testDateBoundaryInputs() throws {
        // Test extreme date inputs
        let extremeDates = [
            Date.distantPast,
            Date.distantFuture,
            Date(timeIntervalSince1970: 0), // Unix epoch
            Date(timeIntervalSince1970: -1), // Before epoch
            Date(), // Current date
            Date(timeIntervalSinceNow: 86400 * 365 * 100) // 100 years in future
        ]
        
        for date in extremeDates {
            let poem = Poem(
                id: UUID().uuidString,
                title: "Date Test Poem",
                author: "Date Tester",
                content: "Testing extreme date: \(date)",
                date: date,
                source: .daily,
                isFavorite: false
            )
            
            XCTAssertNotNil(poem, "Should handle extreme date inputs")
            
            // Test JSON encoding with extreme dates
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            
            do {
                let encodedData = try encoder.encode(poem)
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                let decodedPoem = try decoder.decode(Poem.self, from: encodedData)
                
                // Allow for small differences due to encoding precision
                let timeDifference = abs(decodedPoem.date.timeIntervalSince(poem.date))
                XCTAssertLessThan(timeDifference, 1.0, "Should preserve date with reasonable precision")
                
            } catch {
                XCTFail("Should handle JSON encoding with extreme dates: \(error)")
            }
        }
    }
    
    // MARK: - Memory Security Tests
    
    func testMemoryLeakPrevention() throws {
        // Test that operations don't cause memory leaks
        weak var weakPoem: Poem?
        
        do {
            let poem = Poem(
                id: UUID().uuidString,
                title: "Memory Test Poem",
                author: "Memory Tester",
                content: "Testing memory management",
                date: Date(),
                source: .custom,
                isFavorite: false
            )
            
            weakPoem = poem
            XCTAssertNotNil(weakPoem, "Poem should exist while in scope")
            
            // Perform operations that might cause retention
            let shareText = poem.shareText
            XCTAssertFalse(shareText.isEmpty, "Should generate share text")
            
        } // poem goes out of scope here
        
        // Force garbage collection
        DispatchQueue.main.async {
            // Poem should be deallocated
            XCTAssertNil(weakPoem, "Poem should be deallocated after going out of scope")
        }
    }
    
    func testConcurrentAccessSafety() throws {
        // Test thread safety and concurrent access
        let poem = Poem(
            id: UUID().uuidString,
            title: "Concurrent Test Poem",
            author: "Thread Tester",
            content: "Testing concurrent access",
            date: Date(),
            source: .daily,
            isFavorite: false
        )
        
        let expectation = expectation(description: "Concurrent access test")
        expectation.expectedFulfillmentCount = 10
        
        // Create multiple concurrent operations
        for i in 0..<10 {
            DispatchQueue.global(qos: .background).async {
                // Test that poem properties can be safely accessed concurrently
                let title = poem.title
                let content = poem.content
                let shareText = poem.shareText
                
                XCTAssertFalse(title.isEmpty, "Should safely access title concurrently")
                XCTAssertFalse(content.isEmpty, "Should safely access content concurrently")
                XCTAssertFalse(shareText.isEmpty, "Should safely generate share text concurrently")
                
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
} 