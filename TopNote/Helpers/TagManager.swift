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
                return existingTag
            }
        } catch {
            TopNoteLogger.tagMutation.error("Failed to fetch tags: \(error.localizedDescription)")
        }
        
        // Create new tag
        let newTag = CardTag(name: trimmedName)
        context.insert(newTag)
        TopNoteLogger.tagMutation.info("Created new tag: \(trimmedName)")
        
        return newTag
    }
    
    // MARK: - Tag Deduplication
    
    /// Checks for and merges duplicate tags (case-insensitive).
    /// Should be called on app launch and after importing cards.
    /// - Parameter context: The SwiftData ModelContext to use
    /// - Returns: The number of duplicate tags that were merged
    @discardableResult
    static func deduplicateIfNeeded(context: ModelContext) -> Int {
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
        
        for (_, duplicates) in tagsByName where duplicates.count > 1 {
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
        }
        
        return mergedCount
    }
    
    /// Merges all cards from source tag into destination tag, then deletes source.
    /// - Parameters:
    ///   - source: The tag to merge from (will be deleted)
    ///   - destination: The tag to merge into (will be kept)
    ///   - context: The SwiftData ModelContext to use
    private static func mergeTag(source: CardTag, into destination: CardTag, context: ModelContext) {
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
    }
    
    // MARK: - Orphan Cleanup
    
    /// Removes tags that have no associated cards.
    /// - Parameter context: The SwiftData ModelContext to use
    /// - Returns: The number of orphan tags that were deleted
    @discardableResult
    static func cleanupOrphanTags(context: ModelContext) -> Int {
        let descriptor = FetchDescriptor<CardTag>()
        
        guard let allTags = try? context.fetch(descriptor) else {
            return 0
        }
        
        let orphanTags = allTags.filter { $0.unwrappedCards.isEmpty }
        
        for tag in orphanTags {
            context.delete(tag)
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
