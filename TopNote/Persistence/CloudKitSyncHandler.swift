//
//  CloudKitSyncHandler.swift
//  TopNote
//
//  Created by Zachary Sturman on 1/3/26.
//

import Foundation
import SwiftData
import CoreData
import os.log

/// Handles CloudKit synchronization events and performs post-sync cleanup.
/// Tag deduplication is now limited to:
/// - App launch (once)
/// - User creates a new tag
/// - User imports cards
/// CloudKit sync no longer triggers automatic deduplication to reduce overhead.
final class CloudKitSyncHandler: ObservableObject {
    static let shared = CloudKitSyncHandler()
    
    private var notificationObserver: NSObjectProtocol?
    
    /// Track whether initial deduplication has run this session
    private var hasRunInitialDeduplication = false
    
    private init() {}
    
    /// Starts listening for CloudKit remote change notifications.
    /// Note: We no longer automatically deduplicate on every sync to reduce overhead.
    /// - Parameter container: The ModelContainer to use for deduplication operations
    func startListening(for container: ModelContainer) {
        // Remove any existing observer
        stopListening()
        
        TopNoteLogger.cloudKit.info("Starting CloudKit sync listener")
        
        // Listen for persistent store remote change notifications
        // We keep the listener for potential future use but don't trigger deduplication
        notificationObserver = NotificationCenter.default.addObserver(
            forName: .NSPersistentStoreRemoteChange,
            object: nil,
            queue: .main
        ) { _ in
            // Sync received - no automatic deduplication to reduce overhead
            // Tag deduplication now only runs on app launch and specific user actions
        }
    }
    
    /// Stops listening for CloudKit notifications.
    func stopListening() {
        if let observer = notificationObserver {
            NotificationCenter.default.removeObserver(observer)
            notificationObserver = nil
        }
    }
    
    /// Runs initial tag deduplication on app launch.
    /// This only runs once per app session to minimize overhead.
    /// - Parameter container: The ModelContainer to use
    func runInitialDeduplicationIfNeeded(container: ModelContainer) {
        guard !hasRunInitialDeduplication else { return }
        hasRunInitialDeduplication = true
        
        Task.detached(priority: .utility) {
            let context = ModelContext(container)
            let mergedCount = TagManager.deduplicateIfNeeded(context: context)
            
            if mergedCount > 0 {
                TopNoteLogger.cloudKit.info("Initial cleanup: merged \(mergedCount) duplicate tags")
            }
        }
    }
    
    /// Triggers tag deduplication after a user action that may create duplicates.
    /// Call this after:
    /// - Creating a new tag
    /// - Importing cards with tags
    /// Runs on a background thread to avoid blocking the UI.
    /// - Parameter container: The ModelContainer to use
    func triggerDeduplicationAfterUserAction(container: ModelContainer) {
        Task.detached(priority: .utility) {
            let context = ModelContext(container)
            let mergedCount = TagManager.deduplicateIfNeeded(context: context)
            
            if mergedCount > 0 {
                TopNoteLogger.cloudKit.info("Post-action cleanup: merged \(mergedCount) duplicate tags")
            }
        }
    }
}
