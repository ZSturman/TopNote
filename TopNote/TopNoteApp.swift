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

@main
struct TopNoteApp: App {
    // 1) Build your shared container
    private let sharedModelContainer: ModelContainer = {
        let schema = Schema([Card.self, Folder.self, CardTag.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            ContentView()
                // 3) Inject both the SwiftData container and your manager
                .modelContainer(sharedModelContainer)
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
                print("Badge authorization request failed: \(error)")
            }
        }
    }

    // MARK: - Badge Update

    @MainActor
    private func updateAppBadge() async {
        let context = ModelContext(sharedModelContainer)
        let count = queuedCardsCount(using: context)

        if #available(iOS 17.0, *) {
            // Preferred API on iOS 17+
            UNUserNotificationCenter.current().setBadgeCount(count) { error in
                if let error = error {
                    // On iOS 17+, do not fallback to deprecated UIApplication API
                    print("Failed to set badge via UNUserNotificationCenter: \(error)")
                }
            }
        } else {
            // Fallback for iOS versions prior to 17
            setBadgeNumberLegacy(count)
        }
    }

    private func queuedCardsCount(using context: ModelContext) -> Int {
        let now = Date()
        // Count cards that are due (in queue) and not archived
        let predicate = #Predicate<Card> { card in
            card.isArchived == false && card.nextTimeInQueue <= now
        }
        let fetch = FetchDescriptor<Card>(predicate: predicate)
        do {
            return try context.fetch(fetch).count
        } catch {
            print("Failed to fetch queued count: \(error)")
            return 0
        }
    }
}

// MARK: - Legacy badge setter (pre-iOS 17)
@available(iOS, introduced: 2.0, deprecated: 17.0)
private func setBadgeNumberLegacy(_ count: Int) {
    UIApplication.shared.applicationIconBadgeNumber = count
}
