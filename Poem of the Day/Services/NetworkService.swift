//
//  NetworkService.swift
//  Poem of the Day
//
//  Created by Claude Code on 2025-06-19.
//

import Foundation

actor NetworkService: NetworkServiceProtocol {
    private let session: URLSession
    private let decoder: JSONDecoder
    
    init(session: URLSession = .shared) {
        self.session = session
        self.decoder = JSONDecoder()
    }
    
    func fetchRandomPoem() async throws -> Poem {
        // Check for simulated error (for UI testing)
        // Log arguments for debugging
        NSLog("NetworkService: Arguments: \(ProcessInfo.processInfo.arguments)")
        
        if ProcessInfo.processInfo.environment["SIMULATE_NETWORK_ERROR"] == "true" || 
           ProcessInfo.processInfo.arguments.contains("-SimulateNetworkError") {
            NSLog("NetworkService: Simulating network error")
            throw PoemError.networkUnavailable
        }

        NSLog("NetworkService: Fetching random poem")
        guard let url = URL(string: "https://poetrydb.org/random") else {
            throw PoemError.invalidResponse
        }
        
        do {
            let (data, response) = try await session.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw PoemError.invalidResponse
            }
            
            switch httpResponse.statusCode {
            case 200...299:
                break
            case 404:
                throw PoemError.noPoems
            case 429:
                throw PoemError.rateLimited
            case 500...599:
                throw PoemError.serverError(httpResponse.statusCode)
            default:
                throw PoemError.unknownError
            }
            
            let poemResponses = try decoder.decode([PoemResponse].self, from: data)
            
            guard let firstResponse = poemResponses.first else {
                throw PoemError.noPoems
            }
            
            return firstResponse.toPoem()
            
        } catch is DecodingError {
            throw PoemError.decodingFailed
        } catch let error as PoemError {
            throw error
        } catch {
            if error.isNetworkError {
                throw PoemError.networkUnavailable
            } else {
                throw PoemError.unknownError
            }
        }
    }
}

private extension Error {
    var isNetworkError: Bool {
        if let urlError = self as? URLError {
            switch urlError.code {
            case .notConnectedToInternet, .networkConnectionLost, .timedOut:
                return true
            default:
                return false
            }
        }
        return false
    }
}