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
/// Listens for remote change notifications and triggers tag deduplication.
final class CloudKitSyncHandler: ObservableObject {
    static let shared = CloudKitSyncHandler()
    
    private var notificationObserver: NSObjectProtocol?
    private let debounceInterval: TimeInterval = 2.0
    private var pendingDeduplicationTask: Task<Void, Never>?
    
    private init() {}
    
    /// Starts listening for CloudKit remote change notifications.
    /// Call this once during app initialization.
    /// - Parameter container: The ModelContainer to use for deduplication operations
    func startListening(for container: ModelContainer) {
        // Remove any existing observer
        stopListening()
        
        TopNoteLogger.cloudKit.info("Starting CloudKit sync listener")
        
        // Listen for persistent store remote change notifications
        notificationObserver = NotificationCenter.default.addObserver(
            forName: .NSPersistentStoreRemoteChange,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            self?.handleRemoteChange(notification: notification, container: container)
        }
    }
    
    /// Stops listening for CloudKit notifications.
    func stopListening() {
        if let observer = notificationObserver {
            NotificationCenter.default.removeObserver(observer)
            notificationObserver = nil
            TopNoteLogger.cloudKit.debug("Stopped CloudKit sync listener")
        }
    }
    
    /// Handles a remote change notification from CloudKit.
    private func handleRemoteChange(notification: Notification, container: ModelContainer) {
        TopNoteLogger.cloudKit.debug("Received remote change notification")
        
        // Cancel any pending deduplication task
        pendingDeduplicationTask?.cancel()
        
        // Debounce: wait a short period for batch updates to complete
        pendingDeduplicationTask = Task { @MainActor in
            do {
                try await Task.sleep(nanoseconds: UInt64(debounceInterval * 1_000_000_000))
            } catch {
                // Task was cancelled
                return
            }
            
            // Perform deduplication on a background context
            await performPostSyncCleanup(container: container)
        }
    }
    
    /// Performs cleanup operations after CloudKit sync.
    @MainActor
    private func performPostSyncCleanup(container: ModelContainer) async {
        TopNoteLogger.cloudKit.info("Performing post-sync cleanup")
        
        let context = ModelContext(container)
        
        // Run tag deduplication
        let mergedCount = TagManager.deduplicateIfNeeded(context: context)
        
        if mergedCount > 0 {
            TopNoteLogger.cloudKit.info("Post-sync cleanup: merged \(mergedCount) duplicate tags")
        }
        
        // Optionally clean up orphan tags
        let orphanCount = TagManager.cleanupOrphanTags(context: context)
        
        if orphanCount > 0 {
            TopNoteLogger.cloudKit.info("Post-sync cleanup: removed \(orphanCount) orphan tags")
        }
    }
    
    /// Manually triggers tag deduplication.
    /// Useful for running deduplication on app launch or user request.
    func triggerDeduplication(container: ModelContainer) {
        Task { @MainActor in
            TopNoteLogger.cloudKit.info("Manual deduplication triggered")
            let context = ModelContext(container)
            TagManager.deduplicateIfNeeded(context: context)
        }
    }
}
