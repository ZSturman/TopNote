//
//  CardEntity.swift
//  TopNote
//
//  Created by Zachary Sturman on 12/13/25.
//

import Foundation
import WidgetKit
import SwiftUI
import AppIntents
import UIKit
import os.log

struct CardEntity: AppEntity {
    var id: UUID
    var createdAt: Date
    var cardTypeRaw: String
    var content: String
    var answer: String?
    var isRecurring: Bool
    var skipCount: Int
    var seenCount: Int
    var repeatInterval: Int
    var nextTimeInQueue: Date
    var folder: Folder?
    var isArchived: Bool
    var answerRevealed: Bool
    var skipEnabled: Bool
    var tags: [String]?
    // var widgetTextHidden: Bool
    // Image data for widget display (compressed thumbnails)
    // var contentImageData: Data?
    // var answerImageData: Data?
    
    // Flags to indicate card has image but couldn't be loaded (for placeholder display)
    // var contentImageLoadFailed: Bool = false
    // var answerImageLoadFailed: Bool = false

    var cardType: CardType {
        CardType(rawValue: cardTypeRaw) ?? .note
    }

    static var defaultQuery = CardEntityQuery()

    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        TypeDisplayRepresentation(
            name: LocalizedStringResource("Cards", table: "AppIntents")
        )
    }

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(stringLiteral: content)
    }
}

struct CardEntry: TimelineEntry {
    let date: Date
    let card: CardEntity
    let queueCardCount: Int
    let totalNumberOfCards: Int
    let nextCardForQueue: CardEntity?
    let nextUpdateDate: Date

    let selectedCardTypes: [CardType]
    let selectedFolders: [Folder]

    // Widget-instance state tracking
    let widgetIdentifier: String
}

// MARK: - IMAGE DISABLED
// Image functionality is temporarily disabled. The Card model schema is preserved for production compatibility.
extension CardEntity {
    init(card: Card, widgetImageMaxSize: CGFloat) {
        // IMAGE DISABLED: Skip all image loading to improve performance
        // The image properties are preserved in the CardEntity struct for API compatibility
        
        /* ORIGINAL IMAGE LOADING CODE:
        // Determine appropriate cache size based on requested widget size
        let cacheSize: WidgetThumbnailCache.WidgetSize = {
            switch widgetImageMaxSize {
            case ...350: return .small
            case ...650: return .medium
            case ...950: return .large
            default: return .extraLarge
            }
        }()
        
        // Try to load image from cache first, then fall back to on-demand with retry
        func loadThumbnailData(
            cardID: UUID,
            imageType: WidgetThumbnailCache.ImageType,
            rawDataLoader: () -> Data?
        ) -> (data: Data?, loadFailed: Bool) {
            // First, try pre-generated cache (fast path - no external storage access needed)
            if let cachedData = WidgetThumbnailCache.getThumbnail(
                cardID: cardID,
                imageType: imageType,
                size: cacheSize
            ) {
                return (cachedData, false)
            }
            
            // Fall back to on-demand processing with retry for external storage
            let rawData = ExternalStorageRetry.loadImageWithRetry(
                loader: rawDataLoader,
                cardID: cardID,
                imageType: imageType,
                config: .aggressive
            )
            
            // Check if card has image data but we couldn't load it
            guard let imageData = rawData, !imageData.isEmpty else {
                // Check if the card actually has image data (nil vs failed to load)
                let hasImageData = rawDataLoader() != nil
                if hasImageData {
                    return (nil, true)
                }
                return (nil, false)
            }
            
            // Attempt to decode and process the image
            guard let image = UIImage(data: imageData) else {
                return (nil, true)
            }
            
            let thumbnail = image.widgetThumbnail(maxSize: widgetImageMaxSize)
            
            // Compress to JPEG
            guard let jpegData = thumbnail.jpegData(compressionQuality: 0.75) else {
                return (nil, true)
            }
            
            return (jpegData, false)
        }
        */

        self.id = card.id
        self.createdAt = card.createdAt
        self.cardTypeRaw = card.cardType.rawValue
        self.content = card.displayContent
        self.answer = card.displayAnswer
        self.isRecurring = card.isRecurring
        self.skipCount = card.skipCount
        self.seenCount = card.seenCount
        self.repeatInterval = card.repeatInterval
        self.nextTimeInQueue = card.nextTimeInQueue
        self.folder = card.folder
        self.isArchived = card.isArchived
        self.answerRevealed = card.answerRevealed
        self.skipEnabled = card.skipEnabled
        self.tags = card.unwrappedTags.map(\.name)
        // self.widgetTextHidden = card.widgetTextHidden
        
        // IMAGE DISABLED: Always set image data to nil
//        self.contentImageData = nil
//        self.contentImageLoadFailed = false
//        self.answerImageData = nil
//        self.answerImageLoadFailed = false
//        
        /* ORIGINAL IMAGE LOADING CODE:
        let contentResult = loadThumbnailData(
            cardID: card.id,
            imageType: .content,
            rawDataLoader: { card.contentImageData }
        )
        self.contentImageData = contentResult.data
        self.contentImageLoadFailed = contentResult.loadFailed
        
        let answerResult = loadThumbnailData(
            cardID: card.id,
            imageType: .answer,
            rawDataLoader: { card.answerImageData }
        )
        self.answerImageData = answerResult.data
        self.answerImageLoadFailed = answerResult.loadFailed
        */
    }
}
