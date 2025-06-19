//
//  Logger.swift
//  Poem of the Day
//
//  Created by Claude Code on 2025-06-19.
//

import Foundation
import os.log

/// Centralized logging system for the app
final class AppLogger {
    
    // MARK: - Singleton
    
    static let shared = AppLogger()
    
    // MARK: - Properties
    
    private let osLog: OSLog
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
    }
    
    // MARK: - Log Levels
    
    enum Level {
        case debug
        case info
        case warning
        case error
        case fault
        
        var osLogType: OSLogType {
            switch self {
            case .debug: return .debug
            case .info: return .info
            case .warning: return .default
            case .error: return .error
            case .fault: return .fault
            }
        }
    }
    
    // MARK: - Initialization
    
    private init() {
        self.osLog = OSLog(subsystem: subsystem, category: Category.general.rawValue)
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
        let formattedMessage = "[\(fileName):\(line)] \(function) - \(message)"
        
        let categoryLog = OSLog(subsystem: subsystem, category: category.rawValue)
        os_log("%{public}@", log: categoryLog, type: level.osLogType, formattedMessage)
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