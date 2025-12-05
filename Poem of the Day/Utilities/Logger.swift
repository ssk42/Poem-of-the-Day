//
//  Logger.swift
//  Poem of the Day
//
//  Created by Claude Code on 2025-06-19.
//

import Foundation
import os

/// Centralized logging system for the app
final class AppLogger {
    
    // MARK: - Singleton
    
    static let shared = AppLogger()
    
    // MARK: - Properties
    
    private let logger: Logger
    private let subsystem = Bundle.main.bundleIdentifier ?? "com.stevereitz.poemoftheday"
    
    // MARK: - Categories
    
    enum Category: String, CaseIterable {
        case general = "General"
        case network = "Network"
        case ai = "AI"
        case ui = "UI"
        case repository = "Repository"
        case vibe = "VibeAnalysis"
        case error = "Error"
        case performance = "Performance"
        case telemetry = "Telemetry"
    }
    
    // MARK: - Log Levels
    
    enum Level {
        case debug
        case info
        case warning
        case error
        case fault
    }
    
    // MARK: - Initialization
    
    private init() {
        self.logger = Logger(subsystem: subsystem, category: "App")
    }
    
    // MARK: - Public Methods
    
    func log(_ message: String, 
             level: Level = .info, 
             category: Category = .general, 
             file: String = #file, 
             function: String = #function, 
             line: Int = #line) {
        
        guard AppConfiguration.Debug.enableLogging else { return }
        
        let fileName = URL(fileURLWithPath: file).lastPathComponent
        let formattedMessage = "[\(category.rawValue)] [\(fileName):\(line)] \(function) - \(message)"
        
        switch level {
        case .debug:
            logger.debug("\(formattedMessage, privacy: .public)")
        case .info:
            logger.info("\(formattedMessage, privacy: .public)")
        case .warning:
            logger.warning("\(formattedMessage, privacy: .public)")
        case .error:
            logger.error("\(formattedMessage, privacy: .public)")
        case .fault:
            logger.fault("\(formattedMessage, privacy: .public)")
        }
    }
    
    // MARK: - Convenience Methods
    
    func debug(_ message: String, category: Category = .general, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .debug, category: category, file: file, function: function, line: line)
    }
    
    func info(_ message: String, category: Category = .general, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .info, category: category, file: file, function: function, line: line)
    }
    
    func warning(_ message: String, category: Category = .general, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .warning, category: category, file: file, function: function, line: line)
    }
    
    func error(_ message: String, category: Category = .error, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .error, category: category, file: file, function: function, line: line)
    }
    
    func fault(_ message: String, category: Category = .error, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .fault, category: category, file: file, function: function, line: line)
    }
    
    // MARK: - Performance Logging
    
    func logPerformance<T>(_ operation: String, category: Category = .performance, block: () throws -> T) rethrows -> T {
        let startTime = CFAbsoluteTimeGetCurrent()
        let result = try block()
        let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
        
        log("⏱️ \(operation) completed in \(String(format: "%.3f", timeElapsed))s", 
            level: .info, 
            category: category)
        
        return result
    }
    
    func logAsyncPerformance<T>(_ operation: String, category: Category = .performance, block: () async throws -> T) async rethrows -> T {
        let startTime = CFAbsoluteTimeGetCurrent()
        let result = try await block()
        let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
        
        log("⏱️ \(operation) completed in \(String(format: "%.3f", timeElapsed))s", 
            level: .info, 
            category: category)
        
        return result
    }
}

// MARK: - Global Logger Functions

/// Log debug message
func logDebug(_ message: String, category: AppLogger.Category = .general, file: String = #file, function: String = #function, line: Int = #line) {
    AppLogger.shared.debug(message, category: category, file: file, function: function, line: line)
}

/// Log info message
func logInfo(_ message: String, category: AppLogger.Category = .general, file: String = #file, function: String = #function, line: Int = #line) {
    AppLogger.shared.info(message, category: category, file: file, function: function, line: line)
}

/// Log warning message
func logWarning(_ message: String, category: AppLogger.Category = .general, file: String = #file, function: String = #function, line: Int = #line) {
    AppLogger.shared.warning(message, category: category, file: file, function: function, line: line)
}

/// Log error message
func logError(_ message: String, category: AppLogger.Category = .error, file: String = #file, function: String = #function, line: Int = #line) {
    AppLogger.shared.error(message, category: category, file: file, function: function, line: line)
}