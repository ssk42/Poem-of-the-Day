//
//  LocalPoemGenerator.swift
//  Poem of the Day
//
//  Created by Claude Code on 2025-12-04.
//

import Foundation

/// Handles local, template-based poem generation when AI is unavailable
struct LocalPoemGenerator {
    
    // MARK: - Public Methods
    
    static func generate(vibe: DailyVibe? = nil, prompt: String? = nil) -> Poem {
        var title: String
        var author = "Local Poet"
        
        AppLogger.shared.info("Generating local fallback poem...", category: .ai)
        AppLogger.shared.debug("Vibe: \(vibe?.displayName ?? "none")", category: .ai)
        AppLogger.shared.debug("Prompt: \(prompt ?? "none")", category: .ai)
        
        // Generate dynamic titles based on vibe and keywords
        if let vibe = vibe {
            // Use vibe-specific keywords for title generation
            let keywords = extractKeywordsFromVibe(vibe)
            title = vibe.generateDynamicTitle(keywords: keywords)
            AppLogger.shared.debug("Generated title from vibe: '\(title)'", category: .ai)
        } else if let prompt = prompt {
            // For custom prompts, extract keywords from the prompt
            let keywords = extractKeywordsFromPrompt(prompt)
            title = keywords.first?.capitalized ?? "Custom Inspiration"
            AppLogger.shared.debug("Generated title from prompt: '\(title)'", category: .ai)
        } else {
            title = "A Simple Poem"
            AppLogger.shared.debug("Using default title: '\(title)'", category: .ai)
        }
        
        // For UI Testing: Append timestamp to ensure unique content on each generation
        if AppConfiguration.Testing.isUITesting {
            let timestamp = Int(Date().timeIntervalSince1970 * 1000)
            title = "\(title) \(timestamp)"
            author = "Test Poet \(timestamp)"
            AppLogger.shared.debug("UI Testing mode: Added timestamp \(timestamp)", category: .ai)
        }
        
        // Generate different poems based on vibe or prompt
        var lines: [String]
        
        if let vibe = vibe {
            AppLogger.shared.debug("Generating vibe-specific lines for: \(vibe.displayName)", category: .ai)
            lines = generateVibeSpecificLines(for: vibe)
        } else if let prompt = prompt {
            AppLogger.shared.debug("Generating prompt-specific lines", category: .ai)
            lines = generatePromptSpecificLines(for: prompt)
        } else {
            AppLogger.shared.debug("Using default poem lines", category: .ai)
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
            AppLogger.shared.debug("UI Testing mode: Added timestamp line to content", category: .ai)
        }
        
        let poem = Poem(
            title: title, 
            lines: lines, 
            author: author, 
            vibe: vibe, 
            source: .localFallback
        )
        
        AppLogger.shared.info("Local poem created: '\(poem.title)'", category: .ai)
        
        return poem
    }
    
    // MARK: - Private Helpers
    
    private static func generateVibeSpecificLines(for vibe: DailyVibe) -> [String] {
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
    
    private static func generatePromptSpecificLines(for prompt: String) -> [String] {
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
    
    /// Extracts keywords from a vibe for title generation
    static func extractKeywordsFromVibe(_ vibe: DailyVibe) -> [String] {
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
    static func extractKeywordsFromPrompt(_ prompt: String) -> [String] {
        // Extract meaningful words (nouns, important adjectives)
        let stopWords = Set(["a", "an", "the", "about", "of", "in", "on", "at", "to", "for", "with", "by", "from", "write", "poem", "poetry"])
        let words = prompt.lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty && $0.count > 2 && !stopWords.contains($0) }
        
        // Return first 3 meaningful words
        return Array(words.prefix(3))
    }
}
