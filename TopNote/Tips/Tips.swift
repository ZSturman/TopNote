//
//  Tips.swift
//  TopNote
//
//  Created by Zachary Sturman on 10/29/25.
//

import Foundation
import SwiftUI
import TipKit

// Tip for creating first note
struct FirstNoteTip: Tip {
    var title: Text {
        Text("Add a new note, flashcard or to-do item")
    }
    
    var image: Image? {
        Image(systemName: "plus")
    }
}

struct AddWidgetTip: Tip {
    static let createdFirstCardEvent = Event(id: "createdFirstCard")
    
    var title: Text { Text("Don't forget the widget") }
    var message: Text? { Text("Add the widget to your home screen to start seeing your queued notes.") }
    
    var image: Image? {
        Image(systemName: "widget.medium.badge.plus")
    }


    // Show only when the widget is not present
    var rules: [Rule] {
        #Rule(Self.createdFirstCardEvent) { $0.donations.count >= 1 }
    }
}

// MARK: - Policy Tips

struct PoliciesTip: Tip {
    static let openedPoliciesEvent = Event(id: "openedPolicies")
    
    var title: Text {
        Text("Control your card schedule")
    }
    
    var message: Text? {
        Text("Policies let you customize how cards reappear based on your actions. Adjust skip behavior, flashcard ratings, and more to match your learning style.")
    }
    
    var image: Image? {
        Image(systemName: "slider.horizontal.3")
    }
    
    var rules: [Rule] {
        #Rule(Self.openedPoliciesEvent) { $0.donations.count == 1 }
    }
}

struct FlashcardRatingPolicyTip: Tip {
    static let openedFlashcardPoliciesEvent = Event(id: "openedFlashcardPolicies")
    
    var title: Text {
        Text("Flashcard confidence ratings")
    }
    
    var message: Text? {
        Text("Rate how confident you felt: Easy moves the card further out, Good keeps the normal schedule, and Hard brings it back sooner for review.")
    }
    
    var image: Image? {
        Image(systemName: "hand.thumbsup.fill")
    }
    
    var rules: [Rule] {
        #Rule(Self.openedFlashcardPoliciesEvent) { $0.donations.count == 1 }
    }
}

struct FirstNoteTip_Skip: Tip {
    static let createdFirstNoteEvent = Event(id: "createdFirstNote")
    
    var title: Text {
        Text("Skipping notes")
    }
    
    var message: Text? {
        Text("When you skip a note, it will reappear later than the current repeat interval. This gives you more time before seeing it again.")
    }
    
    var image: Image? {
        Image(systemName: "doc.text")
    }
    
    var rules: [Rule] {
        #Rule(Self.createdFirstNoteEvent) { $0.donations.count == 1 }
    }
}

struct FirstTodoTip_Skip: Tip {
    static let createdFirstTodoEvent = Event(id: "createdFirstTodo")
    
    var title: Text {
        Text("Skipping todos")
    }
    
    var message: Text? {
        Text("When you skip a todo, it will reappear sooner than the current repeat interval. This helps you stay on top of tasks.")
    }
    
    var image: Image? {
        Image(systemName: "checklist")
    }
    
    var rules: [Rule] {
        #Rule(Self.createdFirstTodoEvent) { $0.donations.count == 1 }
    }
}

struct FirstFlashcardTip_Skip: Tip {
    static let createdFirstFlashcardEvent = Event(id: "createdFirstFlashcard")
    
    var title: Text {
        Text("Skipping flashcards")
    }
    
    var message: Text? {
        Text("When you skip a flashcard, it will reappear sooner than the current repeat interval. This ensures you review it more frequently.")
    }
    
    var image: Image? {
        Image(systemName: "rectangle.portrait.on.rectangle.portrait")
    }
    
    var rules: [Rule] {
        #Rule(Self.createdFirstFlashcardEvent) { $0.donations.count == 1 }
    }
}

struct RecurringOffTip: Tip {
    static let toggledRecurringOffEvent = Event(id: "toggledRecurringOff")
    
    var title: Text {
        Text("One-time card")
    }
    
    var message: Text? {
        Text("With recurring turned off, this card will be archived after you complete or skip it. It won't return to your queue automatically.")
    }
    
    var image: Image? {
        Image(systemName: "archivebox")
    }
    
    var rules: [Rule] {
        #Rule(Self.toggledRecurringOffEvent) { $0.donations.count >= 1 }
    }
}

// MARK: - Queue & Widget Tips

struct FirstQueueCardTip: Tip {
    static let viewedFirstQueueCardEvent = Event(id: "viewedFirstQueueCard")
    
    var title: Text {
        Text("Manage cards here or in the widget")
    }
    
    var message: Text? {
        Text("Swipe cards in the app to handle them quickly, or add the widget to your home screen to see and interact with cards without opening the app.")
    }
    
    var image: Image? {
        Image(systemName: "hand.draw")
    }
    
    var rules: [Rule] {
        #Rule(Self.viewedFirstQueueCardEvent) { $0.donations.count == 1 }
    }
}

struct CustomizeWidgetTip: Tip {
    static let appOpenedEvent = Event(id: "appOpened")
    
    var title: Text {
        Text("Customize your widgets")
    }
    
    var message: Text? {
        Text("Long-press any widget to edit it. Filter by flashcards, notes, or todos—or choose specific folders to focus on what matters most.")
    }
    
    var image: Image? {
        Image(systemName: "slider.horizontal.2.square.on.square")
    }
    
    var rules: [Rule] {
        #Rule(Self.appOpenedEvent) { $0.donations.count >= 10 }
    }
}

struct GetStartedTip: Tip {
    static let appOpenedWithoutActionEvent = Event(id: "appOpenedWithoutAction")
    static let userTookActionEvent = Event(id: "userTookAction")
    
    var title: Text {
        Text("Start using your cards")
    }
    
    var message: Text? {
        Text("Tap the + button to create your first card, or swipe existing cards to mark them complete or skip them. Your learning journey begins now!")
    }
    
    var image: Image? {
        Image(systemName: "sparkles")
    }
    
    var rules: [Rule] {
        #Rule(Self.appOpenedWithoutActionEvent) { $0.donations.count >= 5 }
        #Rule(Self.userTookActionEvent) { $0.donations.count == 0 }
    }
}
