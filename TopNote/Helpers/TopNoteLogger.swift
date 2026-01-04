//
//  TopNoteLogger.swift
//  TopNote
//
//  Created by Zachary Sturman on 1/3/26.
//

import Foundation
import os.log

/// Centralized logging infrastructure for TopNote using Apple's unified logging system (OSLog).
/// Use these loggers throughout the app for structured, filterable logging that persists
/// to the system log and can be viewed in Console.app or Xcode.
struct TopNoteLogger {
    private static let subsystem = "com.zacharysturman.TopNote"
    
    // MARK: - Logger Categories
    
    /// Logs related to data access, model container creation, and persistence operations.
    static let dataAccess = Logger(subsystem: subsystem, category: "DataAccess")
    
    /// Logs related to card creation, updates, deletion, and duplication.
    static let cardMutation = Logger(subsystem: subsystem, category: "CardMutation")
    
    /// Logs related to tag creation, lookup, deduplication, and merging.
    static let tagMutation = Logger(subsystem: subsystem, category: "TagMutation")
    
    /// Logs related to card selection state changes.
    static let selection = Logger(subsystem: subsystem, category: "Selection")
    
    /// Logs related to card lifecycle events (archive, enqueue, complete, etc.).
    static let cardLifecycle = Logger(subsystem: subsystem, category: "CardLifecycle")
    
    /// Logs related to CloudKit synchronization and conflict resolution.
    static let cloudKit = Logger(subsystem: subsystem, category: "CloudKit")
    
    /// Logs related to schema migrations and data transformations.
    static let migration = Logger(subsystem: subsystem, category: "Migration")
}
