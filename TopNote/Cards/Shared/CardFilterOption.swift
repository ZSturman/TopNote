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
    case deleted
    
    // MARK: - IMAGE DISABLED
    // CARD ATTRIBUTES
    // case hasAttachment
    
    var id: String { rawValue }
    
    static var typeFilters: [CardFilterOption] {
           [.todo, .flashcard, .note]
       }
       static var statusFilters: [CardFilterOption] {
           [.enqueue, .upcoming, .archived, .deleted]
       }
       
       // MARK: - IMAGE DISABLED
       static var attributeFilters: [CardFilterOption] {
           // [.hasAttachment]
           []
       }
    
    var localizedName: String {
        switch self {
        case .todo:      return "To-Do"
        case .flashcard: return "Flashcard"
        case .note:      return "Note"
        case .enqueue:   return "Queue"
        case .upcoming:  return "Upcoming"
        case .archived:  return "Archived"
        case .deleted:   return "Deleted"
        // MARK: - IMAGE DISABLED
        // case .hasAttachment: return "Has Attachment"
        }
    }
    
    var systemImage: String {
        switch self {
        case .todo:      return "checklist"
        case .flashcard: return "rectangle.on.rectangle.angled"
        case .note:      return "doc.text"
        case .enqueue:   return "clock.arrow.circlepath"
        case .upcoming:  return "calendar"
        case .archived:  return "archivebox"
        case .deleted:   return "trash"
        // MARK: - IMAGE DISABLED
        // case .hasAttachment: return "paperclip"
        }
    }
}
