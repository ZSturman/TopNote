//
//  Tips.swift
//  TopNote
//
//  Created by Zachary Sturman on 10/29/25.
//
//  Tips appear at the moment they're useful, one at a time. First-run tips show as soon as they
//  apply; feature tips wait for real use and arrive at most once a day.
//

import Foundation
import SwiftUI
import TipKit

enum TopNoteTips {
    static let appOpened = Tips.Event(id: "appOpened")
    static let cardHandled = Tips.Event(id: "cardHandled")
    static let todoCreated = Tips.Event(id: "todoCreated")
    static let cardCreated = Tips.Event(id: "cardCreated")

    private static let resetKey = "tips.resetOnNextLaunch"

    static func configure() {
        let arguments = ProcessInfo.processInfo.arguments
        if arguments.contains("-TopNoteResetTips") || UserDefaults.standard.bool(forKey: resetKey) {
            try? Tips.resetDatastore()
            UserDefaults.standard.set(false, forKey: resetKey)
        }
        if arguments.contains("-TopNoteHideTips") {
            Tips.hideAllTipsForTesting()
        }
        let frequency: Tips.ConfigurationOption.DisplayFrequency = arguments.contains("-TopNoteImmediateTips") ? .immediate : .daily
        do {
            try Tips.configure([.displayFrequency(frequency), .datastoreLocation(.applicationDefault)])
        } catch {
            TopNoteLogger.dataAccess.warning("Tips.configure failed: \(error.localizedDescription)")
        }
    }

    /// Tips come back the next time Top Note opens (the datastore can't reset while in use).
    static func resetOnNextLaunch() {
        UserDefaults.standard.set(true, forKey: resetKey)
    }

    static func donate(_ event: Tips.Event<Tips.EmptyDonation>) {
        Task { await event.donate() }
    }

    /// Up Next shows these one at a time, in order, as each becomes relevant.
    static func upNextGroup() -> TipGroup {
        TipGroup(.ordered) {
            WidgetTip()
            TodoRemindersTip()
            SiriTip()
            CustomizeWidgetTip()
        }
    }
}

// MARK: - First run (shown where you can act on them)

struct AddFirstCardTip: Tip {
    var id: String { "addFirstCard" }
    var title: Text { Text("Capture your first card") }
    var message: Text? { Text("Write a note, a flashcard or a to-do. Top Note brings it back when it matters.") }
    var image: Image? { Image(systemName: "plus.circle.fill") }
    var options: [any TipOption] { [Tips.IgnoresDisplayFrequency(true)] }
}

struct RevealAnswerTip: Tip {
    var id: String { "revealAnswer" }
    var title: Text { Text("Answer in your head first") }
    var message: Text? { Text("Then tap the card or Show answer to check yourself.") }
    var image: Image? { Image(systemName: "brain.head.profile") }
    var options: [any TipOption] { [Tips.IgnoresDisplayFrequency(true)] }
}

struct RatingTip: Tip {
    var id: String { "rating" }
    var title: Text { Text("How well did you know it?") }
    var message: Text? { Text("Hard brings the card back sooner. Good and Easy space it out. The time under each button is when you'll see it again.") }
    var image: Image? { Image(systemName: "gauge.with.dots.needle.67percent") }
    var options: [any TipOption] { [Tips.IgnoresDisplayFrequency(true)] }
}

struct NoteActionsTip: Tip {
    var id: String { "noteActions" }
    var title: Text { Text("Notes come back to you") }
    var message: Text? { Text("Got it sends this note away until next time. Less often spaces it further. Add a thought to keep a dated reflection with it.") }
    var image: Image? { Image(systemName: "text.quote") }
    var options: [any TipOption] { [Tips.IgnoresDisplayFrequency(true)] }
}

struct TodoActionsTip: Tip {
    var id: String { "todoActions" }
    var title: Text { Text("Done or later") }
    var message: Text? { Text("Done checks it off; a repeating to-do comes back on schedule. Later sets it aside for a few days.") }
    var image: Image? { Image(systemName: "checkmark.circle") }
    var options: [any TipOption] { [Tips.IgnoresDisplayFrequency(true)] }
}

// MARK: - Feature discovery (ordered on Up Next)

/// After a few cards, suggests the Home Screen widget and offers step-by-step help.
struct WidgetTip: Tip {
    static let showMeHow = "showWidgetGuide"
    var id: String { "widgetTip" }
    var title: Text { Text("Put Top Note on your Home Screen") }
    var message: Text? { Text("The widget shows your next card, and you can flip, rate, check off or skip it right there.") }
    var image: Image? { Image(systemName: "widget.medium.badge.plus") }
    var rules: [Rule] {
        #Rule(TopNoteTips.cardHandled) { $0.donations.count >= 2 }
    }
    var actions: [Action] { [Action(id: Self.showMeHow, title: "Show me how")] }
}

struct TodoRemindersTip: Tip {
    static let connect = "connectReminders"
    var id: String { "todoRemindersTip" }
    var title: Text { Text("Already use Reminders?") }
    var message: Text? { Text("Link a Reminders list. To-dos stay in sync both ways, and new reminders show up here when they're due.") }
    var image: Image? { Image(systemName: "list.bullet.circle") }
    var rules: [Rule] {
        #Rule(TopNoteTips.todoCreated) { $0.donations.count >= 1 }
    }
    var actions: [Action] { [Action(id: Self.connect, title: "Connect Reminders")] }
}

struct SiriTip: Tip {
    static let showShortcuts = "showShortcuts"
    var id: String { "siriTip" }
    var title: Text { Text("Capture without opening the app") }
    var message: Text? { Text("Say \"Add a note in Top Note\" or \"What's next in Top Note\". Add a Top Note button to Control Center, or use the Action button.") }
    var image: Image? { Image(systemName: "mic.circle") }
    var rules: [Rule] {
        #Rule(TopNoteTips.appOpened) { $0.donations.count >= 3 }
        #Rule(TopNoteTips.cardCreated) { $0.donations.count >= 2 }
    }
    var actions: [Action] { [Action(id: Self.showShortcuts, title: "See what you can say")] }
}

struct CustomizeWidgetTip: Tip {
    var id: String { "customizeWidgetTip" }
    var title: Text { Text("Give each widget a job") }
    var message: Text? { Text("Touch and hold a Top Note widget, then Edit Widget to show only flashcards, only to-dos, or certain folders. Add a few with different choices.") }
    var image: Image? { Image(systemName: "slider.horizontal.2.square.on.square") }
    var rules: [Rule] {
        #Rule(TopNoteTips.cardHandled) { $0.donations.count >= 8 }
        #Rule(TopNoteTips.appOpened) { $0.donations.count >= 5 }
    }
}

// MARK: - Library (shown in context)

struct LibrarySwipeTip: Tip {
    var id: String { "librarySwipe" }
    var title: Text { Text("Everything you've captured") }
    var message: Text? { Text("Swipe a card to handle it, tap to edit, and use folders and tags to organize. Up Next shows only what's ready now.") }
    var image: Image? { Image(systemName: "hand.draw") }
}

struct PoliciesTip: Tip {
    static let openedPoliciesEvent = Event(id: "openedPolicies")

    var title: Text { Text("Control your card schedule") }
    var message: Text? { Text("Policies decide how much each action moves a card: how far Skip, Hard, Good and Easy push it.") }
    var image: Image? { Image(systemName: "slider.horizontal.3") }
    var rules: [Rule] {
        #Rule(Self.openedPoliciesEvent) { $0.donations.count == 1 }
    }
}

struct FlashcardRatingPolicyTip: Tip {
    static let openedFlashcardPoliciesEvent = Event(id: "openedFlashcardPolicies")

    var title: Text { Text("Flashcard confidence ratings") }
    var message: Text? { Text("Easy and Good move the card further out, and Hard brings it back sooner for review.") }
    var image: Image? { Image(systemName: "hand.thumbsup.fill") }
    var rules: [Rule] {
        #Rule(Self.openedFlashcardPoliciesEvent) { $0.donations.count == 1 }
    }
}

struct RecurringOffTip: Tip {
    static let toggledRecurringOffEvent = Event(id: "toggledRecurringOff")

    var title: Text { Text("One-time card") }
    var message: Text? { Text("With repeat turned off, this card archives itself after you handle it. It won't come back on its own.") }
    var image: Image? { Image(systemName: "archivebox") }
    var rules: [Rule] {
        #Rule(Self.toggledRecurringOffEvent) { $0.donations.count >= 1 }
    }
}
