//
//  AppRouter.swift
//  TopNote
//
//  Where the app is and where links, widgets, Siri and tips send it.
//

import SwiftUI
import Observation

@MainActor
@Observable
final class AppRouter {
    enum Tab: Hashable {
        case upNext, library, settings
    }

    enum Sheet: Identifiable, Equatable {
        case capture(CardType)
        case widgetGuide
        case shortcutsGuide
        case whatsNew
        case onboarding

        var id: String {
            switch self {
            case .capture(let type): "capture-\(type.routeName)"
            case .widgetGuide: "widgetGuide"
            case .shortcutsGuide: "shortcutsGuide"
            case .whatsNew: "whatsNew"
            case .onboarding: "onboarding"
            }
        }
    }

    var tab: Tab = .upNext
    var upNextFilter: CardType?
    var sheet: Sheet?
    /// A card to highlight in Library (existing deep-link machinery).
    var libraryCardID: UUID?
    /// Settings opens straight to Reminders when set.
    var showsRemindersSettings = false

    /// The kind of card new captures start as; remembers the last one used.
    var lastCaptureType: CardType {
        get { CardType(routeName: UserDefaults.standard.string(forKey: "capture.lastType") ?? "") ?? .note }
        set { UserDefaults.standard.set(newValue.routeName, forKey: "capture.lastType") }
    }

    func open(_ route: TopNoteRoute, isDue: (UUID) -> Bool = { _ in false }) {
        switch route {
        case .card(let id):
            if isDue(id) {
                tab = .upNext
            } else {
                tab = .library
                libraryCardID = id
            }
        case .add(let type):
            sheet = .capture(type ?? lastCaptureType)
        case .upNext(let type):
            tab = .upNext
            upNextFilter = type
        case .settings(let section):
            tab = .settings
            showsRemindersSettings = section == "reminders"
        }
    }

    func capture(_ type: CardType? = nil) {
        sheet = .capture(type ?? lastCaptureType)
    }
}

/// Which welcome a launch should show: onboarding for new people, What's New for upgraders.
enum WelcomeState {
    static let onboardingKey = "welcome.onboardingDone.v2"
    static let whatsNewKey = "welcome.whatsNewSeen.v2"

    static func sheetForLaunch(hasCards: Bool) -> AppRouter.Sheet? {
        let defaults = UserDefaults.standard
        let arguments = ProcessInfo.processInfo.arguments
        if arguments.contains("-TopNoteSkipWelcome") { return nil }
        if arguments.contains("-TopNoteShowOnboarding") { return .onboarding }
        if arguments.contains("-TopNoteShowWhatsNew") { return .whatsNew }
        if defaults.bool(forKey: onboardingKey) || defaults.bool(forKey: whatsNewKey) { return nil }
        // Someone with cards already used 1.x: show what changed. Everyone else gets onboarding.
        return hasCards ? .whatsNew : .onboarding
    }

    static func markSeen() {
        UserDefaults.standard.set(true, forKey: onboardingKey)
        UserDefaults.standard.set(true, forKey: whatsNewKey)
    }
}
