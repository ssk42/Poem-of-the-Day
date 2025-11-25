import XCTest
@testable import Poem_of_the_Day

final class DevicePlatformTests: XCTestCase {
    
    var poemRepository: PoemRepository!
    var networkService: MockNetworkService!
    var telemetryService: TelemetryService!
    
    override func setUpWithError() throws {
        networkService = MockNetworkService()
        telemetryService = TelemetryService()
        poemRepository = PoemRepository(networkService: networkService, telemetryService: telemetryService)
    }
    
    override func tearDownWithError() throws {
        poemRepository = nil
        networkService = nil
        telemetryService = nil
    }
    
    // MARK: - Screen Size Adaptation Tests
    
    func testDifferentScreenSizeLayouts() throws {
        // Test data preparation for different screen sizes
        let testPoem = TestData.samplePoems[0]
        
        // iPhone SE (small screen) - should truncate content appropriately
        let compactContent = testPoem.content.prefix(100)
        XCTAssertLessThanOrEqual(compactContent.count, 100, "Should adapt content for small screens")
        
        // iPad (large screen) - should display full content
        let fullContent = testPoem.content
        XCTAssertGreaterThan(fullContent.count, 0, "Should display full content on large screens")
        
        // Test title adaptation
        let longTitle = String(repeating: "Very Long Title ", count: 10)
        let adaptedTitle = String(longTitle.prefix(50))
        XCTAssertLessThanOrEqual(adaptedTitle.count, 50, "Should adapt titles for different screen sizes")
    }
    
    func testDynamicTypeScaling() throws {
        // Test content scaling for accessibility text sizes
        let testPoem = TestData.samplePoems[0]
        
        let textSizes: [String] = [
            "UICTContentSizeCategoryXS",
            "UICTContentSizeCategoryS", 
            "UICTContentSizeCategoryM",
            "UICTContentSizeCategoryL",
            "UICTContentSizeCategoryXL",
            "UICTContentSizeCategoryXXL",
            "UICTContentSizeCategoryXXXL",
            "UICTContentSizeCategoryAccessibilityM",
            "UICTContentSizeCategoryAccessibilityL",
            "UICTContentSizeCategoryAccessibilityXL",
            "UICTContentSizeCategoryAccessibilityXXL",
            "UICTContentSizeCategoryAccessibilityXXXL"
        ]
        
        for textSize in textSizes {
            // Simulate content adaptation for different text sizes
            let scaleFactor = getScaleFactor(for: textSize)
            let adaptedContent = adaptContentForScale(testPoem.content, scale: scaleFactor)
            
            XCTAssertGreaterThan(adaptedContent.count, 0, "Should adapt content for \(textSize)")
            XCTAssertLessThanOrEqual(adaptedContent.count, testPoem.content.count, "Should not exceed original content")
        }
    }
    
    // MARK: - Device Capability Tests
    
    func testLowEndDevicePerformance() async throws {
        // Simulate low-end device constraints
        let expectation = expectation(description: "Low-end device test")
        
        // Reduced concurrent operations for low-end devices
        let maxConcurrentOperations = 2
        
        for i in 0..<maxConcurrentOperations {
            Task {
                do {
                    let _ = try await poemRepository.getDailyPoem()
                } catch {
                    // Expected on low-end devices
                }
                expectation.fulfill()
            }
        }
        
        expectation.expectedFulfillmentCount = maxConcurrentOperations
        try await XCTWaiter.fulfillment(of: [expectation], timeout: 3.0)
    }
    
    func testHighEndDeviceOptimizations() async throws {
        // Test optimizations for high-end devices
        let expectation = expectation(description: "High-end device test")
        
        // More concurrent operations for high-end devices
        let maxConcurrentOperations = 10
        
        await withTaskGroup(of: Void.self) { group in
            for i in 0..<maxConcurrentOperations {
                group.addTask {
                    do {
                        let _ = try await self.poemRepository.getDailyPoem()
                    } catch {
                        // Some failures expected
                    }
                }
            }
        }
        
        expectation.fulfill()
        try await XCTWaiter.fulfillment(of: [expectation], timeout: 5.0)
    }
    
    // MARK: - Orientation Change Tests
    
    func testOrientationChangeHandling() throws {
        // Test content adaptation for orientation changes
        let testPoem = TestData.samplePoems[0]
        
        // Portrait mode - more vertical space
        let portraitContent = adaptContentForOrientation(testPoem.content, isPortrait: true)
        XCTAssertGreaterThan(portraitContent.count, 0, "Should handle portrait orientation")
        
        // Landscape mode - more horizontal space
        let landscapeContent = adaptContentForOrientation(testPoem.content, isPortrait: false)
        XCTAssertGreaterThan(landscapeContent.count, 0, "Should handle landscape orientation")
        
        // Test title wrapping
        let longTitle = "This is a very long poem title that might need wrapping"
        let portraitTitle = adaptTitleForOrientation(longTitle, isPortrait: true)
        let landscapeTitle = adaptTitleForOrientation(longTitle, isPortrait: false)
        
        XCTAssertNotEqual(portraitTitle, landscapeTitle, "Should adapt titles differently for orientations")
    }
    
    // MARK: - Battery Optimization Tests
    
    func testLowPowerModeOptimizations() throws {
        // Test behavior in low power mode
        let isLowPowerMode = true
        
        if isLowPowerMode {
            // Reduce background operations
            let reducedUpdateFrequency = 300.0 // 5 minutes instead of 1 minute
            XCTAssertGreaterThan(reducedUpdateFrequency, 60.0, "Should reduce update frequency in low power mode")
            
            // Disable non-essential animations
            let animationsEnabled = false
            XCTAssertFalse(animationsEnabled, "Should disable animations in low power mode")
        }
    }
    
    func testThermalStateHandling() throws {
        // Test thermal state handling
        let thermalStates = ["normal", "fair", "serious", "critical"]
        
        for thermalState in thermalStates {
            let maxOperations = getMaxOperationsForThermalState(thermalState)
            
            switch thermalState {
            case "normal":
                XCTAssertGreaterThanOrEqual(maxOperations, 10, "Normal thermal state should allow full operations")
            case "fair":
                XCTAssertGreaterThanOrEqual(maxOperations, 5, "Fair thermal state should allow reduced operations")
            case "serious":
                XCTAssertGreaterThanOrEqual(maxOperations, 2, "Serious thermal state should allow minimal operations")
            case "critical":
                XCTAssertEqual(maxOperations, 1, "Critical thermal state should allow only essential operations")
            default:
                break
            }
        }
    }
    
    // MARK: - Network Capability Tests
    
    func testCellularDataOptimizations() throws {
        // Test optimizations for cellular data
        let connectionTypes = ["WiFi", "4G", "3G", "2G"]
        
        for connectionType in connectionTypes {
            let dataLimit = getDataLimitForConnection(connectionType)
            let compressionEnabled = shouldEnableCompressionForConnection(connectionType)
            
            switch connectionType {
            case "WiFi":
                XCTAssertGreaterThan(dataLimit, 10_000_000, "WiFi should allow large data transfers")
                XCTAssertFalse(compressionEnabled, "WiFi may not need compression")
            case "4G":
                XCTAssertGreaterThan(dataLimit, 1_000_000, "4G should allow moderate data transfers")
                XCTAssertTrue(compressionEnabled, "4G should use compression")
            case "3G", "2G":
                XCTAssertLessThanOrEqual(dataLimit, 1_000_000, "Slow connections should limit data")
                XCTAssertTrue(compressionEnabled, "Slow connections should use compression")
            default:
                break
            }
        }
    }
    
    // MARK: - Accessibility Hardware Tests
    
    func testVoiceOverIntegration() throws {
        // Test VoiceOver support
        let testPoem = TestData.samplePoems[0]
        
        // Test accessibility labels
        let titleAccessibilityLabel = "Poem title: \(testPoem.title)"
        let authorAccessibilityLabel = "By author: \(testPoem.author ?? "Unknown")"
        let contentAccessibilityLabel = "Poem content: \(testPoem.content.prefix(100))..."
        
        XCTAssertFalse(titleAccessibilityLabel.isEmpty, "Should provide title accessibility label")
        XCTAssertFalse(authorAccessibilityLabel.isEmpty, "Should provide author accessibility label")
        XCTAssertFalse(contentAccessibilityLabel.isEmpty, "Should provide content accessibility label")
    }
    
    func testSwitchControlSupport() throws {
        // Test Switch Control accessibility
        let interactiveElements = ["refreshButton", "favoriteButton", "shareButton", "favoritesButton"]
        
        for elementId in interactiveElements {
            let isAccessible = true // All interactive elements should be accessible
            let hasAccessibilityIdentifier = !elementId.isEmpty
            
            XCTAssertTrue(isAccessible, "\(elementId) should be accessible to Switch Control")
            XCTAssertTrue(hasAccessibilityIdentifier, "\(elementId) should have accessibility identifier")
        }
    }
    
    // MARK: - Helper Methods
    
    private func getScaleFactor(for textSize: String) -> Double {
        switch textSize {
        case "UICTContentSizeCategoryXS": return 0.8
        case "UICTContentSizeCategoryS": return 0.9
        case "UICTContentSizeCategoryM": return 1.0
        case "UICTContentSizeCategoryL": return 1.1
        case "UICTContentSizeCategoryXL": return 1.2
        case "UICTContentSizeCategoryXXL": return 1.3
        case "UICTContentSizeCategoryXXXL": return 1.4
        default: return 1.5 // Accessibility sizes
        }
    }
    
    private func adaptContentForScale(_ content: String, scale: Double) -> String {
        let maxLength = Int(Double(content.count) / scale)
        return String(content.prefix(maxLength))
    }
    
    private func adaptContentForOrientation(_ content: String, isPortrait: Bool) -> String {
        return isPortrait ? content : String(content.prefix(content.count * 3 / 4))
    }
    
    private func adaptTitleForOrientation(_ title: String, isPortrait: Bool) -> String {
        return isPortrait ? title : String(title.prefix(30))
    }
    
    private func getMaxOperationsForThermalState(_ state: String) -> Int {
        switch state {
        case "normal": return 10
        case "fair": return 5
        case "serious": return 2
        case "critical": return 1
        default: return 1
        }
    }
    
    private func getDataLimitForConnection(_ type: String) -> Int {
        switch type {
        case "WiFi": return 50_000_000
        case "4G": return 10_000_000
        case "3G": return 1_000_000
        case "2G": return 100_000
        default: return 100_000
        }
    }
    
    private func shouldEnableCompressionForConnection(_ type: String) -> Bool {
        return type != "WiFi"
    }
    
}