import Foundation
import SwiftUI
import SwiftData
import os.log

/// Snapshot of a Card's editable state used to support Cancel (revert) behavior.
struct CardSnapshot {
    let content: String
    let answer: String?
    let isRecurring: Bool
    let skipCount: Int
    let seenCount: Int
    let repeatInterval: Int
    let initialRepeatInterval: Int
    let nextTimeInQueue: Date
    let folder: Folder?
    let tags: [CardTag]
    let isArchived: Bool
    let answerRevealed: Bool
    let skipPolicy: RepeatPolicy
    let ratingEasyPolicy: RepeatPolicy
    let ratingMedPolicy: RepeatPolicy
    let ratingHardPolicy: RepeatPolicy
    let isComplete: Bool
    let resetRepeatIntervalOnComplete: Bool
    let skipEnabled: Bool
    let priority: PriorityType

    init(from card: Card) {
        content = card.content
        answer = card.answer
        isRecurring = card.isRecurring
        skipCount = card.skipCount
        seenCount = card.seenCount
        repeatInterval = card.repeatInterval
        initialRepeatInterval = card.initialRepeatInterval
        nextTimeInQueue = card.nextTimeInQueue
        folder = card.folder
        tags = card.unwrappedTags
        isArchived = card.isArchived
        answerRevealed = card.answerRevealed
        skipPolicy = card.skipPolicy
        ratingEasyPolicy = card.ratingEasyPolicy
        ratingMedPolicy = card.ratingMedPolicy
        ratingHardPolicy = card.ratingHardPolicy
        isComplete = card.isComplete
        resetRepeatIntervalOnComplete = card.resetRepeatIntervalOnComplete
        skipEnabled = card.skipEnabled
        priority = card.priority
    }

    func apply(to card: Card) {
        card.content = content
        card.answer = answer
        card.isRecurring = isRecurring
        card.skipCount = skipCount
        card.seenCount = seenCount
        card.repeatInterval = repeatInterval
        card.initialRepeatInterval = initialRepeatInterval
        card.nextTimeInQueue = nextTimeInQueue
        card.folder = folder
        card.tags = tags
        card.isArchived = isArchived
        card.answerRevealed = answerRevealed
        card.skipPolicy = skipPolicy
        card.ratingEasyPolicy = ratingEasyPolicy
        card.ratingMedPolicy = ratingMedPolicy
        card.ratingHardPolicy = ratingHardPolicy
        card.isComplete = isComplete
        card.resetRepeatIntervalOnComplete = resetRepeatIntervalOnComplete
        card.skipEnabled = skipEnabled
        card.priority = priority
    }
}

/// An ObservableObject that manages the global selection state of a Card.
/// Tracks the currently selected Card and whether it was newly created.
final class SelectedCardModel: ObservableObject {
    /// The currently selected Card, if any.
    @Published var selectedCard: Card? = nil
    
    /// A flag indicating whether the selected card was newly created.
    @Published var isNewlyCreated: Bool = false

    /// Latest in-memory drafts for the selected card. Not published to avoid UI invalidations per keystroke.
    private(set) var draftContent: String? = nil
    private(set) var draftAnswer: String? = nil
    
    /// The ID of the card that the current drafts belong to.
    /// Used to prevent race conditions when switching selections.
    private(set) var draftCardID: UUID? = nil

    /// Snapshot captured at the moment selection begins, used for Cancel.
    private(set) var snapshot: CardSnapshot? = nil
    
    /// Selects a Card by its UUID from the given ModelContext.
    /// - Parameters:
    ///   - id: The UUID of the Card to select.
    ///   - modelContext: The ModelContext used to fetch the Card.
    ///   - isNew: Indicates if the Card is newly created. Defaults to `false`.
    func selectCard(with id: UUID, modelContext: ModelContext, isNew: Bool = false) {
        TopNoteLogger.selection.debug("Selecting card with ID: \(id.uuidString), isNew: \(isNew)")
        
        let descriptor = FetchDescriptor<Card>(predicate: #Predicate { $0.id == id })
        do {
            if let card = try modelContext.fetch(descriptor).first {
                TopNoteLogger.selection.info("Successfully selected card: \(id.uuidString)")
                selectedCard = card
                isNewlyCreated = isNew
                clearDrafts()
                captureSnapshot()
            } else {
                TopNoteLogger.selection.warning("Card not found for ID: \(id.uuidString)")
                selectedCard = nil
                isNewlyCreated = false
                snapshot = nil
                clearDrafts()
            }
        } catch {
            TopNoteLogger.selection.error("Failed to fetch card \(id.uuidString): \(error.localizedDescription)")
            selectedCard = nil
            isNewlyCreated = false
            snapshot = nil
            clearDrafts()
        }
    }
    
    /// Clears the current selection and resets the `isNewlyCreated` flag and snapshot.
    func clearSelection() {
        if let previousCard = selectedCard {
            TopNoteLogger.selection.debug("Clearing selection for card: \(previousCard.id.uuidString)")
        }
        selectedCard = nil
        isNewlyCreated = false
        snapshot = nil
        clearDrafts()
    }
    
    /// Sets the `isNewlyCreated` flag.
    /// - Parameter value: The new value for `isNewlyCreated`.
    func setIsNewlyCreated(_ value: Bool) {
        isNewlyCreated = value
    }

    /// Capture a snapshot of the currently selected card's state.
    func captureSnapshot() {
        if let card = selectedCard {
            snapshot = CardSnapshot(from: card)
        } else {
            snapshot = nil
        }
    }

    /// Restore the snapshot into the currently selected card, if available.
    func restoreSnapshotIfAvailable() {
        if let card = selectedCard, let snapshot {
            snapshot.apply(to: card)
        }
    }

    /// Update the cached drafts without touching SwiftData models.
    func updateDraft(content: String) {
        draftContent = content
    }

    func updateDraft(answer: String) {
        draftAnswer = answer
    }
    
    /// Sets the draft card ID to associate drafts with a specific card.
    func setDraftCardID(_ id: UUID?) {
        draftCardID = id
    }

    func clearDrafts() {
        draftContent = nil
        draftAnswer = nil
        draftCardID = nil
    }
    
    /// Safely retrieves drafts only if they belong to the specified card.
    /// Returns nil if drafts belong to a different card (race condition prevention).
    func getDraftsForCard(_ cardID: UUID) -> (content: String?, answer: String?)? {
        guard draftCardID == cardID else {
            TopNoteLogger.selection.warning("Draft card ID mismatch: expected \(cardID.uuidString), got \(self.draftCardID?.uuidString ?? "nil")")
            return nil
        }
        return (draftContent, draftAnswer)
    }
}

