//
//  FilterChipsView.swift
//  TopNote
//
//  Created by Zachary Sturman on 1/6/26.
//

import SwiftUI

/// A view that displays active filter chips for card type and tag filters
struct FilterChipsView: View {
    let filterOptions: [CardFilterOption]
    let tags: [CardTag]
    let tagSelectionStates: [UUID: TagSelectionState]
    
    /// Returns the active type filters as display text
    private var activeTypeFilters: [String] {
        let typeFilters = filterOptions.filter { CardFilterOption.typeFilters.contains($0) }
        let allTypesSelected = typeFilters.count == CardFilterOption.typeFilters.count
        
        if allTypesSelected || typeFilters.isEmpty {
            return [] // Don't show if all types selected
        }
        
        return typeFilters.compactMap { option -> String? in
            switch option {
            case .note: return "Notes"
            case .todo: return "To-dos"
            case .flashcard: return "Flashcards"
            default: return nil
            }
        }
    }
    
    /// Returns the selected (included) tags
    private var selectedTags: [CardTag] {
        tags.filter { tagSelectionStates[$0.id] == .selected }
    }
    
    /// Returns the deselected (excluded) tags
    private var deselectedTags: [CardTag] {
        tags.filter { tagSelectionStates[$0.id] == .deselected }
    }
    
    /// Whether any filters are active
    private var hasActiveFilters: Bool {
        !activeTypeFilters.isEmpty || !selectedTags.isEmpty || !deselectedTags.isEmpty
    }
    
    var body: some View {
        if hasActiveFilters {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    // Type filter chips
                    ForEach(activeTypeFilters, id: \.self) { typeName in
                        FilterChip(text: typeName, style: .neutral)
                    }
                    
                    // Included tag chips
                    ForEach(selectedTags) { tag in
                        FilterChip(text: "+\(tag.name)", style: .included)
                    }
                    
                    // Excluded tag chips
                    ForEach(deselectedTags) { tag in
                        FilterChip(text: "-\(tag.name)", style: .excluded)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 4)
            }
        }
    }
}

/// A single filter chip badge
struct FilterChip: View {
    let text: String
    let style: ChipStyle
    
    enum ChipStyle {
        case neutral
        case included
        case excluded
        
        var backgroundColor: Color {
            switch self {
            case .neutral: return Color(.systemGray5)
            case .included: return Color.green.opacity(0.2)
            case .excluded: return Color.red.opacity(0.2)
            }
        }
        
        var foregroundColor: Color {
            switch self {
            case .neutral: return .primary
            case .included: return .green
            case .excluded: return .red
            }
        }
    }
    
    var body: some View {
        Text(text)
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(style.backgroundColor)
            .foregroundStyle(style.foregroundColor)
            .clipShape(Capsule())
            .lineLimit(1)
    }
}
