//
//  TopNoteApp.swift
//  TopNote
//
//  Created by Zachary Sturman on 2/17/25.
//
import SwiftUI
import SwiftData
import UserNotifications
import UIKit
import TipKit
import os.log

@main
struct TopNoteApp: App {
    // Use the shared container defined in SharedModel.swift (configured with App Group)
    private let modelContainer = sharedModelContainer
    
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var containerState = ModelContainerState.shared
    
    var body: some Scene {
        WindowGroup {
            // Show error view if model container initialization failed
            if containerState.error != nil {
                MigrationErrorView()
            } else {
                ContentView()
                // 3) Inject both the SwiftData container and your manager
                    .modelContainer(modelContainer)
                    .task {
                            do {
                                try Tips.configure([
                                    .displayFrequency(.immediate),
                                    .datastoreLocation(.applicationDefault)
                                ])
                            } catch {
                                // Configuration failures shouldn't crash the app
                                TopNoteLogger.dataAccess.warning("Tips.configure failed: \(error.localizedDescription)")
                            }
                    }
                    .task {
                        // Start CloudKit sync handler
                        CloudKitSyncHandler.shared.startListening(for: modelContainer)
                        
                        // Run initial tag deduplication once on launch (runs on background thread)
                        CloudKitSyncHandler.shared.runInitialDeduplicationIfNeeded(container: modelContainer)
                    }
                    .task {
                        // Clean up cards deleted more than 30 days ago
                        await cleanupOldDeletedCards()
                    }
                    #if DEBUG
                    .task {
                        seedDemoDataIfNeeded(into: modelContainer)
                    }
                    #endif
                    .task {
                        // Request permission for badges once on first launch
                        await requestBadgeAuthorizationIfNeeded()
                        await updateAppBadge()
                    }
                    .onChange(of: scenePhase) { _, newPhase in
                        if newPhase == .active {
                            Task {
                                await updateAppBadge()
                            }
                        }
                    }
            }
        }
    }
    
    
    // MARK: - Badge Authorization
    
    private func requestBadgeAuthorizationIfNeeded() async {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        // If undetermined, ask; if denied, we cannot set badges
        if settings.authorizationStatus == .notDetermined {
            do {
                try await center.requestAuthorization(options: [.badge])
            } catch {
                // Ignore errors; user may deny
                TopNoteLogger.dataAccess.debug("Badge authorization request failed: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Badge Update
    
    @MainActor
    private func updateAppBadge() async {
        let context = ModelContext(modelContainer)
        let count = queuedCardsCount(using: context)
        
        if #available(iOS 17.0, *) {
            // Preferred API on iOS 17+
            UNUserNotificationCenter.current().setBadgeCount(count) { error in
                if let error = error {
                    // On iOS 17+, do not fallback to deprecated UIApplication API
                    TopNoteLogger.dataAccess.error("Failed to set badge via UNUserNotificationCenter: \(error.localizedDescription)")
                }
            }
        } else {
            // Fallback for iOS versions prior to 17
            setBadgeNumberLegacy(count)
        }
    }
    
    private func queuedCardsCount(using context: ModelContext) -> Int {
        let now = Date()
        // Count cards that are due (in queue) and not archived - using fetchCount for efficiency
        let predicate = #Predicate<Card> { card in
            card.isArchived == false && card.nextTimeInQueue <= now
        }
        let fetch = FetchDescriptor<Card>(predicate: predicate)
        do {
            // Use fetchCount instead of fetch().count to avoid loading all cards
            let count = try context.fetchCount(fetch)
            return count
        } catch {
            TopNoteLogger.dataAccess.error("Failed to count queued cards: \(error.localizedDescription)")
            return 0
        }
    }
    
    // MARK: - Cleanup Old Deleted Cards
    
    /// Permanently deletes cards that were soft-deleted more than 30 days ago
    private func cleanupOldDeletedCards() async {
        let context = ModelContext(modelContainer)
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        
        // Fetch cards with deletedAt before 30 days ago
        let predicate = #Predicate<Card> { card in
            card.deletedAt != nil
        }
        let fetch = FetchDescriptor<Card>(predicate: predicate)
        
        do {
            let deletedCards = try context.fetch(fetch)
            var permanentlyDeletedCount = 0
            
            for card in deletedCards {
                if let deletedAt = card.deletedAt, deletedAt < thirtyDaysAgo {
                    context.delete(card)
                    permanentlyDeletedCount += 1
                }
            }
            
            if permanentlyDeletedCount > 0 {
                try context.save()
                TopNoteLogger.dataAccess.info("Cleaned up \(permanentlyDeletedCount) cards deleted more than 30 days ago")
            }
        } catch {
            TopNoteLogger.dataAccess.error("Failed to cleanup old deleted cards: \(error.localizedDescription)")
        }
    }
}

// MARK: - Legacy badge setter (pre-iOS 17)
@available(iOS, introduced: 2.0, deprecated: 17.0)
private func setBadgeNumberLegacy(_ count: Int) {
    UIApplication.shared.applicationIconBadgeNumber = count
}
