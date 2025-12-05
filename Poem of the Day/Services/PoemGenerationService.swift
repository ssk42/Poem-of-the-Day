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
    
    private let aiGenerator = AIPoemGenerator()
    
    // MARK: - Initialization
    
    init() {}
    
    // MARK: - Public Methods
    
    func generatePoemFromVibe(_ vibeAnalysis: VibeAnalysis) async throws -> Poem {
        // Check for mock error
        if AppConfiguration.Testing.shouldMockAIError {
            throw PoemGenerationError.generationFailed
        }
        
        AppLogger.shared.info("Generating poem for vibe: \(vibeAnalysis.vibe.displayName)", category: .ai)
        AppLogger.shared.debug("Confidence: \(vibeAnalysis.confidence)", category: .ai)
        
        // Check for mock responses (UI Testing)
        if AppConfiguration.Testing.shouldMockAIResponses {
            AppLogger.shared.info("Returning mock response for UI testing", category: .ai)
            return LocalPoemGenerator.generate(vibe: vibeAnalysis.vibe)
        }
        
        // Try AI Generation
        do {
            if await aiGenerator.isAvailable() {
                return try await aiGenerator.generatePoem(from: vibeAnalysis)
            }
        } catch {
            AppLogger.shared.error("AI generation failed: \(error). Falling back to local.", category: .ai)
        }
        
        // Fallback to local generation
        AppLogger.shared.warning("Using local fallback generator", category: .ai)
        return LocalPoemGenerator.generate(vibe: vibeAnalysis.vibe)
    }
    
    func generatePoemWithCustomPrompt(_ prompt: String) async throws -> Poem {
        // Check for mock error
        if AppConfiguration.Testing.shouldMockAIError {
            throw PoemGenerationError.generationFailed
        }
        
        guard !prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw PoemGenerationError.invalidPrompt
        }
        
        // Check for mock responses (UI Testing)
        if AppConfiguration.Testing.shouldMockAIResponses {
            return LocalPoemGenerator.generate(prompt: prompt)
        }
        
        // Try AI Generation
        do {
            if await aiGenerator.isAvailable() {
                return try await aiGenerator.generatePoem(customPrompt: prompt)
            }
        } catch {
            AppLogger.shared.error("AI generation failed: \(error). Falling back to local.", category: .ai)
        }
        
        // Fallback to local generation
        // Note: The original implementation threw an error here instead of falling back for custom prompts,
        // but falling back seems safer if we want to guarantee a result.
        // However, to match original behavior, we might want to throw if AI is unavailable for custom prompts.
        // Let's stick to the original behavior for custom prompts: fail if no AI.
        throw PoemGenerationError.modelUnavailable
    }
    
    func isAvailable() async -> Bool {
        // In UI tests, respect the environment variable
        if AppConfiguration.Testing.isUITesting {
            return AppConfiguration.Testing.isAIAvailable
        }
        
        return await aiGenerator.isAvailable()
    }
}
