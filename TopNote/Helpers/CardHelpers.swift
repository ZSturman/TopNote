//
//  CardHelpers.swift
//  TopNote
//
//  Created by Zachary Sturman on 8/9/25.
//

import Foundation
import SwiftData
import UIKit
import SwiftUI

/// Duplicates a Card and inserts the copy into the provided context.
/// - Parameters:
///   - card: The Card to duplicate.
///   - context: The ModelContext to insert the new Card into.
/// - Returns: The duplicated Card instance.
@discardableResult
func duplicateCard(_ card: Card, in context: ModelContext) -> Card {
    let now = Date()
    let duplicate = Card(
        createdAt: now,
        cardType: card.cardType,
        priorityTypeRaw: card.priority,
        content: card.content,
        isRecurring: card.isRecurring,
        skipCount: card.skipCount,
        seenCount: card.seenCount,
        repeatInterval: card.repeatInterval,
        //isDynamic: card.isDynamic,
        nextTimeInQueue: card.nextTimeInQueue,
        folder: card.folder,
        tags: card.unwrappedTags,
        answer: card.answer,
        contentImageData: card.contentImageData,
        answerImageData: card.answerImageData,
        rating: card.rating,
        isArchived: card.isArchived,
        //answerRevealed: card.answerRevealed,
        skipPolicy: card.skipPolicy,
        ratingEasyPolicy: card.ratingEasyPolicy,
        ratingMedPolicy: card.ratingMedPolicy,
        ratingHardPolicy: card.ratingHardPolicy,
        isComplete: card.isComplete
    )
    context.insert(duplicate)
    return duplicate
}

/// Creates and inserts a new Card into the context.
@discardableResult
func createCard(
    in context: ModelContext,
    cardType: CardType = .todo,
    content: String = "",
    answer: String? = nil,
    folder: Folder? = nil,
    tags: [CardTag] = [],
    isRecurring: Bool = false
) -> Card {
    let now = Date()
    let card = Card(
        createdAt: now,
        cardType: cardType,
        priorityTypeRaw: .none,
        content: content,
        isRecurring: isRecurring,
        skipCount: 0,
        seenCount: 0,
        repeatInterval: 240,
        //isDynamic: true,
        nextTimeInQueue: now,
        folder: folder,
        tags: tags,
        answer: answer,
        rating: [],
        isArchived: false,
        //answerRevealed: false,
        skipPolicy: .none,
        ratingEasyPolicy: .mild,
        ratingMedPolicy: .none,
        ratingHardPolicy: .aggressive
    )
    context.insert(card)
    return card
}

// MARK: - Image Helpers
//
//extension UIImage {
//    /// Maximum dimension for stored images to reduce memory pressure on widgets
//    private static let maxStorageDimension: CGFloat = 2000
//    
//    /// Resizes image if it exceeds the maximum dimension while maintaining aspect ratio
//    /// - Parameter maxDimension: Maximum width or height
//    /// - Returns: Resized image or self if already within limits
//    func resizedIfNeeded(maxDimension: CGFloat = UIImage.maxStorageDimension) -> UIImage {
//        let maxSide = max(size.width, size.height)
//        guard maxSide > maxDimension else { return self }
//        
//        let ratio = maxDimension / maxSide
//        let newSize = CGSize(width: size.width * ratio, height: size.height * ratio)
//        
//        let renderer = UIGraphicsImageRenderer(size: newSize)
//        return renderer.image { _ in
//            self.draw(in: CGRect(origin: .zero, size: newSize))
//        }
//    }
//    
//    /// Compresses image to JPEG with quality setting
//    /// Automatically resizes large images to reduce memory pressure
//    /// - Parameter quality: Compression quality (0.0 to 1.0), defaults to 0.75 for balance
//    /// - Returns: Compressed JPEG data
//    func compressedJPEGData(quality: CGFloat = 0.75) -> Data? {
//        let resized = self.resizedIfNeeded()
//        return resized.jpegData(compressionQuality: quality)
//    }
//    
//    /// Prepares image for widget storage (thumbnail + compression)
//    /// - Returns: Optimized JPEG data suitable for widget display
//    func prepareForWidget() -> Data? {
//        let thumbnail = self.thumbnailImage(maxSize: 150)
//        return thumbnail.compressedJPEGData(quality: 0.7)
//    }
//}
//
//extension Data {
//    /// Converts Data to UIImage
//    var toUIImage: UIImage? {
//        return UIImage(data: self)
//    }
//}
//
//extension Image {
//    /// Creates a SwiftUI Image from Data
//    /// - Parameter data: Image data (JPEG, PNG, etc.)
//    /// - Returns: SwiftUI Image or nil if conversion fails
//    static func fromData(_ data: Data?) -> Image? {
//        guard let data = data, let uiImage = UIImage(data: data) else { return nil }
//        return Image(uiImage: uiImage)
//    }
//}
