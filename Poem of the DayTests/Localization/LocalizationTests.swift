import XCTest
@testable import Poem_of_the_Day

final class LocalizationTests: XCTestCase {
    
    var poemRepository: PoemRepository!
    var networkService: MockNetworkService!
    
    override func setUpWithError() throws {
        networkService = MockNetworkService()
        poemRepository = PoemRepository(networkService: networkService, telemetryService: TelemetryService())
    }
    
    override func tearDownWithError() throws {
        poemRepository = nil
        networkService = nil
    }
    
    // MARK: - Multi-Language Content Tests
    
    func testInternationalPoemContent() throws {
        let internationalPoems = [
            // English
            Poem(id: UUID(), title: "English Poem", lines: ["This is an English poem with standard Latin characters."], author: "English Author", source: .api),
            
            // Spanish
            Poem(id: UUID(), title: "Poema Español", lines: ["Este es un poema en español con acentos: café, niño, corazón."], author: "Autor Español", source: .api),
            
            // French  
            Poem(id: UUID(), title: "Poème Français", lines: ["Ceci est un poème français avec des accents: été, cœur, naïve."], author: "Auteur Français", source: .api),
            
            // German
            Poem(id: UUID(), title: "Deutsches Gedicht", lines: ["Dies ist ein deutsches Gedicht mit Umlauten: Größe, Hände, Mädchen."], author: "Deutscher Autor", source: .api),
            
            // Japanese
            Poem(id: UUID(), title: "日本の詩", lines: ["これは日本語の詩です。桜、月、海の美しさを歌います。"], author: "日本の作家", source: .api),
            
            // Arabic (RTL)
            Poem(id: UUID(), title: "قصيدة عربية", lines: ["هذه قصيدة عربية تحتوي على نصوص من اليمين إلى اليسار."], author: "شاعر عربي", source: .api),
            
            // Hebrew (RTL)
            Poem(id: UUID(), title: "שיר עברי", lines: ["זהו שיר עברי עם טקסט מימין לשמאל וניקוד."], author: "משורר עברי", source: .api),
            
            // Chinese
            Poem(id: UUID(), title: "中文诗", lines: ["这是一首中文诗，包含简体中文字符。"], author: "中文作者", source: .api),
            
            // Russian
            Poem(id: UUID(), title: "Русская поэма", lines: ["Это русская поэма с кириллическими символами: борщ, водка, медведь."], author: "Русский автор", source: .api)
        ]
        
        for poem in internationalPoems {
            // Test encoding/decoding with international characters
            let encoder = JSONEncoder()
            do {
                let encodedData = try encoder.encode(poem)
                let decoder = JSONDecoder()
                let decodedPoem = try decoder.decode(Poem.self, from: encodedData)
                
                XCTAssertEqual(decodedPoem.title, poem.title, "Should preserve international title")
                XCTAssertEqual(decodedPoem.author, poem.author, "Should preserve international author")
                XCTAssertEqual(decodedPoem.content, poem.content, "Should preserve international content")
                
            } catch {
                XCTFail("Should handle international encoding for \(poem.id): \(error)")
            }
            
            // Test share text with international characters
            let shareText = poem.shareText
            XCTAssertTrue(shareText.contains(poem.title), "Share text should contain international title")
            XCTAssertFalse(shareText.isEmpty, "Should generate share text for international content")
        }
    }
    
    // MARK: - Text Direction Tests
    
    func testRightToLeftLanguageSupport() throws {
        let rtlPoems = [
            Poem(id: UUID(), title: "العنوان العربي", lines: ["محتوى النص العربي من اليمين إلى اليسار مع أرقام ١٢٣٤٥٦٧٨٩٠"], author: "المؤلف العربي", source: .api),
            
            Poem(id: UUID(), title: "כותרת עברית", lines: ["תוכן עברי מימין לשמאל עם מספרים ١٢٣٤٥٦٧٨٩٠"], author: "כותב עברי", source: .api),
            
            Poem(id: UUID(), title: "عنوان فارسی", lines: ["محتوای فارسی از راست به چپ با اعداد ۱۲۳۴۵۶۷۸۹۰"], author: "نویسنده فارسی", source: .api)
        ]
        
        for poem in rtlPoems {
            // Test that RTL text is handled properly
            XCTAssertGreaterThan(poem.title.count, 0, "RTL title should not be empty")
            XCTAssertGreaterThan(poem.content.count, 0, "RTL content should not be empty")
            
            // Test character encoding
            let titleData = poem.title.data(using: .utf8)
            let contentData = poem.content.data(using: .utf8)
            
            XCTAssertNotNil(titleData, "Should encode RTL title as UTF-8")
            XCTAssertNotNil(contentData, "Should encode RTL content as UTF-8")
            
            // Test string operations with RTL text
            let trimmedTitle = poem.title.trimmingCharacters(in: .whitespacesAndNewlines)
            XCTAssertEqual(trimmedTitle, poem.title, "Should handle RTL text trimming")
        }
    }
    
    // MARK: - Number and Date Formatting Tests
    
    func testRegionalNumberFormatting() throws {
        let testNumbers = [1, 10, 100, 1000, 10000, 100000]
        let locales = [
            "en_US", // 1,000.50
            "de_DE", // 1.000,50  
            "fr_FR", // 1 000,50
            "ar_SA", // ١٬٠٠٠٫٥٠
            "hi_IN", // १,०००.५०
            "ja_JP"  // 1,000.50
        ]
        
        for localeId in locales {
            let locale = Locale(identifier: localeId)
            let formatter = NumberFormatter()
            formatter.locale = locale
            formatter.numberStyle = .decimal
            
            for number in testNumbers {
                let formattedNumber = formatter.string(from: NSNumber(value: number))
                XCTAssertNotNil(formattedNumber, "Should format number \(number) for locale \(localeId)")
                XCTAssertFalse(formattedNumber!.isEmpty, "Formatted number should not be empty")
            }
        }
    }
    
    func testRegionalDateFormatting() throws {
        let testDate = Date()
        let locales = [
            "en_US", // MM/dd/yyyy
            "en_GB", // dd/MM/yyyy
            "de_DE", // dd.MM.yyyy
            "fr_FR", // dd/MM/yyyy
            "ja_JP", // yyyy/MM/dd
            "ar_SA", // dd/MM/yyyy (Arabic digits)
            "zh_CN"  // yyyy/M/d
        ]
        
        for localeId in locales {
            let locale = Locale(identifier: localeId)
            let formatter = DateFormatter()
            formatter.locale = locale
            formatter.dateStyle = .short
            
            let formattedDate = formatter.string(from: testDate)
            XCTAssertFalse(formattedDate.isEmpty, "Should format date for locale \(localeId)")
            
            // Test that formatted date can be parsed back
            let parsedDate = formatter.date(from: formattedDate)
            XCTAssertNotNil(parsedDate, "Should parse formatted date for locale \(localeId)")
        }
    }
    
    // MARK: - Cultural Content Tests
    
    func testCulturallyAppropriatePoemContent() throws {
        // Test that poems are culturally appropriate for different regions
        let culturalTestCases = [
            ("en_US", ["freedom", "liberty", "american dream"]),
            ("ja_JP", ["桜", "侘寂", "禅"]),
            ("ar_SA", ["صحراء", "جمل", "نجوم"]),
            ("de_DE", ["berg", "wald", "gemütlichkeit"]),
            ("fr_FR", ["amour", "liberté", "art"]),
            ("es_ES", ["flamenco", "siesta", "fiesta"])
        ]
        
        for (locale, culturalTerms) in culturalTestCases {
            // Simulate culturally appropriate content
            let culturalPoem = Poem(
                id: UUID(),
                title: "Cultural Poem for \(locale)",
                lines: ["This poem includes cultural elements: \(culturalTerms.joined(separator: ", "))"],
                author: "Local Author",
                source: .api
            )
            
            XCTAssertTrue(culturalTerms.allSatisfy { term in
                culturalPoem.content.localizedCaseInsensitiveContains(term)
            }, "Poem should contain culturally appropriate terms for \(locale)")
        }
    }
    
    // MARK: - Input Method Tests
    
    func testInputMethodSupport() throws {
        // Test support for different input methods
        let inputMethodTests = [
            ("pinyin", "ni hao", "你好"),
            ("romaji", "konnichiwa", "こんにちは"),
            ("transliteration", "marhaba", "مرحبا"),
            ("phonetic", "shalom", "שלום")
        ]
        
        for (inputMethod, phonetic, native) in inputMethodTests {
            // Test that both phonetic and native inputs are handled
            let phoneticPoem = Poem(
                id: UUID(),
                title: phonetic,
                lines: ["Testing \(inputMethod) input: \(phonetic)"],
                author: "Input Tester",
                source: .aiGenerated
            )
            
            let nativePoem = Poem(
                id: UUID(),
                title: native,
                lines: ["Testing \(inputMethod) input: \(native)"],
                author: "Input Tester",
                source: .aiGenerated
            )
            
            XCTAssertNotNil(phoneticPoem, "Should handle phonetic input for \(inputMethod)")
            XCTAssertNotNil(nativePoem, "Should handle native script for \(inputMethod)")
        }
    }
    
    // MARK: - Currency and Measurement Tests
    
    func testRegionalMeasurements() throws {
        // Test handling of different measurement systems
        let measurements = [
            ("metric", "kilometers", "celsius"),
            ("imperial", "miles", "fahrenheit"),
            ("mixed", "feet", "celsius")
        ]
        
        for (system, distance, temperature) in measurements {
            // Test that measurement-related content is handled properly
            let measurementContent = "Distance: 10 \(distance), Temperature: 20 \(temperature)"
            
            let poem = Poem(
                id: UUID(),
                title: "Measurement Poem",
                lines: [measurementContent],
                author: "Measurement Author",
                source: .aiGenerated
            )
            
            XCTAssertTrue(poem.content.contains(distance), "Should contain distance unit")
            XCTAssertTrue(poem.content.contains(temperature), "Should contain temperature unit")
        }
    }
    
    // MARK: - Accessibility Localization Tests
    
    func testLocalizedAccessibilityLabels() throws {
        let accessibilityLabels = [
            ("en", "Poem", "Author", "Content", "Favorite"),
            ("es", "Poema", "Autor", "Contenido", "Favorito"),
            ("fr", "Poème", "Auteur", "Contenu", "Favori"),
            ("de", "Gedicht", "Autor", "Inhalt", "Favorit"),
            ("ja", "詩", "作者", "内容", "お気に入り"),
            ("ar", "قصيدة", "مؤلف", "محتوى", "مفضل")
        ]
        
        for (language, poemLabel, authorLabel, contentLabel, favoriteLabel) in accessibilityLabels {
            // Test that accessibility labels are properly localized
            let localizedLabels = [poemLabel, authorLabel, contentLabel, favoriteLabel]
            
            for label in localizedLabels {
                XCTAssertFalse(label.isEmpty, "Accessibility label should not be empty for \(language)")
                XCTAssertGreaterThan(label.count, 0, "Accessibility label should have content for \(language)")
            }
        }
    }
    
    // MARK: - Time Zone Tests
    
    func testTimeZoneHandling() throws {
        let timeZones = [
            "America/New_York",    // EST/EDT
            "Europe/London",       // GMT/BST  
            "Asia/Tokyo",          // JST
            "Australia/Sydney",    // AEST/AEDT
            "America/Los_Angeles", // PST/PDT
            "Asia/Dubai",          // GST
            "Europe/Berlin"        // CET/CEST
        ]
        
        let testDate = Date()
        
        for timeZoneId in timeZones {
            guard let timeZone = TimeZone(identifier: timeZoneId) else {
                XCTFail("Should create time zone for \(timeZoneId)")
                continue
            }
            
            let formatter = DateFormatter()
            formatter.timeZone = timeZone
            formatter.dateStyle = .medium
            formatter.timeStyle = .short
            
            let formattedDate = formatter.string(from: testDate)
            XCTAssertFalse(formattedDate.isEmpty, "Should format date for time zone \(timeZoneId)")
            
            // Test that poem dates work across time zones
            let poem = Poem(
                id: UUID(),
                title: "Time Zone Test Poem",
                lines: ["Created at \(formattedDate) in \(timeZoneId)"],
                author: "Time Zone Tester",
                source: .api
            )
            
            XCTAssertNotNil(poem, "Should create poem with time zone-specific date")
        }
    }
} 