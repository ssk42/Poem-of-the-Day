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
    case quotaExceeded
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
        case .quotaExceeded:
            return "Daily generation limit exceeded"
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
        case .quotaExceeded:
            return "You can generate more poems tomorrow"
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
struct GeneratedPoem: Codable {
    let title: String
    let author: String
    let lines: [String]
    let style: String?
}
#endif

// MARK: - Foundation Models Service

actor PoemGenerationService: PoemGenerationServiceProtocol {
    
    // MARK: - Properties
    
    #if canImport(FoundationModels)
    @available(iOS 26, *)
    private var languageModel: AnyObject? // Will be SystemLanguageModel when available
    @available(iOS 26, *)
    private var modelSession: AnyObject? // Will be LanguageModelSession when available
    @available(iOS 26, *)
    private var adapter: AnyObject? // Will be SystemLanguageModel.Adapter when available
    #endif
    
    private var dailyGenerationCount: Int = 0
    private let maxDailyGenerations = 10
    private let lastResetDate: Date
    private let userDefaults: UserDefaults
    
    // MARK: - Initialization
    
    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        self.lastResetDate = userDefaults.object(forKey: "lastGenerationReset") as? Date ?? Date()
        self.dailyGenerationCount = userDefaults.integer(forKey: "dailyGenerationCount")
        
        // Reset daily count if it's a new day
        if !Calendar.current.isDate(lastResetDate, inSameDayAs: Date()) {
            self.dailyGenerationCount = 0
            userDefaults.set(0, forKey: "dailyGenerationCount")
            userDefaults.set(Date(), forKey: "lastGenerationReset")
        }
        
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
            /*
            do {
                // Try to load a custom poetry adapter if available
                if let poetryAdapter = try? SystemLanguageModel.Adapter(name: "poetry_generation") {
                    self.adapter = poetryAdapter
                    self.languageModel = SystemLanguageModel(adapter: poetryAdapter)
                } else {
                    // Fall back to base system model
                    self.languageModel = SystemLanguageModel()
                }
                
                if let model = languageModel as? SystemLanguageModel {
                    self.modelSession = LanguageModelSession(model: model)
                }
            } catch {
                print("Failed to initialize Foundation Models: \(error)")
                // Model will remain nil, falling back to local generation
            }
            */
        }
        #endif
    }
    
    // MARK: - Public Methods
    
    func generatePoemFromVibe(_ vibeAnalysis: VibeAnalysis) async throws -> Poem {
        do {
            try await checkAvailabilityAndQuota()
            
            let prompt = buildVibePrompt(from: vibeAnalysis)
            
            // Try Foundation Models if available (iOS 26+)
            if await isFoundationModelsAvailable() {
                #if canImport(FoundationModels)
                if #available(iOS 26, *) {
                    // Future implementation
                    // let generatedPoem = try await generateWithFoundationModels(prompt: prompt)
                    // let poem = convertToPoemModel(generatedPoem, vibe: vibeAnalysis.vibe)
                    // await incrementDailyCount()
                    // return poem
                }
                #endif
            }
            
            // Fall back to local generation for now
            throw PoemGenerationError.modelUnavailable
            
        } catch PoemGenerationError.deviceNotSupported {
            // Fallback to local generation if AI is not supported
            return generateLocalPoem(vibe: vibeAnalysis.vibe)
        } catch {
            // For now, always fall back to local generation since Foundation Models isn't available yet
            return generateLocalPoem(vibe: vibeAnalysis.vibe)
        }
    }
    
    func generatePoemWithCustomPrompt(_ prompt: String) async throws -> Poem {
        do {
            try await checkAvailabilityAndQuota()
            
            guard !prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                throw PoemGenerationError.invalidPrompt
            }
            
            let enhancedPrompt = enhanceCustomPrompt(prompt)
            
            // Try Foundation Models if available (iOS 26+)
            if await isFoundationModelsAvailable() {
                #if canImport(FoundationModels)
                if #available(iOS 26, *) {
                    // Future implementation
                    // let generatedPoem = try await generateWithFoundationModels(prompt: enhancedPrompt)
                    // let poem = convertToPoemModel(generatedPoem, vibe: nil)
                    // await incrementDailyCount()
                    // return poem
                }
                #endif
            }
            
            // Fall back to local generation for now
            throw PoemGenerationError.modelUnavailable
            
        } catch PoemGenerationError.deviceNotSupported {
            // Fallback to local generation for custom prompts when AI is not supported
            return generateLocalPoem(prompt: prompt)
        } catch {
            // For now, always fall back to local generation since Foundation Models isn't available yet
            return generateLocalPoem(prompt: prompt)
        }
    }
    
    func isAvailable() async -> Bool {
        // Check if Foundation Models is available
        return await isFoundationModelsAvailable()
    }
    
    // MARK: - Foundation Models Availability Check
    
    private func isFoundationModelsAvailable() async -> Bool {
        #if canImport(FoundationModels)
        if #available(iOS 26, *) {
            // Use proper SystemLanguageModel availability checking
            do {
                // Check if SystemLanguageModel is available on this device
                let isSupported = await SystemLanguageModel.isSupported
                
                // Additional capability checks
                if isSupported {
                    // Check if text generation is supported
                    let capabilities = await SystemLanguageModel.capabilities
                    return capabilities.contains(.textGeneration)
                }
                
                return false
            } catch {
                // If availability check fails, assume not available
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
        /*
        guard let session = modelSession as? LanguageModelSession else {
            throw PoemGenerationError.modelUnavailable
        }
        
        do {
            // Use guided generation for structured poem output
            let response = try await session.respond(to: prompt, generatingResponseOf: GeneratedPoem.self)
            return response
        } catch {
            // If guided generation fails, try regular text generation and parse
            let textResponse = try await session.respond(to: prompt)
            return try parseTextToPoem(textResponse)
        }
        */
        throw PoemGenerationError.modelUnavailable
    }
    #endif
    
    // MARK: - Private Methods
    
    private func checkAvailabilityAndQuota() async throws {
        // For now, since Foundation Models isn't available, we'll allow local generation
        // In the future: guard await isAvailable() else { throw PoemGenerationError.deviceNotSupported }
        
        guard dailyGenerationCount < maxDailyGenerations else {
            throw PoemGenerationError.quotaExceeded
        }
    }
    
    private func buildVibePrompt(from vibeAnalysis: VibeAnalysis) -> String {
        let basePrompt = vibeAnalysis.vibe.poemPrompt
        let context = buildContextFromAnalysis(vibeAnalysis)
        
        return """
        You are a talented poet creating original poetry. \(basePrompt)
        
        Context: Today's news suggests \(context).
        
        Create a poem that captures this \(vibeAnalysis.vibe.displayName.lowercased()) feeling while being:
        - Original and creative
        - Appropriate for all audiences
        - 12-20 lines long
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
        - 12-20 lines long
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
        let lines = text.components(separatedBy: .newlines)
        
        var title = "Generated Poem"
        var author = "AI Poet"
        var poemLines: [String] = []
        var style: String?
        
        var parsingPoem = false
        
        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
            
            if trimmedLine.hasPrefix("Title:") {
                title = String(trimmedLine.dropFirst(6)).trimmingCharacters(in: .whitespacesAndNewlines)
            } else if trimmedLine.hasPrefix("Author:") {
                author = String(trimmedLine.dropFirst(7)).trimmingCharacters(in: .whitespacesAndNewlines)
            } else if trimmedLine.hasPrefix("Style:") {
                style = String(trimmedLine.dropFirst(6)).trimmingCharacters(in: .whitespacesAndNewlines)
            } else if !trimmedLine.isEmpty && !trimmedLine.hasPrefix("Title:") && !trimmedLine.hasPrefix("Author:") && !trimmedLine.hasPrefix("Style:") {
                parsingPoem = true
            }
            
            if parsingPoem && !trimmedLine.isEmpty {
                poemLines.append(trimmedLine)
            }
        }
        
        if poemLines.isEmpty {
            throw PoemGenerationError.generationFailed
        }
        
        return GeneratedPoem(
            title: title,
            author: author,
            lines: poemLines,
            style: style
        )
    }
    
    @available(iOS 26, *)
    private func convertToPoemModel(_ generatedPoem: GeneratedPoem, vibe: DailyVibe?) -> Poem {
        return Poem(
            title: generatedPoem.title,
            lines: generatedPoem.lines,
            author: generatedPoem.author,
            vibe: vibe
        )
    }
    #endif
    
    private func incrementDailyCount() async {
        dailyGenerationCount += 1
        userDefaults.set(dailyGenerationCount, forKey: "dailyGenerationCount")
    }
    
    private func generateLocalPoem(vibe: DailyVibe? = nil, prompt: String? = nil) -> Poem {
        let title = vibe?.displayName ?? (prompt != nil ? "Custom Inspiration" : "A Simple Poem")
        let author = "Local Poet"
        
        // Generate different poems based on vibe or prompt
        let lines: [String]
        
        if let vibe = vibe {
            lines = generateVibeSpecificLines(for: vibe)
        } else if let prompt = prompt {
            lines = generatePromptSpecificLines(for: prompt)
        } else {
            lines = [
                "When AI sleeps, and models rest,",
                "A local verse is put to the test.",
                "No complex thoughts, no grand design,",
                "Just simple words, in a simple line.",
                "A poem born from code, not art,",
                "A humble offering, from the heart."
            ]
        }
        
        return Poem(title: title, lines: lines, author: author, vibe: vibe)
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
}
