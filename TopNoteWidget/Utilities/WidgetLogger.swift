////
////  WidgetLogger.swift
////  TopNote
////
////  Created by Zachary Sturman on 12/15/25.
////
//
//import Foundation
//import os.log
//
///// Centralized logging for widget image operations
///// Logs are viewable in Console.app with subsystem filter: com.zacharysturman.TopNote.Widget
//struct WidgetLogger {
//    
//    // MARK: - Log Categories
//    
//    private static let subsystem = "com.zacharysturman.TopNote.Widget"
//    
//    /// Logger for image processing operations
//    static let imageProcessing = Logger(subsystem: subsystem, category: "ImageProcessing")
//    
//    /// Logger for timeline operations
//    static let timeline = Logger(subsystem: subsystem, category: "Timeline")
//    
//    /// Logger for state management
//    static let stateManager = Logger(subsystem: subsystem, category: "StateManager")
//    
//    /// Logger for data access
//    static let dataAccess = Logger(subsystem: subsystem, category: "DataAccess")
//    
//    // MARK: - Image Processing Logs
//    
//    /// Log when image data is nil
//    static func logNilImageData(cardID: UUID, imageType: ImageType) {
//        imageProcessing.debug("[\(imageType.rawValue)] Image data is nil for card: \(cardID.uuidString)")
//    }
//    
//    /// Log when image data is empty
//    static func logEmptyImageData(cardID: UUID, imageType: ImageType, dataSize: Int) {
//        imageProcessing.warning("[\(imageType.rawValue)] Image data is empty (size: \(dataSize)) for card: \(cardID.uuidString)")
//    }
//    
//    /// Log when image data fails to decode
//    static func logImageDecodeFailed(cardID: UUID, imageType: ImageType, dataSize: Int) {
//        imageProcessing.error("[\(imageType.rawValue)] Failed to decode image data (size: \(dataSize) bytes) for card: \(cardID.uuidString)")
//    }
//    
//    /// Log successful image processing
//    static func logImageProcessed(cardID: UUID, imageType: ImageType, originalSize: CGSize, thumbnailSize: CGSize, outputBytes: Int) {
//        imageProcessing.info("[\(imageType.rawValue)] Processed image for card: \(cardID.uuidString) | Original: \(Int(originalSize.width))x\(Int(originalSize.height)) → Thumbnail: \(Int(thumbnailSize.width))x\(Int(thumbnailSize.height)) | Output: \(outputBytes) bytes")
//    }
//    
//    /// Log JPEG compression failure
//    static func logJpegCompressionFailed(cardID: UUID, imageType: ImageType) {
//        imageProcessing.error("[\(imageType.rawValue)] JPEG compression failed for card: \(cardID.uuidString)")
//    }
//    
//    /// Log memory warning during image processing
//    static func logMemoryWarning(context: String) {
//        imageProcessing.warning("Memory pressure detected during: \(context)")
//    }
//    
//    // MARK: - Timeline Logs
//    
//    /// Log timeline refresh start
//    static func logTimelineRefreshStart(widgetIdentifier: String, cardCount: Int) {
//        timeline.info("Timeline refresh started | Widget: \(widgetIdentifier) | Cards to process: \(cardCount)")
//    }
//    
//    /// Log timeline refresh complete
//    static func logTimelineRefreshComplete(widgetIdentifier: String, duration: TimeInterval, entryCount: Int) {
//        timeline.info("Timeline refresh complete | Widget: \(widgetIdentifier) | Duration: \(String(format: "%.2f", duration))s | Entries: \(entryCount)")
//    }
//    
//    /// Log timeline error
//    static func logTimelineError(widgetIdentifier: String, error: Error) {
//        timeline.error("Timeline error | Widget: \(widgetIdentifier) | Error: \(error.localizedDescription)")
//    }
//    
//    // MARK: - State Manager Logs
//    
//    /// Log card state reset
//    static func logCardStateReset(widgetID: String, oldCardID: UUID?, newCardID: UUID) {
//        if let oldID = oldCardID {
//            stateManager.info("Card state reset | Widget: \(widgetID) | Old: \(oldID.uuidString) → New: \(newCardID.uuidString)")
//        } else {
//            stateManager.info("Card state initialized | Widget: \(widgetID) | Card: \(newCardID.uuidString)")
//        }
//    }
//    
//    /// Log flip state timeout
//    static func logFlipStateTimeout(widgetID: String, cardID: UUID, elapsedSeconds: TimeInterval) {
//        stateManager.debug("Flip state timed out | Widget: \(widgetID) | Card: \(cardID.uuidString) | Elapsed: \(Int(elapsedSeconds))s")
//    }
//    
//    // MARK: - Data Access Logs
//    
//    /// Log external storage access attempt
//    static func logExternalStorageAccess(cardID: UUID, imageType: ImageType, success: Bool) {
//        if success {
//            dataAccess.debug("[\(imageType.rawValue)] External storage access successful for card: \(cardID.uuidString)")
//        } else {
//            dataAccess.warning("[\(imageType.rawValue)] External storage access failed for card: \(cardID.uuidString)")
//        }
//    }
//    
//    /// Log App Group access
//    static func logAppGroupAccess(suiteName: String, success: Bool) {
//        if success {
//            dataAccess.debug("App Group access successful: \(suiteName)")
//        } else {
//            dataAccess.error("App Group access failed: \(suiteName)")
//        }
//    }
//    
//    // MARK: - Supporting Types
//    
//    enum ImageType: String {
//        case content = "Content"
//        case answer = "Answer"
//    }
//}
//
//// MARK: - Performance Measurement
//
//extension WidgetLogger {
//    
//    /// Measure and log execution time for a block
//    static func measureTime<T>(
//        operation: String,
//        logger: Logger = timeline,
//        block: () throws -> T
//    ) rethrows -> T {
//        let start = CFAbsoluteTimeGetCurrent()
//        let result = try block()
//        let elapsed = CFAbsoluteTimeGetCurrent() - start
//        logger.debug("\(operation) completed in \(String(format: "%.3f", elapsed))s")
//        return result
//    }
//    
//    /// Async version of measureTime
//    static func measureTimeAsync<T>(
//        operation: String,
//        logger: Logger = timeline,
//        block: () async throws -> T
//    ) async rethrows -> T {
//        let start = CFAbsoluteTimeGetCurrent()
//        let result = try await block()
//        let elapsed = CFAbsoluteTimeGetCurrent() - start
//        logger.debug("\(operation) completed in \(String(format: "%.3f", elapsed))s")
//        return result
//    }
//}
//
//// MARK: - Debug Helpers
//
//#if DEBUG
//extension WidgetLogger {
//    
//    /// Dump current widget state for debugging
//    static func dumpWidgetState(widgetID: String, cardID: UUID) {
//        // FIXME: WidgetStateManager is not available when compiling for UnitTests.
//        // To re-enable, add WidgetStateManager.swift to the UnitTests target or remove WidgetLogger.swift from it.
//        /*
//        let manager = WidgetStateManager.shared
//        
//        let isFlipped = manager.isFlipped(widgetID: widgetID, cardID: cardID)
//        let isTextHidden = manager.isTextHidden(widgetID: widgetID, cardID: cardID)
//        let lastCardID = manager.getLastCardID(widgetID: widgetID)
//        
//        stateManager.debug("""
//            Widget State Dump:
//            - Widget ID: \(widgetID)
//            - Current Card: \(cardID.uuidString)
//            - Last Card: \(lastCardID?.uuidString ?? "nil")
//            - Is Flipped: \(isFlipped)
//            - Is Text Hidden: \(isTextHidden)
//            """)
//        */
//    }
//    
//    /// Log detailed image data analysis
//    static func analyzeImageData(_ data: Data?, cardID: UUID, imageType: ImageType) {
//        guard let data = data else {
//            imageProcessing.debug("[\(imageType.rawValue)] Image data is nil for \(cardID.uuidString)")
//            return
//        }
//        
//        let sizeKB = Double(data.count) / 1024.0
//        
//        // Check for common image format signatures
//        var format = "Unknown"
//        if data.count >= 8 {
//            let bytes = [UInt8](data.prefix(8))
//            
//            // JPEG: FF D8 FF
//            if bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF {
//                format = "JPEG"
//            }
//            // PNG: 89 50 4E 47 0D 0A 1A 0A
//            else if bytes[0] == 0x89 && bytes[1] == 0x50 && bytes[2] == 0x4E && bytes[3] == 0x47 {
//                format = "PNG"
//            }
//            // HEIC: Check for 'ftyp' box
//            else if bytes[4] == 0x66 && bytes[5] == 0x74 && bytes[6] == 0x79 && bytes[7] == 0x70 {
//                format = "HEIC/HEIF"
//            }
//        }
//        
//        imageProcessing.debug("""
//            [\(imageType.rawValue)] Image Analysis for \(cardID.uuidString):
//            - Size: \(String(format: "%.2f", sizeKB)) KB
//            - Format: \(format)
//            - Raw bytes: \(data.count)
//            """)
//    }
//}
//#endif
