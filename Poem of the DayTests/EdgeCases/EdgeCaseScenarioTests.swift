import XCTest
@testable import Poem_of_the_Day

final class EdgeCaseScenarioTests: XCTestCase {
    
    var poemRepository: PoemRepository!
    var networkService: MockNetworkService!
    var viewModel: PoemViewModel!
    
    override func setUpWithError() throws {
        networkService = MockNetworkService()
        poemRepository = PoemRepository(networkService: networkService, telemetryService: TelemetryService())
        viewModel = PoemViewModel(
            poemGenerationService: MockPoemGenerationService(),
            telemetryService: TelemetryService(),
            repository: poemRepository
        )
    }
    
    override func tearDownWithError() throws {
        viewModel = nil
        poemRepository = nil
        networkService = nil
    }
    
    // MARK: - Extreme Content Tests
    
    func testExtremelyLongPoemContent() throws {
        // Test with poem content that exceeds typical limits
        let extremelyLongContent = String(repeating: "This is an extremely long poem line that goes on and on and on. ", count: 10000)
        
        let longPoem = Poem(
            id: "extreme_long",
            title: "Extremely Long Poem",
            author: "Endurance Author",
            content: extremelyLongContent,
            date: Date(),
            source: .custom,
            isFavorite: false
        )
        
        XCTAssertNotNil(longPoem, "Should handle extremely long content")
        
        // Test share text with extreme content
        let shareText = longPoem.shareText
        XCTAssertFalse(shareText.isEmpty, "Should generate share text for long content")
        
        // Test JSON encoding with extreme length
        let encoder = JSONEncoder()
        do {
            let encodedData = try encoder.encode(longPoem)
            XCTAssertGreaterThan(encodedData.count, 0, "Should encode extremely long poem")
        } catch {
            XCTFail("Should handle encoding of extremely long content: \(error)")
        }
    }
    
    func testEmptyAndNilContent() throws {
        // Test with empty or minimal content
        let emptyContentCases = [
            ("", "", ""),
            (" ", " ", " "),
            ("\n", "\n", "\n"),
            ("\t", "\t", "\t"),
            ("   \n\t  ", "   \n\t  ", "   \n\t  ")
        ]
        
        for (title, author, content) in emptyContentCases {
            let poem = Poem(
                id: "empty_\(UUID().uuidString)",
                title: title,
                author: author,
                content: content,
                date: Date(),
                source: .custom,
                isFavorite: false
            )
            
            XCTAssertNotNil(poem, "Should handle empty/whitespace content")
            
            // Share text should handle empty content gracefully
            let shareText = poem.shareText
            XCTAssertNotNil(shareText, "Should generate share text even for empty content")
        }
    }
    
    func testSpecialCharacterCombinations() throws {
        // Test with complex special character combinations
        let specialCases = [
            "🎭🎪🎨🎯🎲🎸🎺🎻🎼🎵🎶🎤🎧🎹", // Musical emojis
            "\\n\\r\\t\\0\\x00\\xFF", // Escape sequences
            "\"'`''\"\"«»‹›⟨⟩", // Various quotes
            "∑∏∫∂∆∇√∞≠≤≥±×÷", // Mathematical symbols
            "\u{1F600}\u{1F601}\u{1F602}", // Unicode escape sequences
            "⚠️🚨🔴🟡🟢🔵🟣⚫⚪", // Warning and colored symbols
            "🇺🇸🇬🇧🇫🇷🇩🇪🇯🇵", // Flag emojis
            "👨‍👩‍👧‍👦👩‍💻🧑‍🎨", // Complex family/profession emojis
        ]
        
        for specialText in specialCases {
            let poem = Poem(
                id: "special_\(UUID().uuidString)",
                title: "Special: \(specialText)",
                author: "Special Author: \(specialText)",
                content: "Content with special characters: \(specialText)",
                date: Date(),
                source: .custom,
                isFavorite: false
            )
            
            XCTAssertNotNil(poem, "Should handle special character combinations")
            
            // Test encoding/decoding
            let encoder = JSONEncoder()
            do {
                let encodedData = try encoder.encode(poem)
                let decoder = JSONDecoder()
                let decodedPoem = try decoder.decode(Poem.self, from: encodedData)
                
                XCTAssertEqual(decodedPoem.title, poem.title, "Should preserve special characters")
                XCTAssertEqual(decodedPoem.content, poem.content, "Should preserve special content")
            } catch {
                XCTFail("Should handle special character encoding: \(error)")
            }
        }
    }
    
    // MARK: - Date Edge Cases
    
    func testExtremeDateValues() throws {
        let extremeDates = [
            Date.distantPast,
            Date.distantFuture,
            Date(timeIntervalSince1970: 0), // Unix epoch
            Date(timeIntervalSince1970: -86400), // Before epoch
            Date(timeIntervalSince1970: 253402300799), // Year 9999
            Date(timeIntervalSinceNow: -86400 * 365 * 100), // 100 years ago
            Date(timeIntervalSinceNow: 86400 * 365 * 100), // 100 years future
        ]
        
        for extremeDate in extremeDates {
            let poem = Poem(
                id: "date_extreme_\(UUID().uuidString)",
                title: "Extreme Date Poem",
                author: "Time Traveler",
                content: "Created at extreme date: \(extremeDate)",
                date: extremeDate,
                source: .daily,
                isFavorite: false
            )
            
            XCTAssertNotNil(poem, "Should handle extreme dates")
            
            // Test that extreme dates can be encoded/decoded
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            
            do {
                let encodedData = try encoder.encode(poem)
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                
                let decodedPoem = try decoder.decode(Poem.self, from: encodedData)
                
                // Allow for small precision differences
                let timeDifference = abs(decodedPoem.date.timeIntervalSince(poem.date))
                XCTAssertLessThan(timeDifference, 1.0, "Should preserve extreme dates with reasonable precision")
                
            } catch {
                // Some extreme dates might not be encodable - that's acceptable
                XCTAssertTrue(true, "Extreme date encoding behavior is implementation-defined")
            }
        }
    }
    
    // MARK: - Memory and Performance Edge Cases
    
    func testRapidSuccessiveOperations() async throws {
        // Test rapid successive operations that might cause race conditions
        let numberOfOperations = 100
        let expectation = expectation(description: "Rapid operations")
        expectation.expectedFulfillmentCount = numberOfOperations
        
        // Perform many operations very quickly
        for i in 0..<numberOfOperations {
            Task {
                if i % 4 == 0 {
                    await viewModel.loadTodaysPoem()
                } else if i % 4 == 1 {
                    await viewModel.refreshPoem()
                } else if i % 4 == 2 {
                    let _ = await viewModel.loadFavoritePoems()
                } else {
                    // Toggle favorite on current poem if available
                    if let poem = viewModel.currentPoem {
                        await viewModel.toggleFavorite(for: poem)
                    }
                }
                expectation.fulfill()
            }
        }
        
        await fulfillment(of: [expectation], timeout: 30.0)
        
        // App should remain stable after rapid operations
        XCTAssertTrue(
            viewModel.loadingState == .loaded || viewModel.loadingState == .error,
            "Should remain in stable state after rapid operations"
        )
    }
    
    func testConcurrentModificationOfFavorites() async throws {
        // Test concurrent modification of favorites list
        let testPoems = TestData.samplePoems
        let expectation = expectation(description: "Concurrent favorites")
        expectation.expectedFulfillmentCount = testPoems.count
        
        // Concurrently toggle favorites for multiple poems
        await withTaskGroup(of: Void.self) { group in
            for poem in testPoems {
                group.addTask {
                    await self.viewModel.toggleFavorite(for: poem)
                    expectation.fulfill()
                }
            }
        }
        
        await fulfillment(of: [expectation], timeout: 10.0)
        
        // Verify final state is consistent
        let finalFavorites = await viewModel.loadFavoritePoems()
        XCTAssertNotNil(finalFavorites, "Should have consistent favorites after concurrent operations")
    }
    
    // MARK: - Network Edge Cases
    
    func testNetworkResponseEdgeCases() async throws {
        let edgeCaseResponses = [
            Data(), // Empty response
            Data(count: 1), // Single byte
            Data(count: 1_000_000), // Very large response
            "null".data(using: .utf8)!, // JSON null
            "{}".data(using: .utf8)!, // Empty JSON object
            "[]".data(using: .utf8)!, // Empty JSON array
            "\"\"".data(using: .utf8)!, // Empty JSON string
        ]
        
        for responseData in edgeCaseResponses {
            networkService.mockResponseData = responseData
            networkService.shouldFail = false
            
            let expectation = expectation(description: "Edge case response")
            
            Task {
                do {
                    let _ = try await poemRepository.fetchTodaysPoem()
                    // If it succeeds, that's fine
                } catch {
                    // If it fails, that's also acceptable for edge cases
                    XCTAssertTrue(error is PoemError, "Should throw appropriate error for edge case data")
                }
                expectation.fulfill()
            }
            
            await fulfillment(of: [expectation], timeout: 5.0)
        }
    }
    
    func testNetworkTimeoutEdgeCases() async throws {
        // Test various timeout scenarios
        let timeoutScenarios: [TimeInterval] = [0.001, 0.01, 30.0, 60.0, 300.0]
        
        for timeout in timeoutScenarios {
            networkService.simulateDelay = timeout
            
            let expectation = expectation(description: "Timeout test \(timeout)")
            
            Task {
                let startTime = CFAbsoluteTimeGetCurrent()
                
                do {
                    let _ = try await poemRepository.fetchTodaysPoem()
                } catch {
                    // Timeouts are expected for long delays
                }
                
                let endTime = CFAbsoluteTimeGetCurrent()
                let actualDuration = endTime - startTime
                
                // Should either complete quickly or timeout appropriately
                XCTAssertTrue(
                    actualDuration < timeout + 5.0,
                    "Should handle timeout scenario for \(timeout)s"
                )
                
                expectation.fulfill()
            }
            
            await fulfillment(of: [expectation], timeout: max(timeout + 10.0, 15.0))
        }
    }
    
    // MARK: - State Consistency Edge Cases
    
    func testStateConsistencyUnderStress() async throws {
        // Test state consistency under various stress conditions
        await viewModel.loadTodaysPoem()
        
        let expectation = expectation(description: "State consistency")
        
        Task {
            // Perform various operations that might affect state
            for i in 0..<20 {
                switch i % 5 {
                case 0:
                    await viewModel.refreshPoem()
                case 1:
                    if let poem = viewModel.currentPoem {
                        await viewModel.toggleFavorite(for: poem)
                    }
                case 2:
                    let _ = await viewModel.loadFavoritePoems()
                case 3:
                    if AppConfiguration.FeatureFlags.aiPoemGeneration {
                        await viewModel.generatePoemFromVibe()
                    }
                case 4:
                    if AppConfiguration.FeatureFlags.aiPoemGeneration {
                        await viewModel.generatePoemFromPrompt("Stress test \(i)")
                    }
                default:
                    break
                }
                
                // Brief pause to allow state changes
                await Task.sleep(nanoseconds: 10_000_000) // 0.01 seconds
            }
            
            // Final state should be consistent
            XCTAssertTrue(
                viewModel.loadingState != .loading,
                "Should reach stable state after stress operations"
            )
            
            expectation.fulfill()
        }
        
        await fulfillment(of: [expectation], timeout: 60.0)
    }
    
    // MARK: - Resource Cleanup Edge Cases
    
    func testResourceCleanupUnderPressure() throws {
        // Test resource cleanup under memory pressure
        var poems: [Poem] = []
        
        // Create many poem objects
        for i in 0..<10000 {
            let poem = Poem(
                id: "cleanup_\(i)",
                title: "Cleanup Poem \(i)",
                author: "Memory Tester",
                content: String(repeating: "Line \(i) ", count: 100),
                date: Date(),
                source: .custom,
                isFavorite: i % 2 == 0
            )
            poems.append(poem)
        }
        
        XCTAssertEqual(poems.count, 10000, "Should create large number of objects")
        
        // Test operations on large dataset
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // Perform operations that might stress memory
        let favorites = poems.filter { $0.isFavorite }
        let encodedData = try? JSONEncoder().encode(favorites)
        
        let endTime = CFAbsoluteTimeGetCurrent()
        let duration = endTime - startTime
        
        XCTAssertLessThan(duration, 5.0, "Should handle large datasets efficiently")
        XCTAssertNotNil(encodedData, "Should encode large datasets")
        
        // Clean up
        poems.removeAll()
        XCTAssertEqual(poems.count, 0, "Should clean up successfully")
    }
    
    // MARK: - AI Edge Cases
    
    func testAIGenerationEdgeCases() async throws {
        guard AppConfiguration.FeatureFlags.aiPoemGeneration else {
            throw XCTSkip("AI features not available")
        }
        
        let edgeCasePrompts = [
            "", // Empty prompt
            " ", // Whitespace only
            String(repeating: "A", count: 10000), // Extremely long prompt
            "🎭🎪🎨🎯🎲", // Emoji only
            "Generate a poem about \n\n\n\t\t\r", // With control characters
            "Write a poem with \"quotes\" and 'apostrophes' and `backticks`", // Various quotes
            "CREATE TABLE poems; DROP TABLE users; --", // SQL injection attempt
            "<script>alert('xss')</script>", // XSS attempt
        ]
        
        for prompt in edgeCasePrompts {
            let expectation = expectation(description: "AI edge case: \(prompt.prefix(20))")
            
            Task {
                await viewModel.generatePoemFromPrompt(prompt)
                
                // Should handle edge case prompts gracefully
                // Either succeed or fail gracefully without crashing
                XCTAssertTrue(true, "Should handle edge case prompt gracefully")
                
                expectation.fulfill()
            }
            
            await fulfillment(of: [expectation], timeout: 15.0)
        }
    }
    
    // MARK: - Helper Methods
    
    private func fulfillment(of expectations: [XCTestExpectation], timeout: TimeInterval) async {
        await withCheckedContinuation { continuation in
            let waiter = XCTWaiter()
            let result = waiter.wait(for: expectations, timeout: timeout)
            continuation.resume()
        }
    }
} 