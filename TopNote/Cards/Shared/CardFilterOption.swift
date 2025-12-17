//
//  CardFilterOption.swift
//  TopNote
//
//  Created by Zachary Sturman on 11/27/25.
//


enum CardFilterOption: String, CaseIterable, Identifiable {
    
    // CARD TYPES
    case todo
    case flashcard
    case note
    
    // CARD STATES
    case enqueue
    case upcoming
    case archived
    
    // MARK: - IMAGE DISABLED
    // CARD ATTRIBUTES
    // case hasAttachment
    
    var id: String { rawValue }
    
    static var typeFilters: [CardFilterOption] {
           [.todo, .flashcard, .note]
       }
       static var statusFilters: [CardFilterOption] {
           [.enqueue, .upcoming, .archived]
       }
       // MARK: - IMAGE DISABLED
       static var attributeFilters: [CardFilterOption] {
           // [.hasAttachment]
           []
       }
    
    var localizedName: String {
        switch self {
        case .todo:      return "To-Do"
        case .flashcard: return "Flashcards"
        case .note:      return "Notes"
        case .enqueue:   return "Queue"
        case .upcoming:  return "Upcoming"
        case .archived:  return "Archived"
        // MARK: - IMAGE DISABLED
        // case .hasAttachment: return "Has Attachment"
        }
    }
}
