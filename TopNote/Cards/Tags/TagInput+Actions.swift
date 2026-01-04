//
//  TagInput+Actions.swift
//  TopNote
//
//  Created by Zachary Sturman on 11/27/25.
//

import WidgetKit

extension TagInputView {
    func addTag() {
        let trimmed = newTag.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        let tag = getOrCreateTag(withName: trimmed)
        if !card.unwrappedTags.contains(where: { $0.id == tag.id }) {
            if card.tags == nil {
                card.tags = [tag]
            } else {
                card.tags?.append(tag)
            }
        }
        newTag = ""
        Card.throttledWidgetReload()
    }
    
    func addExistingTag(_ tag: CardTag) {
        if !card.unwrappedTags.contains(where: { $0.id == tag.id }) {
            if card.tags == nil {
                card.tags = [tag]
            } else {
                card.tags?.append(tag)
            }
        }
        newTag = ""
        Card.throttledWidgetReload()

    }
    
    func removeTag(_ tag: CardTag) {
        card.tags?.removeAll { $0.id == tag.id }
        if tag.unwrappedCards.isEmpty {
            modelContext.delete(tag)
        }
        Card.throttledWidgetReload()
    }
    
    func getOrCreateTag(withName name: String) -> CardTag {
        // Delegate to centralized TagManager for consistent tag handling
        return TagManager.getOrCreateTag(name: name, context: modelContext)
    }
}
