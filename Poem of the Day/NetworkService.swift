//
//  NetworkService.swift
//  Poem of the Day
//
//  Created by Claude Code on 2025-06-19.
//

import Foundation

protocol NetworkServiceProtocol: Sendable {
    func fetchRandomPoem() async throws -> Poem
}

actor NetworkService: NetworkServiceProtocol {
    private let session: URLSession
    private let decoder: JSONDecoder
    
    init(session: URLSession = .shared) {
        self.session = session
        self.decoder = JSONDecoder()
    }
    
    func fetchRandomPoem() async throws -> Poem {
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
            
            let basePoem = firstResponse.toPoem()
            // Create poem with API source
            return Poem(
                id: basePoem.id,
                title: basePoem.title,
                lines: basePoem.content.components(separatedBy: "\n"),
                author: basePoem.author,
                source: .api
            )
            
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