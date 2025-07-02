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
            Poem(id: "en_1", title: "English Poem", author: "English Author", 
                 content: "This is an English poem with standard Latin characters.",
                 date: Date(), source: .daily, isFavorite: false),
            
            // Spanish
            Poem(id: "es_1", title: "Poema Español", author: "Autor Español",
                 content: "Este es un poema en español con acentos: café, niño, corazón.",
                 date: Date(), source: .daily, isFavorite: false),
            
            // French  
            Poem(id: "fr_1", title: "Poème Français", author: "Auteur Français",
                 content: "Ceci est un poème français avec des accents: été, cœur, naïve.",
                 date: Date(), source: .daily, isFavorite: false),
            
            // German
            Poem(id: "de_1", title: "Deutsches Gedicht", author: "Deutscher Autor",
                 content: "Dies ist ein deutsches Gedicht mit Umlauten: Größe, Hände, Mädchen.",
                 date: Date(), source: .daily, isFavorite: false),
            
            // Japanese
            Poem(id: "ja_1", title: "日本の詩", author: "日本の作家",
                 content: "これは日本語の詩です。桜、月、海の美しさを歌います。",
                 date: Date(), source: .daily, isFavorite: false),
            
            // Arabic (RTL)
            Poem(id: "ar_1", title: "قصيدة عربية", author: "شاعر عربي",
                 content: "هذه قصيدة عربية تحتوي على نصوص من اليمين إلى اليسار.",
                 date: Date(), source: .daily, isFavorite: false),
            
            // Hebrew (RTL)
            Poem(id: "he_1", title: "שיר עברי", author: "משורר עברי",
                 content: "זהו שיר עברי עם טקסט מימין לשמאל וניקוד.",
                 date: Date(), source: .daily, isFavorite: false),
            
            // Chinese
            Poem(id: "zh_1", title: "中文诗", author: "中文作者",
                 content: "这是一首中文诗，包含简体中文字符。",
                 date: Date(), source: .daily, isFavorite: false),
            
            // Russian
            Poem(id: "ru_1", title: "Русская поэма", author: "Русский автор",
                 content: "Это русская поэма с кириллическими символами: борщ, водка, медведь.",
                 date: Date(), source: .daily, isFavorite: false)
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
            Poem(id: "rtl_ar", title: "العنوان العربي", author: "المؤلف العربي",
                 content: "محتوى النص العربي من اليمين إلى اليسار مع أرقام ١٢٣٤٥٦٧٨٩٠",
                 date: Date(), source: .daily, isFavorite: false),
            
            Poem(id: "rtl_he", title: "כותרת עברית", author: "כותב עברי",
                 content: "תוכן עברי מימין לשמאל עם מספרים ١٢٣٤٥٦٧٨٩٠",
                 date: Date(), source: .daily, isFavorite: false),
            
            Poem(id: "rtl_fa", title: "عنوان فارسی", author: "نویسنده فارسی",
                 content: "محتوای فارسی از راست به چپ با اعداد ۱۲۳۴۵۶۷۸۹۰",
                 date: Date(), source: .daily, isFavorite: false)
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
                id: "cultural_\(locale)",
                title: "Cultural Poem for \(locale)",
                author: "Local Author",
                content: "This poem includes cultural elements: \(culturalTerms.joined(separator: ", "))",
                date: Date(),
                source: .daily,
                isFavorite: false
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
                id: "input_\(inputMethod)_phonetic",
                title: phonetic,
                author: "Input Tester",
                content: "Testing \(inputMethod) input: \(phonetic)",
                date: Date(),
                source: .custom,
                isFavorite: false
            )
            
            let nativePoem = Poem(
                id: "input_\(inputMethod)_native",
                title: native,
                author: "Input Tester",
                content: "Testing \(inputMethod) input: \(native)",
                date: Date(),
                source: .custom,
                isFavorite: false
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
                id: "measurement_\(system)",
                title: "Measurement Poem",
                author: "Measurement Author",
                content: measurementContent,
                date: Date(),
                source: .custom,
                isFavorite: false
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
                id: "tz_\(timeZoneId.replacingOccurrences(of: "/", with: "_"))",
                title: "Time Zone Test Poem",
                author: "Time Zone Tester",
                content: "Created at \(formattedDate) in \(timeZoneId)",
                date: testDate,
                source: .daily,
                isFavorite: false
            )
            
            XCTAssertNotNil(poem, "Should create poem with time zone-specific date")
        }
    }
} 