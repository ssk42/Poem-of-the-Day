//
//  PoemGenerationService.swift
//  Poem of the Day
//
//  Created by Claude Code on 2025-06-19.
//

import Foundation

// Apple FoundationModels framework for iOS 26+
// Uses on-device large language model for text generation
#if canImport(FoundationModels)
import FoundationModels
#endif

// MARK: - Errors

enum PoemGenerationError: Error, LocalizedError {
    case modelUnavailable
    case generationFailed
    case invalidPrompt
    case deviceNotSupported
    case contentFiltered
    case networkRequired
    case systemResourcesUnavailable
    case adaptationFailed
    
    var errorDescription: String? {
        switch self {
        case .modelUnavailable:
            return "AI model is currently unavailable"
        case .generationFailed:
            return "Failed to generate poem"
        case .invalidPrompt:
            return "Invalid prompt provided"
        case .deviceNotSupported:
            return "Device does not support AI poem generation"
        case .contentFiltered:
            return "Content was filtered for safety"
        case .networkRequired:
            return "Network connection required for AI features"
        case .systemResourcesUnavailable:
            return "System resources unavailable"
        case .adaptationFailed:
            return "Failed to adapt model for poem generation"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .modelUnavailable:
            return "Please try again later"
        case .deviceNotSupported:
            return "AI poem generation requires a supported device with Apple Intelligence"
        case .networkRequired:
            return "Connect to the internet to use AI features"
        default:
            return "Please try again"
        }
    }
}

// MARK: - Guided Generation Structure (Future API)

#if canImport(FoundationModels)
// Define the structure for guided poem generation when Foundation Models is available
@available(iOS 26, *)
@Generable(description: "A generated poem with title, author, lines, and style")
struct GeneratedPoem: Codable {
    @Guide(description: "The title of the poem")
    let title: String
    
    @Guide(description: "The author of the poem (use 'AI Poet')")
    let author: String
    
    @Guide(description: "Individual lines of the poem", .count(12...20))
    let lines: [String]
    
    @Guide(description: "The style of the poem (e.g., 'free verse', 'sonnet', 'haiku')")
    let style: String?
}
#endif

// MARK: - Foundation Models Service

actor PoemGenerationService: PoemGenerationServiceProtocol {
    
    // MARK: - Properties
    
    #if canImport(FoundationModels)
    // Store as AnyObject to avoid @available on stored properties
    private var languageModel: AnyObject? // Will be SystemLanguageModel when available
    private var modelSession: AnyObject? // Will be LanguageModelSession when available
    private var adapter: Any? // Will be SystemLanguageModel.Adapter when available (struct, so use Any instead of AnyObject)
    #endif
    
    // MARK: - Initialization
    
    init() {
        Task {
            await initializeFoundationModel()
        }
    }
    
    // MARK: - Foundation Models Setup
    
    private func initializeFoundationModel() async {
        #if canImport(FoundationModels)
        if #available(iOS 26, *) {
            // Future implementation when Foundation Models API is available
            // This will be uncommented when the actual APIs are available
            
            // Try to load a custom poetry adapter if available
            do {
                let poetryAdapter = try SystemLanguageModel.Adapter(name: "poetry_generation")
                self.adapter = poetryAdapter
                self.languageModel = SystemLanguageModel(adapter: poetryAdapter)
            } catch {
                // Fall back to base system model
                self.languageModel = SystemLanguageModel()
            }
            
            if let model = languageModel as? SystemLanguageModel {
                self.modelSession = LanguageModelSession(model: model)
            }
            
        }
        #endif
    }
    
    // MARK: - Public Methods
    
    func generatePoemFromVibe(_ vibeAnalysis: VibeAnalysis) async throws -> Poem {
        // Check for mock error
        if AppConfiguration.Testing.shouldMockAIError {
            throw PoemGenerationError.generationFailed
        }
        
        print("🎨 PoemGenerationService: Generating poem for vibe: \(vibeAnalysis.vibe.displayName)")
        print("   Vibe details: \(vibeAnalysis.vibe.description)")
        print("   Confidence: \(vibeAnalysis.confidence)")
        
        do {
            let prompt = buildVibePrompt(from: vibeAnalysis)
            print("📝 Built prompt (\(prompt.count) chars)")
            print("   First 200 chars: \(String(prompt.prefix(200)))")
        
            // Check for mock responses (UI Testing)
            if AppConfiguration.Testing.shouldMockAIResponses {
                print("🧪 Returning mock response for UI testing")
                let mockPoem = generateLocalPoem(vibe: vibeAnalysis.vibe)
                print("✅ Mock poem created:")
                print("   Title: \(mockPoem.title)")
                print("   Content length: \(mockPoem.content.count)")
                return mockPoem
            }
            
            // Try Foundation Models if available (iOS 18+)
            let isAvailable = await isFoundationModelsAvailable()
            print("🔍 Foundation Models available: \(isAvailable)")
            
            if isAvailable {
                #if canImport(FoundationModels)
                if #available(iOS 26, *) {
                    print("🚀 Attempting AI generation with Foundation Models...")
                    let generatedPoem = try await generateWithFoundationModels(prompt: prompt)
                    print("✅ Foundation Models returned poem:")
                    print("   Title: \(generatedPoem.title)")
                    print("   Lines: \(generatedPoem.lines.count)")
                    
                    let poem = convertToPoemModel(generatedPoem, vibeAnalysis: vibeAnalysis)
                    print("✅ Successfully converted to Poem model!")
                    print("   Final title: \(poem.title)")
                    print("   Final content length: \(poem.content.count)")
                    print("   Vibe: \(poem.vibe?.displayName ?? "none")")
                    return poem
                }
                #endif
            }
            
            // Fall back to local generation for now
            print("⚠️ Foundation Models not available, throwing modelUnavailable error")
            throw PoemGenerationError.modelUnavailable
            
        } catch PoemGenerationError.deviceNotSupported {
            print("❌ Device not supported, generating local fallback poem")
            let fallbackPoem = generateLocalPoem(vibe: vibeAnalysis.vibe)
            print("✅ Fallback poem created:")
            print("   Title: \(fallbackPoem.title)")
            print("   Content length: \(fallbackPoem.content.count)")
            print("   Source: \(fallbackPoem.source?.rawValue ?? "unknown")")
            return fallbackPoem
        } catch PoemGenerationError.modelUnavailable {
            print("❌ Model unavailable, generating local fallback poem")
            let fallbackPoem = generateLocalPoem(vibe: vibeAnalysis.vibe)
            print("✅ Fallback poem created:")
            print("   Title: \(fallbackPoem.title)")
            print("   Content length: \(fallbackPoem.content.count)")
            print("   Source: \(fallbackPoem.source?.rawValue ?? "unknown")")
            return fallbackPoem
        } catch {
            print("❌ Unexpected error: \(error), generating local fallback poem")
            let fallbackPoem = generateLocalPoem(vibe: vibeAnalysis.vibe)
            print("✅ Fallback poem created:")
            print("   Title: \(fallbackPoem.title)")
            print("   Content length: \(fallbackPoem.content.count)")
            print("   Source: \(fallbackPoem.source?.rawValue ?? "unknown")")
            return fallbackPoem
        }
    }
    
    func generatePoemWithCustomPrompt(_ prompt: String) async throws -> Poem {
        // Check for mock error
        if AppConfiguration.Testing.shouldMockAIError {
            throw PoemGenerationError.generationFailed
        }
        
        guard !prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw PoemGenerationError.invalidPrompt
        }
        
        let enhancedPrompt = enhanceCustomPrompt(prompt)
        
        // Check for mock responses (UI Testing)
        if AppConfiguration.Testing.shouldMockAIResponses {
            return generateLocalPoem(prompt: prompt)
        }
        
        // Try Foundation Models if available (iOS 18+)
        if await isFoundationModelsAvailable() {
            #if canImport(FoundationModels)
            if #available(iOS 26, *) {
                // Future implementation
                let generatedPoem = try await generateWithFoundationModels(prompt: enhancedPrompt)
                
                // For custom prompts, extract keywords from prompt for dynamic title
                let keywords = extractKeywordsFromPrompt(prompt)
                let dynamicTitle = keywords.first?.capitalized ?? generatedPoem.title
                
                let poem = Poem(
                    title: dynamicTitle,
                    lines: generatedPoem.lines,
                    author: generatedPoem.author,
                    vibe: nil,
                    source: .aiGenerated
                )
                return poem
            }
            #endif
        }
        
        // Fall back to local generation for now
        throw PoemGenerationError.modelUnavailable
    }
    
    func isAvailable() async -> Bool {
        // In UI tests, respect the environment variable
        if AppConfiguration.Testing.isUITesting {
            return AppConfiguration.Testing.isAIAvailable
        }
        
        // Check if Foundation Models is available
        return await isFoundationModelsAvailable()
    }
    
    // MARK: - Foundation Models Availability Check
    
    private func isFoundationModelsAvailable() async -> Bool {
        #if canImport(FoundationModels)
        if #available(iOS 26, *) {
            // Check if SystemLanguageModel is available on this device
            let model = SystemLanguageModel.default
            
            switch model.availability {
            case .available:
                return true
            case .unavailable:
                return false
            }
        }
        #endif
        return false
    }
    
    // MARK: - Future Foundation Models Generation
    
    #if canImport(FoundationModels)
    @available(iOS 26, *)
    private func generateWithFoundationModels(prompt: String) async throws -> GeneratedPoem {
        // Future implementation when APIs are available
        
        guard let session = modelSession as? LanguageModelSession else {
            print("❌ Model session is not available")
            throw PoemGenerationError.modelUnavailable
        }
        
        print("🚀 Starting poem generation with Foundation Models")
        print("📝 Prompt length: \(prompt.count) characters")
        
        do {
            // Use guided generation for structured poem output
            print("🎯 Attempting guided generation with GeneratedPoem type...")
            let response = try await session.respond(to: prompt, generating: GeneratedPoem.self)
            let generatedPoem = response.content
            
            // Validate that we got meaningful content
            guard !generatedPoem.title.isEmpty,
                  !generatedPoem.author.isEmpty,
                  !generatedPoem.lines.isEmpty else {
                print("⚠️ Generated poem has empty fields")
                print("  - Title empty: \(generatedPoem.title.isEmpty)")
                print("  - Author empty: \(generatedPoem.author.isEmpty)")
                print("  - Lines empty: \(generatedPoem.lines.isEmpty)")
                throw PoemGenerationError.generationFailed
            }
            
            print("✅ Successfully generated poem via guided generation:")
            print("  - Title: '\(generatedPoem.title)'")
            print("  - Author: \(generatedPoem.author)")
            print("  - Lines: \(generatedPoem.lines.count)")
            print("  - Style: \(generatedPoem.style ?? "none")")
            return generatedPoem
            
        } catch let error as LanguageModelSession.GenerationError {
            print("❌ Guided generation failed with LanguageModelSession.GenerationError")
            print("   Error details: \(error)")
            
            // Try regular text generation and parse as fallback
            do {
                print("🔄 Attempting fallback to regular text generation...")
                let textResponse = try await session.respond(to: prompt)
                let textContent = textResponse.content
                print("📝 Received text response (\(textContent.count) chars)")
                print("📝 First 300 chars: \(String(textContent.prefix(300)))")
                
                let parsed = try parseTextToPoem(textContent)
                print("✅ Successfully parsed text response into poem")
                return parsed
            } catch {
                print("❌ Fallback text generation also failed: \(error)")
                throw PoemGenerationError.generationFailed
            }
            
        } catch {
            print("❌ Unexpected error during guided generation: \(type(of: error)) - \(error)")
            
            // Try regular text generation and parse as fallback
            do {
                print("🔄 Attempting fallback to text generation after unexpected error...")
                let textResponse = try await session.respond(to: prompt)
                let textContent = textResponse.content
                print("📝 Received text response (\(textContent.count) chars)")
                print("📝 First 300 chars: \(String(textContent.prefix(300)))")
                
                let parsed = try parseTextToPoem(textContent)
                print("✅ Successfully parsed text response into poem")
                return parsed
            } catch {
                print("❌ Fallback text generation also failed: \(error)")
                throw PoemGenerationError.generationFailed
            }
        }
    }
    #endif
    
    // MARK: - Private Methods
    
    private func buildVibePrompt(from vibeAnalysis: VibeAnalysis) -> String {
        let basePrompt = vibeAnalysis.vibe.poemPrompt
        let context = buildContextFromAnalysis(vibeAnalysis)
        
        return """
        You are a talented poet creating original poetry. \(basePrompt)
        
        Context: Today's news suggests \(context).
        
        Create a poem that captures this \(vibeAnalysis.vibe.displayName.lowercased()) feeling while being:
        - Original and creative
        - Appropriate for all audiences
        - Emotionally resonant
        - Well-structured with clear rhythm
        
        The poem should have:
        - A compelling title
        - Your name as "AI Poet" for the author
        - Individual lines of poetry (not paragraphs)
        - A style description (e.g., "free verse", "sonnet", "haiku")
        """
    }
    
    private func buildContextFromAnalysis(_ analysis: VibeAnalysis) -> String {
        let sentimentDesc = describeSentiment(analysis.sentiment)
        let keywords = analysis.keywords.prefix(3).joined(separator: ", ")
        
        return "a \(analysis.vibe.displayName.lowercased()) atmosphere with \(sentimentDesc). Key themes include: \(keywords)"
    }
    
    private func describeSentiment(_ sentiment: SentimentScore) -> String {
        switch (sentiment.positivity, sentiment.energy) {
        case (0.7..., 0.7...):
            return "high positivity and energy"
        case (0.7..., _):
            return "positive but calm energy"
        case (_, 0.7...):
            return "high energy with mixed emotions"
        case (...0.3, _):
            return "challenging but thoughtful themes"
        default:
            return "balanced emotional tones"
        }
    }
    
    private func enhanceCustomPrompt(_ prompt: String) -> String {
        return """
        You are a talented poet. Write a beautiful poem based on this request: "\(prompt)"
        
        Please ensure the poem is:
        - Original and creative
        - Appropriate for all audiences
        - Well-structured with clear rhythm
        - Emotionally engaging
        
        The poem should have:
        - A compelling title
        - Your name as "AI Poet" for the author
        - Individual lines of poetry (not paragraphs)
        - A style description (e.g., "free verse", "sonnet", "haiku")
        """
    }
    
    #if canImport(FoundationModels)
    @available(iOS 26, *)
    private func parseTextToPoem(_ text: String) throws -> GeneratedPoem {
        var processedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        
        print("📥 Raw text to parse (first 200 chars): \(String(processedText.prefix(200)))")
        
        // Handle markdown code blocks (```json ... ```)
        if processedText.hasPrefix("```") {
            print("🔍 Detected markdown code block, extracting JSON...")
            
            // Remove the opening ```json or ``` and closing ```
            var lines = processedText.components(separatedBy: .newlines)
            
            // Remove first line if it's a code fence
            if lines.first?.hasPrefix("```") == true {
                lines.removeFirst()
            }
            
            // Remove last line if it's a code fence
            if lines.last?.trimmingCharacters(in: .whitespacesAndNewlines) == "```" {
                lines.removeLast()
            }
            
            processedText = lines.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
            print("📝 Extracted content (first 200 chars): \(String(processedText.prefix(200)))")
        }
        
        // Try to parse as JSON if it looks like JSON
        if processedText.hasPrefix("{") {
            print("🔍 Attempting JSON parsing...")
            if let jsonData = processedText.data(using: .utf8) {
                do {
                    let decoded = try JSONDecoder().decode(GeneratedPoem.self, from: jsonData)
                    print("✅ Successfully decoded JSON into GeneratedPoem")
                    print("  - Title: \(decoded.title)")
                    print("  - Lines count: \(decoded.lines.count)")
                    return decoded
                } catch {
                    print("❌ JSON decoding failed: \(error)")
                    // Continue to text parsing fallback
                }
            }
        }
        
        print("🔄 Falling back to text parsing...")
        
        // Fall back to text parsing
        let lines = processedText.components(separatedBy: .newlines)
        
        var title = "Generated Poem"
        var author = "AI Poet"
        var poemLines: [String] = []
        var style: String?
        
        var parsingPoem = false
        var foundMetadata = false
        
        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
            
            // Skip empty lines before the poem starts
            if !parsingPoem && trimmedLine.isEmpty {
                continue
            }
            
            // Check for metadata fields
            if trimmedLine.hasPrefix("Title:") {
                title = String(trimmedLine.dropFirst(6)).trimmingCharacters(in: .whitespacesAndNewlines)
                foundMetadata = true
            } else if trimmedLine.hasPrefix("Author:") {
                author = String(trimmedLine.dropFirst(7)).trimmingCharacters(in: .whitespacesAndNewlines)
                foundMetadata = true
            } else if trimmedLine.hasPrefix("Style:") {
                style = String(trimmedLine.dropFirst(6)).trimmingCharacters(in: .whitespacesAndNewlines)
                foundMetadata = true
            } else if !trimmedLine.isEmpty {
                // Once we hit non-metadata content, start collecting poem lines
                if foundMetadata || !parsingPoem {
                    parsingPoem = true
                }
                
                // Add non-empty lines to the poem
                if parsingPoem {
                    poemLines.append(trimmedLine)
                }
            }
        }
        
        // If we didn't find metadata and have content, treat all non-empty lines as the poem
        if !foundMetadata && poemLines.isEmpty {
            poemLines = lines
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
        }
        
        if poemLines.isEmpty {
            print("❌ No poem lines found after parsing")
            throw PoemGenerationError.generationFailed
        }
        
        print("✅ Successfully parsed poem with \(poemLines.count) lines")
        
        return GeneratedPoem(
            title: title,
            author: author,
            lines: poemLines,
            style: style
        )
    }
    
    @available(iOS 26, *) 
    private func convertToPoemModel(_ generatedPoem: GeneratedPoem, vibeAnalysis: VibeAnalysis) -> Poem {
        print("🔄 Converting GeneratedPoem to Poem model:")
        print("  - Original Title: \(generatedPoem.title)")
        print("  - Author: \(generatedPoem.author)")
        print("  - Lines count: \(generatedPoem.lines.count)")
        print("  - Style: \(generatedPoem.style ?? "none")")
        print("  - Vibe: \(vibeAnalysis.vibe.displayName)")
        
        // Generate dynamic title using vibe analysis keywords
        let keywords = vibeAnalysis.keywords.isEmpty ? extractKeywordsFromVibe(vibeAnalysis.vibe) : vibeAnalysis.keywords
        let dynamicTitle = vibeAnalysis.vibe.generateDynamicTitle(keywords: keywords)
        
        print("  - Dynamic Title: \(dynamicTitle)")
        
        let poem = Poem(
            title: dynamicTitle,  // Use dynamic title instead of generatedPoem.title
            lines: generatedPoem.lines,
            author: generatedPoem.author,
            vibe: vibeAnalysis.vibe,
            source: .aiGenerated
        )
        
        print("✅ Created Poem with content length: \(poem.content.count) characters")
        print("📄 First 100 chars of content: \(String(poem.content.prefix(100)))")
        
        return poem
    }
    #endif
    
    private func generateLocalPoem(vibe: DailyVibe? = nil, prompt: String? = nil) -> Poem {
        var title: String
        var author = "Local Poet"
        
        print("🏠 Generating local fallback poem...")
        print("   Vibe: \(vibe?.displayName ?? "none")")
        print("   Prompt: \(prompt ?? "none")")
        
        // Generate dynamic titles based on vibe and keywords
        if let vibe = vibe {
            // Use vibe-specific keywords for title generation
            let keywords = extractKeywordsFromVibe(vibe)
            title = vibe.generateDynamicTitle(keywords: keywords)
            print("   Generated title from vibe: '\(title)'")
        } else if let prompt = prompt {
            // For custom prompts, extract keywords from the prompt
            let keywords = extractKeywordsFromPrompt(prompt)
            title = keywords.first?.capitalized ?? "Custom Inspiration"
            print("   Generated title from prompt: '\(title)'")
        } else {
            title = "A Simple Poem"
            print("   Using default title: '\(title)'")
        }
        
        // For UI Testing: Append timestamp to ensure unique content on each generation
        if AppConfiguration.Testing.isUITesting {
            let timestamp = Int(Date().timeIntervalSince1970 * 1000)
            title = "\(title) \(timestamp)"
            author = "Test Poet \(timestamp)"
            print("   UI Testing mode: Added timestamp \(timestamp)")
        }
        
        // Generate different poems based on vibe or prompt
        var lines: [String]
        
        if let vibe = vibe {
            print("   Generating vibe-specific lines for: \(vibe.displayName)")
            lines = generateVibeSpecificLines(for: vibe)
        } else if let prompt = prompt {
            print("   Generating prompt-specific lines")
            lines = generatePromptSpecificLines(for: prompt)
        } else {
            print("   Using default poem lines")
            lines = [
                "When AI sleeps, and models rest,",
                "A local verse is put to the test.",
                "No complex thoughts, no grand design,",
                "Just simple words, in a simple line.",
                "A poem born from code, not art,",
                "A humble offering, from the heart."
            ]
        }
        
        // For UI Testing: Make content unique by adding a timestamp comment to the last line
        if AppConfiguration.Testing.isUITesting, !lines.isEmpty {
            let timestamp = Int(Date().timeIntervalSince1970 * 1000)
            // Append a subtle timestamp to make content unique for UI tests
            lines.append("") // Empty line for separation
            lines.append("(Generated at \(timestamp))")
            print("   UI Testing mode: Added timestamp line to content")
        }
        
        let poem = Poem(
            title: title, 
            lines: lines, 
            author: author, 
            vibe: vibe, 
            source: .localFallback
        )
        
        print("✅ Local poem created:")
        print("   Title: '\(poem.title)'")
        print("   Author: \(poem.author ?? "Unknown")")
        print("   Content length: \(poem.content.count) chars")
        print("   Vibe: \(poem.vibe?.displayName ?? "none")")
        print("   Source: \(poem.source?.rawValue ?? "unknown")")
        print("   First 100 chars: \(String(poem.content.prefix(100)))")
        
        return poem
    }
    
    private func generateVibeSpecificLines(for vibe: DailyVibe) -> [String] {
        switch vibe {
        case .hopeful:
            return [
                "Dawn breaks with gentle, golden light,",
                "Chasing shadows from the night.",
                "Hope rises like the morning sun,",
                "A new day's journey has begun.",
                "With every breath, a chance to grow,",
                "To plant the seeds of what we know.",
                "Tomorrow holds what dreams may bring,",
                "In hope's embrace, our hearts take wing."
            ]
        case .contemplative:
            return [
                "In quiet moments, thoughts take flight,",
                "Through corridors of fading light.",
                "Questions linger in the air,",
                "Of life and love and what we share.",
                "Reflection pools in stillness deep,",
                "Where memories and wisdom sleep.",
                "In contemplation's gentle space,",
                "We find the truth in time's embrace."
            ]
        case .energetic:
            return [
                "Electric currents through the air,",
                "Energy dancing everywhere!",
                "Hearts beat fast with life's refrain,",
                "Joy and movement break each chain.",
                "Forward motion, spirits high,",
                "Reaching upward to the sky.",
                "In this moment, fully alive,",
                "Energy helps our souls to thrive!"
            ]
        case .peaceful:
            return [
                "Stillness settles like morning dew,",
                "On petals fresh and skies so blue.",
                "Peace descends with gentle grace,",
                "Finding rest in this quiet space.",
                "Breathe in calm, breathe out the day,",
                "Let worries slowly drift away.",
                "In tranquil moments, spirits mend,",
                "On peace, our hearts can now depend."
            ]
        case .melancholic:
            return [
                "Autumn leaves drift slowly down,",
                "In shades of amber, gold, and brown.",
                "Bittersweet the memories flow,",
                "Of seasons past and long ago.",
                "Beauty found in gentle sorrow,",
                "Yesterday fades to meet tomorrow.",
                "In melancholy's tender embrace,",
                "We find both sadness and sweet grace."
            ]
        case .inspiring:
            return [
                "Rise up, spirit, break the chains,",
                "Let courage flow through all your veins.",
                "Dreams await your bold embrace,",
                "Step forward with determined grace.",
                "Mountains move for those who dare,",
                "To reach beyond what seems unfair.",
                "In inspiration's mighty call,",
                "Stand tall, stand proud, and give your all."
            ]
        case .uncertain:
            return [
                "Crossroads stretch in every way,",
                "Unclear which path to take today.",
                "In uncertainty's misty veil,",
                "We write tomorrow's unknown tale.",
                "Questions linger, answers hide,",
                "But wisdom walks here by our side.",
                "Through clouds of doubt, one truth rings clear:",
                "Each step we take conquers our fear."
            ]
        case .celebratory:
            return [
                "Raise your voice and sing with joy,",
                "Let celebration employ",
                "Every reason to be glad,",
                "For all the good things that we've had.",
                "Dance beneath the starlit sky,",
                "Let happiness and spirits fly.",
                "In moments bright and filled with cheer,",
                "Celebrate what we hold dear!"
            ]
        case .reflective:
            return [
                "Mirror of the soul looks deep,",
                "Into places where we keep",
                "Lessons learned and wisdom earned,",
                "From every bridge that we have burned.",
                "Reflection shows us who we are,",
                "How close we've come, how very far.",
                "In looking back, we clearly see",
                "The path that led to who we'll be."
            ]
        case .determined:
            return [
                "Steel resolve and iron will,",
                "Forward march up every hill.",
                "Determination's steady flame",
                "Burns bright through loss and burned through shame.",
                "No obstacle can block the way",
                "Of those who choose to seize the day.",
                "With purpose clear and vision true,",
                "There's nothing we cannot push through."
            ]
        case .nostalgic:
            return [
                "Looking back through time's soft haze,",
                "To golden childhood summer days.",
                "Memory's warmth wraps 'round my heart,",
                "Though years and miles keep us apart.",
                "Vintage photos, fading still,",
                "Tell stories that no time can kill.",
                "In nostalgia's gentle embrace,",
                "Yesterday finds a sacred place."
            ]
        case .adventurous:
            return [
                "Beyond horizons, frontiers call,",
                "Adventure waits beyond the wall.",
                "With map in hand and courage strong,",
                "We journey forth where we belong.",
                "Discover worlds both far and near,",
                "Step past the boundaries of our fear.",
                "The quest unfolds with each new day,",
                "Adventure lights the unknown way."
            ]
        case .whimsical:
            return [
                "Dancing fireflies and moonlit dreams,",
                "Nothing's quite the way it seems.",
                "Imagination takes its flight,",
                "Through stard ust and magic light.",
                "Quirky thoughts and playful rhyme,",
                "Step outside of space and time.",
                "In whimsy's wonderful embrace,",
                "We find a most enchanted place."
            ]
        case .urgent:
            return [
                "Time runs short, the hour is here,",
                "Pressing matters drawing near.",
                "Critical choices must be made,",
                "Decisions can't be long delayed.",
                "Urgency propels us on,",
                "Before the precious moment's gone.",
                "Act now with purpose, swift and true,",
                "For time waits not for me or you."
            ]
        case .triumphant:
            return [
                "Victory's sweet and hard-won taste,",
                "Conquering what once we faced.",
                "Triumphant hearts beat strong and free,",
                "Celebrating what we've come to be.",
                "Glory shines in morning's light,",
                "We conquered darkness with our might.",
                "Champions rise above the fray,",
                "Triumphant on this glorious day."
            ]
        case .solemn:
            return [
                "In reverent silence, heads are bowed,",
                "Honoring memories, solemn, proud.",
                "Dignity marks these hallowed grounds,",
                "Where sacred truth in stillness sounds.",
                "With respect we gather here,",
                "For those we hold forever dear.",
                "In solemn moments, hearts aligned,",
                "Great meaning in the quiet we find."
            ]
        case .playful:
            return [
                "Laughter echoes through the air,",
                "Joy and playfulness everywhere!",
                "Dancing, skipping, games at hand,",
                "Fun awaits in wonderland.",
                "Lighthearted moments, merry days,",
                "Finding joy in simple ways.",
                "With playful spirit, hearts run free,",
                "Embracing life's sweet comedy."
            ]
        case .mysterious:
            return [
                "Secrets whisper in the night,",
                "Hidden truths just out of sight.",
                "Mysteries wrapped in shadow's veil,",
                "Enigmas telling cryptic tale.",
                "Unknown paths through foggy maze,",
                "Riddles formed in moonlight's haze.",
                "In mystery's alluring call,",
                "We seek to unravel it all."
            ]
        case .rebellious:
            return [
                "Break the chains and challenge fate,",
                "Defy the rules, don't hesitate.",
                "Revolution's fire burns so bright,",
                "Standing up for what is right.",
                "Rebellious hearts refuse to bow,",
                "Question every why and how.",
                "Freedom calls to those who dare,",
                "To shake the world and show they care."
            ]
        case .compassionate:
            return [
                "Gentle touch and caring heart,",
                "Kindness sets us all apart.",
                "Empathy flows like rivers deep,",
                "Compassion's promises we keep.",
                "Love extends to all we meet,",
                "Making every day complete.",
                "With tender grace and understanding,",
                "We build a world more kind and standing."
            ]
        }
    }
    
    private func generatePromptSpecificLines(for prompt: String) -> [String] {
        // Simple pattern matching for common themes in prompts
        let lowerPrompt = prompt.lowercased()
        
        if lowerPrompt.contains("love") || lowerPrompt.contains("heart") {
            return [
                "Love's gentle whisper fills the air,",
                "A tender touch, a moment rare.",
                "Hearts that beat in perfect time,",
                "Creating poetry and rhyme.",
                "In love's embrace, we find our way,",
                "Through darkest night to brightest day."
            ]
        } else if lowerPrompt.contains("nature") || lowerPrompt.contains("tree") || lowerPrompt.contains("forest") {
            return [
                "Ancient trees with branches wide,",
                "Stand as nature's faithful guide.",
                "Leaves whisper secrets in the breeze,",
                "Stories told by willow trees.",
                "In nature's arms, we find our peace,",
                "Where all our worries gently cease."
            ]
        } else if lowerPrompt.contains("ocean") || lowerPrompt.contains("sea") || lowerPrompt.contains("water") {
            return [
                "Waves roll in with endless grace,",
                "Covering every grain and trace.",
                "Ocean's song, both deep and wide,",
                "Calls to something deep inside.",
                "In waters blue, we see our dreams,",
                "Reflected in the silver streams."
            ]
        } else {
            return [
                "Inspired by your words so true,",
                "This simple verse I write for you.",
                "Though humble lines and basic rhyme,",
                "They capture just a piece of time.",
                "From prompt to poem, thought takes flight,",
                "Creating beauty in the night."
            ]
        }
    }
    
    // MARK: - Title Generation Helpers
    
    /// Extracts keywords from a vibe for title generation
    private func extractKeywordsFromVibe(_ vibe: DailyVibe) -> [String] {
        // Use common thematic words associated with each vibe
        switch vibe {
        case .hopeful: return ["Hope", "Dawn", "Tomorrow"]
        case .contemplative: return ["Thought", "Reflection", "Wisdom"]
        case .energetic: return ["Energy", "Motion", "Surge"]
        case .peaceful: return ["Peace", "Calm", "Serenity"]
        case .melancholic: return ["Memory", "Autumn", "Rain"]
        case .inspiring: return ["Courage", "Rise", "Dreams"]
        case .uncertain: return ["Unknown", "Crossroads", "Journey"]
        case .celebratory: return ["Victory", "Joy", "Celebration"]
        case .reflective: return ["Wisdom", "Memory", "Time"]
        case .determined: return ["Will", "Resolve", "Strength"]
        case .nostalgic: return ["Memory", "Yesterday", "Heritage"]
        case .adventurous: return ["Quest", "Discovery", "Frontier"]
        case .whimsical: return ["Wonder", "Imagination", "Magic"]
        case .urgent: return ["Time", "Crisis", "Now"]
        case .triumphant: return ["Triumph", "Conquest", "Glory"]
        case .solemn: return ["Honor", "Remembrance", "Dignity"]
        case .playful: return ["Joy", "Dance", "Games"]
        case .mysterious: return ["Mystery", "Secrets", "Enigma"]
        case .rebellious: return ["Revolution", "Freedom", "Defiance"]
        case .compassionate: return ["Love", "Kindness", "Heart"]
        }
    }
    
    /// Extracts keywords from a custom prompt for title generation
    private func extractKeywordsFromPrompt(_ prompt: String) -> [String] {
        // Extract meaningful words (nouns, important adjectives)
        let stopWords = Set(["a", "an", "the", "about", "of", "in", "on", "at", "to", "for", "with", "by", "from", "write", "poem", "poetry"])
        let words = prompt.lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty && $0.count > 2 && !stopWords.contains($0) }
        
        // Return first 3 meaningful words
        return Array(words.prefix(3))
    }
}
