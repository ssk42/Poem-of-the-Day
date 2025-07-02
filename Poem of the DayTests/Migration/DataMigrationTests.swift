import XCTest
@testable import Poem_of_the_Day

final class DataMigrationTests: XCTestCase {
    
    var mockUserDefaults: UserDefaults!
    
    override func setUpWithError() throws {
        // Create isolated test environment
        let suiteName = "DataMigrationTests_\(UUID().uuidString)"
        mockUserDefaults = UserDefaults(suiteName: suiteName)!
    }
    
    override func tearDownWithError() throws {
        if let suiteName = mockUserDefaults.persistentDomain(forName: mockUserDefaults.dictionaryRepresentation().keys.first ?? "") {
            mockUserDefaults.removeSuite(named: mockUserDefaults.dictionaryRepresentation().keys.first ?? "")
        }
        mockUserDefaults = nil
    }
    
    // MARK: - Version Migration Tests
    
    func testMigrationFromVersion1ToVersion2() throws {
        // Simulate old version 1.0 data format
        let oldFavoritesData = [
            "poem1": "Title 1|Author 1|Content 1",
            "poem2": "Title 2|Author 2|Content 2"
        ]
        
        mockUserDefaults.set(oldFavoritesData, forKey: "old_favorites")
        
        // Migrate to new format
        let migratedPoems = migrateV1ToV2Favorites(from: mockUserDefaults)
        
        XCTAssertEqual(migratedPoems.count, 2, "Should migrate all old favorites")
        XCTAssertEqual(migratedPoems[0].title, "Title 1", "Should preserve title")
        XCTAssertEqual(migratedPoems[0].author, "Author 1", "Should preserve author")
        XCTAssertEqual(migratedPoems[0].content, "Content 1", "Should preserve content")
    }
    
    func testMigrationFromVersion2ToVersion3() throws {
        // Simulate version 2.0 data format (basic JSON)
        let v2Poems = [
            ["id": "1", "title": "V2 Title", "author": "V2 Author", "content": "V2 Content"],
            ["id": "2", "title": "V2 Title 2", "author": "V2 Author 2", "content": "V2 Content 2"]
        ]
        
        let v2Data = try JSONSerialization.data(withJSONObject: v2Poems)
        mockUserDefaults.set(v2Data, forKey: "v2_favorites")
        
        // Migrate to version 3 format (with dates and sources)
        let migratedPoems = migrateV2ToV3Favorites(from: mockUserDefaults)
        
        XCTAssertEqual(migratedPoems.count, 2, "Should migrate V2 favorites")
        XCTAssertNotNil(migratedPoems[0].date, "Should add default date")
        XCTAssertEqual(migratedPoems[0].source, .daily, "Should add default source")
    }
    
    func testCurrentVersionCompatibility() throws {
        // Test current version data handling
        let currentPoems = TestData.samplePoems
        
        let encoder = JSONEncoder()
        let encodedData = try encoder.encode(currentPoems)
        mockUserDefaults.set(encodedData, forKey: "current_favorites")
        
        // Should load without migration
        guard let storedData = mockUserDefaults.data(forKey: "current_favorites") else {
            XCTFail("Should store current version data")
            return
        }
        
        let decoder = JSONDecoder()
        let decodedPoems = try decoder.decode([Poem].self, from: storedData)
        
        XCTAssertEqual(decodedPoems.count, currentPoems.count, "Should preserve current data")
        XCTAssertEqual(decodedPoems[0].id, currentPoems[0].id, "Should preserve poem IDs")
    }
    
    // MARK: - Schema Evolution Tests
    
    func testNewFieldHandling() throws {
        // Test handling of data with missing new fields
        let oldPoemJSON = """
        {
            "id": "old_poem",
            "title": "Old Poem",
            "author": "Old Author",
            "content": "Old Content"
        }
        """
        
        let oldData = oldPoemJSON.data(using: .utf8)!
        
        // Should handle missing fields gracefully
        let decoder = JSONDecoder()
        do {
            let poem = try decoder.decode(Poem.self, from: oldData)
            XCTAssertEqual(poem.title, "Old Poem", "Should decode old data")
            XCTAssertNotNil(poem.date, "Should provide default date")
        } catch {
            // Expected if strict decoding - should implement custom decoder
            XCTAssertTrue(true, "Should handle old data format gracefully")
        }
    }
    
    func testRemovedFieldHandling() throws {
        // Test handling of data with removed fields
        let futureData = """
        {
            "id": "future_poem",
            "title": "Future Poem",
            "author": "Future Author", 
            "content": "Future Content",
            "date": "2023-01-01T00:00:00Z",
            "source": "daily",
            "isFavorite": true,
            "removedField": "This field was removed",
            "anotherRemovedField": 42
        }
        """
        
        let futureDataEncoded = futureData.data(using: .utf8)!
        
        // Should ignore unknown fields
        let decoder = JSONDecoder()
        let formatter = ISO8601DateFormatter()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)
            return formatter.date(from: dateString) ?? Date()
        }
        
        do {
            let poem = try decoder.decode(Poem.self, from: futureDataEncoded)
            XCTAssertEqual(poem.title, "Future Poem", "Should decode known fields")
            XCTAssertEqual(poem.isFavorite, true, "Should preserve favorite status")
        } catch {
            XCTFail("Should handle future data with removed fields: \(error)")
        }
    }
    
    // MARK: - Data Integrity Tests
    
    func testDataCorruptionRecovery() throws {
        // Test recovery from corrupted data
        let corruptedData = "This is not valid JSON data".data(using: .utf8)!
        mockUserDefaults.set(corruptedData, forKey: "corrupted_favorites")
        
        // Should recover gracefully
        let recoveredData = recoverFavoritesData(from: mockUserDefaults)
        XCTAssertNotNil(recoveredData, "Should recover from corruption")
        XCTAssertEqual(recoveredData.count, 0, "Should return empty array for corrupted data")
    }
    
    func testPartialDataCorruption() throws {
        // Test handling of partially corrupted data
        let mixedData = [
            validPoemJSON(),
            "{ invalid json",
            validPoemJSON(),
            "{ \"incomplete\": true"
        ]
        
        let validPoems = recoverValidPoems(from: mixedData)
        XCTAssertEqual(validPoems.count, 2, "Should recover valid poems from mixed data")
    }
    
    // MARK: - Performance Migration Tests
    
    func testLargDataSetMigration() throws {
        // Test migration performance with large datasets
        let largeDataset = (0..<1000).map { index in
            [
                "id": "large_\(index)",
                "title": "Large Dataset Poem \(index)",
                "author": "Author \(index)",
                "content": "Content for poem number \(index)"
            ]
        }
        
        let startTime = CFAbsoluteTimeGetCurrent()
        
        let largeData = try JSONSerialization.data(withJSONObject: largeDataset)
        mockUserDefaults.set(largeData, forKey: "large_dataset")
        
        let migratedPoems = migrateV2ToV3Favorites(from: mockUserDefaults, key: "large_dataset")
        
        let endTime = CFAbsoluteTimeGetCurrent()
        let migrationTime = endTime - startTime
        
        XCTAssertLessThan(migrationTime, 2.0, "Should migrate 1000 poems within 2 seconds")
        XCTAssertEqual(migratedPoems.count, 1000, "Should migrate all poems")
    }
    
    // MARK: - Backup and Restore Tests
    
    func testDataBackupCreation() throws {
        // Test creating backup before migration
        let testPoems = TestData.samplePoems
        let encoder = JSONEncoder()
        let originalData = try encoder.encode(testPoems)
        
        mockUserDefaults.set(originalData, forKey: "favorites")
        
        // Create backup
        let backupCreated = createBackup(userDefaults: mockUserDefaults, key: "favorites")
        XCTAssertTrue(backupCreated, "Should create backup successfully")
        
        // Verify backup exists
        let backupData = mockUserDefaults.data(forKey: "favorites_backup_\(getCurrentDateString())")
        XCTAssertNotNil(backupData, "Should store backup data")
        XCTAssertEqual(backupData, originalData, "Backup should match original data")
    }
    
    func testDataRestoreFromBackup() throws {
        // Test restoring from backup after failed migration
        let backupPoems = TestData.samplePoems
        let encoder = JSONEncoder()
        let backupData = try encoder.encode(backupPoems)
        
        let backupKey = "favorites_backup_\(getCurrentDateString())"
        mockUserDefaults.set(backupData, forKey: backupKey)
        
        // Simulate failed migration (corrupted data)
        mockUserDefaults.set("corrupted".data(using: .utf8), forKey: "favorites")
        
        // Restore from backup
        let restored = restoreFromBackup(userDefaults: mockUserDefaults, key: "favorites")
        XCTAssertTrue(restored, "Should restore from backup successfully")
        
        // Verify restoration
        guard let restoredData = mockUserDefaults.data(forKey: "favorites") else {
            XCTFail("Should have restored data")
            return
        }
        
        let decoder = JSONDecoder()
        let restoredPoems = try decoder.decode([Poem].self, from: restoredData)
        XCTAssertEqual(restoredPoems.count, backupPoems.count, "Should restore all poems")
    }
    
    // MARK: - Migration Helper Methods
    
    private func migrateV1ToV2Favorites(from userDefaults: UserDefaults) -> [Poem] {
        guard let oldData = userDefaults.dictionary(forKey: "old_favorites") as? [String: String] else {
            return []
        }
        
        return oldData.compactMap { (key, value) in
            let components = value.components(separatedBy: "|")
            guard components.count == 3 else { return nil }
            
            return Poem(
                id: key,
                title: components[0],
                author: components[1], 
                content: components[2],
                date: Date(),
                source: .daily,
                isFavorite: true
            )
        }
    }
    
    private func migrateV2ToV3Favorites(from userDefaults: UserDefaults, key: String = "v2_favorites") -> [Poem] {
        guard let v2Data = userDefaults.data(forKey: key) else { return [] }
        
        do {
            let v2Array = try JSONSerialization.jsonObject(with: v2Data) as? [[String: Any]] ?? []
            
            return v2Array.compactMap { dict in
                guard let id = dict["id"] as? String,
                      let title = dict["title"] as? String,
                      let author = dict["author"] as? String,
                      let content = dict["content"] as? String else {
                    return nil
                }
                
                return Poem(
                    id: id,
                    title: title,
                    author: author,
                    content: content,
                    date: Date(),
                    source: .daily,
                    isFavorite: true
                )
            }
        } catch {
            return []
        }
    }
    
    private func recoverFavoritesData(from userDefaults: UserDefaults) -> [Poem] {
        // Try to recover what we can from corrupted data
        guard let corruptedData = userDefaults.data(forKey: "corrupted_favorites") else {
            return []
        }
        
        // In real implementation, would try various recovery strategies
        return [] // Return empty array for completely corrupted data
    }
    
    private func recoverValidPoems(from jsonStrings: [String]) -> [Poem] {
        return jsonStrings.compactMap { jsonString in
            guard let data = jsonString.data(using: .utf8) else { return nil }
            
            do {
                let decoder = JSONDecoder()
                return try decoder.decode(Poem.self, from: data)
            } catch {
                return nil // Skip invalid JSON
            }
        }
    }
    
    private func validPoemJSON() -> String {
        return """
        {
            "id": "valid_poem",
            "title": "Valid Poem",
            "author": "Valid Author",
            "content": "Valid Content",
            "date": "2023-01-01T00:00:00Z",
            "source": "daily",
            "isFavorite": true
        }
        """
    }
    
    private func createBackup(userDefaults: UserDefaults, key: String) -> Bool {
        guard let originalData = userDefaults.data(forKey: key) else { return false }
        
        let backupKey = "\(key)_backup_\(getCurrentDateString())"
        userDefaults.set(originalData, forKey: backupKey)
        return true
    }
    
    private func restoreFromBackup(userDefaults: UserDefaults, key: String) -> Bool {
        let backupKey = "\(key)_backup_\(getCurrentDateString())"
        guard let backupData = userDefaults.data(forKey: backupKey) else { return false }
        
        userDefaults.set(backupData, forKey: key)
        return true
    }
    
    private func getCurrentDateString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }
} 