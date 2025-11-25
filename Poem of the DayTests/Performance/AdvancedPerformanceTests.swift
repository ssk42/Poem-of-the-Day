import XCTest
@testable import Poem_of_the_Day

@MainActor
final class AdvancedPerformanceTests: XCTestCase {
    
    var poemRepository: PoemRepository!
    var viewModel: PoemViewModel!
    var networkService: MockNetworkService!
    var telemetryService: TelemetryService!
    
    override func setUpWithError() throws {
        networkService = MockNetworkService()
        telemetryService = TelemetryService()
        poemRepository = PoemRepository(networkService: networkService, telemetryService: telemetryService)
        viewModel = PoemViewModel(
            repository: poemRepository,
            telemetryService: telemetryService
        )
    }
    
    override func tearDownWithError() throws {
        viewModel = nil
        poemRepository = nil
        networkService = nil
        telemetryService = nil
    }
    
    // MARK: - Stress Testing
    
    func testMassiveFavoritesPerformance() throws {
        // Test performance with thousands of favorite poems
        measure {
            let massivePoems = (0..<5000).map { index in
                Poem(
                    id: UUID(),
                    title: "Stress Test Poem \(index)",
                    lines: ["""
                    This is a stress test poem number \(index).
                    It has multiple lines to simulate real poem content.
                    Line 3 of poem \(index).
                    Line 4 with more content for poem \(index).
                    Final line of stress test poem \(index).
                    """],
                    author: "Stress Tester \(index)",
                    vibe: nil,
                    source: .aiGenerated
                )
            }
            
            // Test JSON encoding performance with massive dataset
            let encoder = JSONEncoder()
            do {
                let startTime = CFAbsoluteTimeGetCurrent()
                let encodedData = try encoder.encode(massivePoems)
                let encodingTime = CFAbsoluteTimeGetCurrent() - startTime
                
                XCTAssertLessThan(encodingTime, 2.0, "Should encode 5000 poems within 2 seconds")
                XCTAssertGreaterThan(encodedData.count, 0, "Should produce encoded data")
                
                // Test decoding performance
                let decodingStartTime = CFAbsoluteTimeGetCurrent()
                let decoder = JSONDecoder()
                let decodedPoems = try decoder.decode([Poem].self, from: encodedData)
                let decodingTime = CFAbsoluteTimeGetCurrent() - decodingStartTime
                
                XCTAssertLessThan(decodingTime, 2.0, "Should decode 5000 poems within 2 seconds")
                XCTAssertEqual(decodedPoems.count, massivePoems.count, "Should preserve all poems")
                
            } catch {
                XCTFail("Should handle massive dataset encoding/decoding: \(error)")
            }
        }
    }
    
    func testRapidAPICallsPerformance() throws {
        // Test performance under rapid API calls
        let numberOfCalls = 100
        
        networkService.delayDuration = 0.01 // Very fast responses
        
        measure {
            let expectation = expectation(description: "Rapid API calls")
            expectation.expectedFulfillmentCount = numberOfCalls
            
            Task {
                let startTime = CFAbsoluteTimeGetCurrent()
                
                // Make 100 concurrent API calls
                await withTaskGroup(of: Void.self) { group in
                    for _ in 0..<numberOfCalls {
                        group.addTask {
                            do {
                                let _ = try await self.poemRepository.getDailyPoem()
                            } catch {
                                // Expected - some may fail due to rapid calls
                            }
                            expectation.fulfill()
                        }
                    }
                }
                
                let endTime = CFAbsoluteTimeGetCurrent()
                let duration = endTime - startTime
                
                XCTAssertLessThan(duration, 5.0, "Should handle 100 concurrent API calls within 5 seconds")
            }
            
            wait(for: [expectation], timeout: 10.0)
        }
    }
    
    func testMemoryIntensiveOperations() throws {
        // Test memory performance under intensive operations
        measure(metrics: [XCTMemoryMetric()]) {
            let expectation = expectation(description: "Memory intensive operations")
            
            Task {
                // Create and process large amounts of data
                for _ in 0..<10 {
                    let batchPoems = (0..<1000).map { index in
                        Poem(
                            id: UUID(),
                            title: "Memory Test Poem \(index)",
                            lines: [String(repeating: "Memory intensive content line. ", count: 100)],
                            author: "Memory Tester",
                            vibe: nil,
                            source: .aiGenerated
                        )
                    }
                    
                    // Process each batch
                    for poem in batchPoems {
                        let _ = poem.shareText
                        let encoder = JSONEncoder()
                        let _ = try? encoder.encode(poem)
                    }
                    
                    // Force memory cleanup between batches
                    autoreleasepool {
                        // Cleanup happens automatically
                    }
                }
                expectation.fulfill()
            }
            
            wait(for: [expectation], timeout: 30.0)
        }
    }
    
    func testConcurrentViewModelOperations() throws {
        // Test performance of concurrent ViewModel operations
        measure {
            let numberOfOperations = 50
            let expectation = expectation(description: "Concurrent operations")
            expectation.expectedFulfillmentCount = numberOfOperations
            
            Task {
                // Perform multiple concurrent operations
                await withTaskGroup(of: Void.self) { group in
                    for i in 0..<numberOfOperations {
                        group.addTask {
                            if i % 4 == 0 {
                                await self.viewModel.loadInitialData()
                            } else if i % 4 == 1 {
                                await self.viewModel.refreshPoem()
                            } else if i % 4 == 2 {
                                let _ = await self.viewModel.favorites
                            } else {
                                if await self.viewModel.isAIGenerationAvailable {
                                    await self.viewModel.generateCustomPoem(prompt: "Test prompt \(i)")
                                }
                            }
                            expectation.fulfill()
                        }
                    }
                }
            }
            
            wait(for: [expectation], timeout: 15.0)
        }
    }
    
    // MARK: - Scalability Testing
    
    func testLargeDataSetSearchPerformance() throws {
        // Test search performance in large datasets
        let largeDataset = (0..<10000).map { index in
            Poem(
                id: UUID(),
                title: "Searchable Poem \(index)",
                lines: ["Content for poem \(index) with searchable terms"],
                author: "Author \(index % 100)", // 100 different authors
                vibe: nil,
                source: index % 2 == 0 ? .api : .aiGenerated
            )
        }
        
        measure {
            // Simulate search operations
            let searchTerms = ["Poem", "Author", "Content", "searchable", "terms"]
            
            for searchTerm in searchTerms {
                let startTime = CFAbsoluteTimeGetCurrent()
                
                let filteredPoems = largeDataset.filter { poem in
                    poem.title.localizedCaseInsensitiveContains(searchTerm) ||
                    (poem.author?.localizedCaseInsensitiveContains(searchTerm) ?? false) ||
                    poem.content.localizedCaseInsensitiveContains(searchTerm)
                }
                
                let searchTime = CFAbsoluteTimeGetCurrent() - startTime
                
                XCTAssertLessThan(searchTime, 0.5, "Should search 10k poems within 0.5 seconds")
                XCTAssertGreaterThan(filteredPoems.count, 0, "Should find matching poems")
            }
        }
    }
    
    func testSortingLargeDatasets() throws {
        // Test sorting performance on large datasets
        let unsortedPoems = (0..<5000).shuffled().map { index in
            Poem(
                id: UUID(),
                title: "Title \(index)",
                lines: ["Content \(index)"],
                author: "Author \(index % 200)",
                vibe: nil,
                source: .api
            )
        }
        
        measure {
            // Test different sorting operations
            let sortingOperations: [(String, (Poem, Poem) -> Bool)] = [
                ("by title", { $0.title < $1.title }),
                ("by author", { ($0.author ?? "") < ($1.author ?? "") })
            ]
            
            for (sortName, sortClosure) in sortingOperations {
                let startTime = CFAbsoluteTimeGetCurrent()
                let sortedPoems = unsortedPoems.sorted(by: sortClosure)
                let sortTime = CFAbsoluteTimeGetCurrent() - startTime
                
                XCTAssertLessThan(sortTime, 1.0, "Should sort 5k poems \(sortName) within 1 second")
                XCTAssertEqual(sortedPoems.count, unsortedPoems.count, "Should preserve all poems")
            }
        }
    }
    
    // MARK: - Network Performance Testing
    
    func testNetworkLatencyVariations() async throws {
        // Test performance under various network latency conditions
        let latencyScenarios: [TimeInterval] = [0.001, 0.01, 0.1, 0.5, 1.0, 2.0]
        
        for latency in latencyScenarios {
            networkService.delayDuration = latency
            
            let expectation = expectation(description: "Latency test \(latency)s")
            
            let startTime = CFAbsoluteTimeGetCurrent()
            
            do {
                let _ = try await poemRepository.getDailyPoem()
                let endTime = CFAbsoluteTimeGetCurrent()
                let actualDuration = endTime - startTime
                
                // Should complete within reasonable time considering simulated latency
                XCTAssertGreaterThanOrEqual(actualDuration, latency, "Should respect simulated latency")
                XCTAssertLessThan(actualDuration, latency + 2.0, "Should not add excessive overhead")
                
            } catch {
                XCTFail("Should handle latency scenario \(latency)s: \(error)")
            }
            
            expectation.fulfill()
            await fulfillment(of: [expectation], timeout: latency + 5.0)
        }
    }
    
    /*
    func testBandwidthLimitations() async throws {
        // Test disabled because MockNetworkService doesn't support raw data mocking
    }
    */
    
    // MARK: - AI Performance Testing
    
    func testAIGenerationPerformanceVariations() throws {
        // Test AI generation performance under different conditions
        // Note: Using synchronous check since we are in measure block context
        // Assuming AI is available for test
        
        let testPrompts = [
            "Short",
            "A medium length prompt with some creative direction",
            String(repeating: "Very long and detailed prompt with extensive creative direction and specific requirements that might challenge the AI generation system. ", count: 10)
        ]
        
        for (index, prompt) in testPrompts.enumerated() {
            measure {
                let expectation = expectation(description: "AI performance test \(index)")
                
                Task {
                    let startTime = CFAbsoluteTimeGetCurrent()
                    await viewModel.generateCustomPoem(prompt: prompt)
                    let endTime = CFAbsoluteTimeGetCurrent()
                    let duration = endTime - startTime
                    
                    XCTAssertLessThan(duration, 10.0, "Should generate poem within 10 seconds")
                    XCTAssertNotNil(viewModel.poemOfTheDay, "Should generate poem")
                    
                    expectation.fulfill()
                }
                
                wait(for: [expectation], timeout: 15.0)
            }
        }
    }
    
    func testConcurrentAIGenerations() throws {
        // Test performance of concurrent AI generations
        
        measure {
            let numberOfGenerations = 5
            let expectation = expectation(description: "Concurrent AI generations")
            expectation.expectedFulfillmentCount = numberOfGenerations
            
            Task {
                await withTaskGroup(of: Void.self) { group in
                    for i in 0..<numberOfGenerations {
                        group.addTask {
                            await self.viewModel.generateCustomPoem(prompt: "Concurrent test \(i)")
                            expectation.fulfill()
                        }
                    }
                }
            }
            
            wait(for: [expectation], timeout: 30.0)
        }
    }
    
    // MARK: - Memory Pressure Testing
    
    func testLowMemoryScenarioHandling() throws {
        // Simulate low memory conditions
        measure(metrics: [XCTMemoryMetric()]) {
            // Create memory pressure scenario
            var memoryIntensiveData: [[Poem]] = []
            
            for batch in 0..<100 {
                let batchData = (0..<100).map { index in
                    Poem(
                        id: UUID(),
                        title: "Memory Pressure Poem \(index)",
                        lines: [String(repeating: "Memory pressure line \(index). ", count: 50)],
                        author: "Pressure Tester",
                        vibe: nil,
                        source: .aiGenerated
                    )
                }
                memoryIntensiveData.append(batchData)
                
                // Simulate memory cleanup every 10 batches
                if batch % 10 == 9 {
                    memoryIntensiveData.removeFirst(5)
                }
            }
            
            // Verify system remains responsive
            XCTAssertGreaterThan(memoryIntensiveData.count, 0, "Should handle memory pressure")
        }
    }
    
    // MARK: - CPU Intensive Performance Testing
    
    func testCPUIntensiveOperations() throws {
        // Test CPU-intensive operations
        measure(metrics: [XCTCPUMetric()]) {
            let complexPoems = (0..<1000).map { index in
                Poem(
                    id: UUID(),
                    title: "CPU Test Poem \(index)",
                    lines: [generateComplexContent(index: index)],
                    author: "CPU Tester",
                    vibe: nil,
                    source: .aiGenerated
                )
            }
            
            // Perform CPU-intensive operations
            for poem in complexPoems {
                // Multiple operations that require CPU
                let _ = poem.shareText
                let _ = poem.id.hashValue
                let encoder = JSONEncoder()
                let _ = try? encoder.encode(poem)
            }
            
            XCTAssertEqual(complexPoems.count, 1000, "Should complete CPU-intensive operations")
        }
    }
    
    // MARK: - Helper Methods
    
    private func generateComplexContent(index: Int) -> String {
        let lines = (0..<20).map { lineIndex in
            "Line \(lineIndex) of poem \(index) with complex content including numbers: \(lineIndex * index) and calculations: \(Double(lineIndex) / Double(max(index, 1)))."
        }
        return lines.joined(separator: "\n")
    }
    
    private func fulfillment(of expectations: [XCTestExpectation], timeout: TimeInterval) async {
        await withCheckedContinuation { continuation in
            let waiter = XCTWaiter()
            let _ = waiter.wait(for: expectations, timeout: timeout)
            continuation.resume()
        }
    }
} 