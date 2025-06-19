//
//  PoemError.swift
//  Poem of the Day
//
//  Created by Claude Code on 2025-06-19.
//

import Foundation

enum PoemError: LocalizedError, Equatable {
    case networkUnavailable
    case invalidResponse
    case decodingFailed
    case noPoems
    case rateLimited
    case serverError(Int)
    case unsupportedOperation
    case unknownError
    
    var errorDescription: String? {
        switch self {
        case .networkUnavailable:
            return "Network connection unavailable. Please check your internet connection."
        case .invalidResponse:
            return "The server returned an invalid response."
        case .decodingFailed:
            return "Failed to process the poem data."
        case .noPoems:
            return "No poems are currently available."
        case .rateLimited:
            return "Too many requests. Please try again later."
        case .serverError(let code):
            return "Server error (\(code)). Please try again later."
        case .unsupportedOperation:
            return "This feature is not available on your device."
        case .unknownError:
            return "An unexpected error occurred."
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .networkUnavailable:
            return "Check your internet connection and try again."
        case .invalidResponse, .decodingFailed:
            return "This usually resolves itself. Try again in a few moments."
        case .noPoems:
            return "New poems are added regularly. Try again later."
        case .rateLimited:
            return "Wait a few minutes before requesting a new poem."
        case .serverError:
            return "The service may be temporarily unavailable. Try again later."
        case .unsupportedOperation:
            return "AI poem generation requires iOS 18.1 or later with Neural Engine support."
        case .unknownError:
            return "Try restarting the app or contact support if the problem persists."
        }
    }
}