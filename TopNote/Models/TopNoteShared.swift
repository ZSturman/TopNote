//
//  TopNoteShared.swift
//  TopNote
//
//  Identifiers and routes shared by the app, the widget extension and App Intents.
//

import Foundation
import WidgetKit

enum TopNoteShared {
    static let appGroupID = "group.com.zacharysturman.topnote"

    /// Widget kinds. The card widget's kind is unchanged from 1.x so placed widgets keep working.
    enum WidgetKind {
        static let card = "Top Note Widget"
        static let glance = "Top Note Glance"
    }

    static var groupDefaults: UserDefaults {
        UserDefaults(suiteName: appGroupID) ?? .standard
    }

    static func reloadWidgets() {
        WidgetCenter.shared.reloadTimelines(ofKind: WidgetKind.card)
        WidgetCenter.shared.reloadTimelines(ofKind: WidgetKind.glance)
    }

    /// True while UI tests or screenshot runs use a throwaway in-memory library.
    static var usesInMemoryStore: Bool {
        ProcessInfo.processInfo.arguments.contains("-TopNoteInMemoryStore")
    }
}

/// Deep links understood by the app: `topnote://card/<id>`, `topnote://add?type=note`,
/// `topnote://upnext?type=flashcard`, `topnote://settings/reminders`.
enum TopNoteRoute: Equatable {
    case card(UUID)
    case add(CardType?)
    case upNext(CardType?)
    case settings(String?)

    init?(url: URL) {
        guard url.scheme == "topnote" else { return nil }
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        let type = components?.queryItems?.first(where: { $0.name == "type" })?.value.flatMap(CardType.init(routeName:))
        let path = url.pathComponents.filter { $0 != "/" }
        switch url.host {
        case "card":
            guard let first = path.first, let id = UUID(uuidString: first) else { return nil }
            self = .card(id)
        case "add": self = .add(type)
        case "upnext", "study": self = .upNext(url.host == "study" ? (type ?? .flashcard) : type)
        case "settings": self = .settings(path.first)
        default: return nil
        }
    }

    var url: URL {
        var components = URLComponents()
        components.scheme = "topnote"
        switch self {
        case .card(let id):
            components.host = "card"
            components.path = "/\(id.uuidString)"
        case .add(let type):
            components.host = "add"
            if let type { components.queryItems = [URLQueryItem(name: "type", value: type.routeName)] }
        case .upNext(let type):
            components.host = "upnext"
            if let type { components.queryItems = [URLQueryItem(name: "type", value: type.routeName)] }
        case .settings(let section):
            components.host = "settings"
            if let section { components.path = "/\(section)" }
        }
        return components.url!
    }
}

extension CardType {
    /// Lowercase, URL-safe name: note, todo, flashcard.
    var routeName: String {
        switch self {
        case .note: "note"
        case .todo: "todo"
        case .flashcard: "flashcard"
        }
    }

    init?(routeName: String) {
        guard let match = CardType.allCases.first(where: { $0.routeName == routeName.lowercased() }) else { return nil }
        self = match
    }
}

/// How well a flashcard is known, from how far its spacing has grown (as in Recallable).
/// It describes progress; it never says a card is overdue.
enum CardStrength: Int, CaseIterable, Comparable {
    case new, learning, familiar, strong

    init(reviewCount: Int, intervalHours: Int) {
        guard reviewCount > 0 else { self = .new; return }
        switch intervalHours {
        case ..<(7 * 24): self = .learning
        case ..<(30 * 24): self = .familiar
        default: self = .strong
        }
    }

    static func < (lhs: CardStrength, rhs: CardStrength) -> Bool { lhs.rawValue < rhs.rawValue }

    var title: String {
        switch self {
        case .new: "New"
        case .learning: "Learning"
        case .familiar: "Familiar"
        case .strong: "Strong"
        }
    }

    /// Filled bars out of three, for a compact strength meter.
    var bars: Int { rawValue }
}

/// Short, friendly spans such as "1 day", "3 wk", "2 mo".
enum IntervalText {
    static func short(hours: Int) -> String {
        let days = Double(hours) / 24
        switch days {
        case ..<1.5: return "1 day"
        case ..<13.5: return "\(Int(days.rounded())) days"
        case ..<27.5: return "\(Int((days / 7).rounded())) wk"
        case ..<330: return "\(Int((days / 30).rounded())) mo"
        default: return "1 yr"
        }
    }

    static func long(hours: Int) -> String {
        let days = Double(hours) / 24
        switch days {
        case ..<1.5: return "tomorrow"
        case ..<13.5: return "in \(Int(days.rounded())) days"
        case ..<27.5:
            let weeks = Int((days / 7).rounded())
            return weeks == 1 ? "in a week" : "in \(weeks) weeks"
        case ..<330:
            let months = Int((days / 30).rounded())
            return months == 1 ? "in a month" : "in \(months) months"
        default: return "in a year"
        }
    }
}
