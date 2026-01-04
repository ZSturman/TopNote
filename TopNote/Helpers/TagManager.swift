//
//  TagManager.swift
//  TopNote
//
//  Created by Zachary Sturman on 1/3/26.
//

import Foundation
import SwiftData
import os.log

/// Centralized manager for CardTag operations.
/// Ensures consistent tag creation, lookup, and deduplication across the app.
struct TagManager {
    
    // MARK: - Tag Lookup and Creation
    
    /// Gets an existing tag by name (case-insensitive) or creates a new one.
    /// This is the single source of truth for tag creation to prevent duplicates.
    /// - Parameters:
    ///   - name: The tag name to find or create
    ///   - context: The SwiftData ModelContext to use
    /// - Returns: The existing or newly created CardTag
    @discardableResult
    static func getOrCreateTag(name: String, context: ModelContext) -> CardTag {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            TopNoteLogger.tagMutation.warning("Attempted to create tag with empty name")
            // Return a placeholder that won't be used
            let placeholder = CardTag(name: "")
            return placeholder
        }
        
        let normalizedName = trimmedName.lowercased()
        
        // Fetch all tags and find case-insensitive match
        // Note: SwiftData predicates don't support case-insensitive string comparison directly
        let descriptor = FetchDescriptor<CardTag>()
        
        do {
            let allTags = try context.fetch(descriptor)
            
            if let existingTag = allTags.first(where: {
                $0.name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == normalizedName
            }) {
                TopNoteLogger.tagMutation.debug("Found existing tag: \(existingTag.name) (id: \(existingTag.id.uuidString))")
                return existingTag
            }
        } catch {
            TopNoteLogger.tagMutation.error("Failed to fetch tags: \(error.localizedDescription)")
        }
        
        // Create new tag
        let newTag = CardTag(name: trimmedName)
        context.insert(newTag)
        TopNoteLogger.tagMutation.info("Created new tag: \(trimmedName) (id: \(newTag.id.uuidString))")
        
        return newTag
    }
    
    // MARK: - Tag Deduplication
    
    /// Checks for and merges duplicate tags (case-insensitive).
    /// Should be called after CloudKit sync to handle potential conflicts.
    /// - Parameter context: The SwiftData ModelContext to use
    /// - Returns: The number of duplicate tags that were merged
    @discardableResult
    static func deduplicateIfNeeded(context: ModelContext) -> Int {
        TopNoteLogger.tagMutation.debug("Starting tag deduplication check")
        
        let descriptor = FetchDescriptor<CardTag>()
        
        guard let allTags = try? context.fetch(descriptor) else {
            TopNoteLogger.tagMutation.error("Failed to fetch tags for deduplication")
            return 0
        }
        
        // Group tags by normalized name
        var tagsByName: [String: [CardTag]] = [:]
        for tag in allTags {
            let normalizedName = tag.name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            tagsByName[normalizedName, default: []].append(tag)
        }
        
        var mergedCount = 0
        
        for (normalizedName, duplicates) in tagsByName where duplicates.count > 1 {
            TopNoteLogger.tagMutation.info("Found \(duplicates.count) duplicate tags for '\(normalizedName)'")
            
            // Keep the oldest tag (first by UUID if no createdAt available)
            let sortedDuplicates = duplicates.sorted { $0.id.uuidString < $1.id.uuidString }
            guard let keepTag = sortedDuplicates.first else { continue }
            
            // Merge cards from duplicates into the kept tag
            for duplicateTag in sortedDuplicates.dropFirst() {
                mergeTag(source: duplicateTag, into: keepTag, context: context)
                mergedCount += 1
            }
        }
        
        if mergedCount > 0 {
            do {
                try context.save()
                TopNoteLogger.tagMutation.info("Deduplication complete: merged \(mergedCount) duplicate tags")
            } catch {
                TopNoteLogger.tagMutation.error("Failed to save after deduplication: \(error.localizedDescription)")
            }
        } else {
            TopNoteLogger.tagMutation.debug("No duplicate tags found")
        }
        
        return mergedCount
    }
    
    /// Merges all cards from source tag into destination tag, then deletes source.
    /// - Parameters:
    ///   - source: The tag to merge from (will be deleted)
    ///   - destination: The tag to merge into (will be kept)
    ///   - context: The SwiftData ModelContext to use
    static func mergeTag(source: CardTag, into destination: CardTag, context: ModelContext) {
        TopNoteLogger.tagMutation.debug("Merging tag '\(source.name)' into '\(destination.name)'")
        
        let sourceCards = source.unwrappedCards
        
        for card in sourceCards {
            // Remove from source
            card.tags?.removeAll { $0.id == source.id }
            
            // Add to destination if not already present
            if !card.unwrappedTags.contains(where: { $0.id == destination.id }) {
                if card.tags == nil {
                    card.tags = [destination]
                } else {
                    card.tags?.append(destination)
                }
            }
        }
        
        // Delete the source tag
        context.delete(source)
        TopNoteLogger.tagMutation.debug("Deleted merged tag: \(source.name) (id: \(source.id.uuidString))")
    }
    
    // MARK: - Orphan Cleanup
    
    /// Removes tags that have no associated cards.
    /// - Parameter context: The SwiftData ModelContext to use
    /// - Returns: The number of orphan tags that were deleted
    @discardableResult
    static func cleanupOrphanTags(context: ModelContext) -> Int {
        let descriptor = FetchDescriptor<CardTag>()
        
        guard let allTags = try? context.fetch(descriptor) else {
            TopNoteLogger.tagMutation.error("Failed to fetch tags for orphan cleanup")
            return 0
        }
        
        let orphanTags = allTags.filter { $0.unwrappedCards.isEmpty }
        
        for tag in orphanTags {
            context.delete(tag)
            TopNoteLogger.tagMutation.debug("Deleted orphan tag: \(tag.name)")
        }
        
        if !orphanTags.isEmpty {
            do {
                try context.save()
                TopNoteLogger.tagMutation.info("Cleaned up \(orphanTags.count) orphan tags")
            } catch {
                TopNoteLogger.tagMutation.error("Failed to save after orphan cleanup: \(error.localizedDescription)")
            }
        }
        
        return orphanTags.count
    }
}
