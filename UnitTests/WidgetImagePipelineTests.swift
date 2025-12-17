//
//  WidgetImagePipelineTests.swift
//  TopNote
//
//  Created by Zachary Sturman on 12/15/25.
//

// MARK: - IMAGE DISABLED
// This entire file has been commented out because image functionality is disabled.
// The tests can be re-enabled when image support is restored.

/*
@testable import TopNote
import SwiftData
import Foundation
import Testing

import UIKit
import Foundation

// MARK: - Widget Image Pipeline Tests

@Suite("Widget Image Pipeline Tests")
struct WidgetImagePipelineTests {
    
    // MARK: - UIImage.widgetThumbnail Tests
    
    @Test func thumbnailDoesNotResizeSmallImage() throws {
        // Create a 100x100 image (smaller than maxSize)
        let size = CGSize(width: 100, height: 100)
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { context in
            UIColor.red.setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }
        
        let thumbnail = image.widgetThumbnail(maxSize: 300)
        
        // Should return same dimensions since image is smaller than maxSize
        #expect(thumbnail.size.width == 100)
        #expect(thumbnail.size.height == 100)
    }
    
    @Test func thumbnailResizesLargeImage() throws {
        // Create a 1000x1000 image (larger than maxSize)
        let size = CGSize(width: 1000, height: 1000)
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { context in
            UIColor.blue.setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }
        
        let maxSize: CGFloat = 300
        let thumbnail = image.widgetThumbnail(maxSize: maxSize)
        
        // Should resize to maxSize
        #expect(thumbnail.size.width <= maxSize)
        #expect(thumbnail.size.height <= maxSize)
    }
    
    @Test func thumbnailPreservesAspectRatio() throws {
        // Create a 800x400 image (2:1 aspect ratio)
        let size = CGSize(width: 800, height: 400)
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { context in
            UIColor.green.setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }
        
        let maxSize: CGFloat = 300
        let thumbnail = image.widgetThumbnail(maxSize: maxSize)
        
        // Should preserve 2:1 aspect ratio
        let aspectRatio = thumbnail.size.width / thumbnail.size.height
        #expect(abs(aspectRatio - 2.0) < 0.01, "Aspect ratio should be preserved")
    }
    
    @Test func thumbnailHandlesVeryLargeImage() throws {
        // Create a 4000x3000 image (simulating a photo)
        let size = CGSize(width: 4000, height: 3000)
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { context in
            UIColor.purple.setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }
        
        let maxSize: CGFloat = 600
        let thumbnail = image.widgetThumbnail(maxSize: maxSize)
        
        // Both dimensions should be within maxSize
        #expect(thumbnail.size.width <= maxSize)
        #expect(thumbnail.size.height <= maxSize)
        // Larger dimension should equal maxSize
        #expect(max(thumbnail.size.width, thumbnail.size.height) == maxSize)
    }
    
    @Test func thumbnailHandlesPortraitImage() throws {
        // Create a 400x800 portrait image
        let size = CGSize(width: 400, height: 800)
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { context in
            UIColor.orange.setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }
        
        let maxSize: CGFloat = 300
        let thumbnail = image.widgetThumbnail(maxSize: maxSize)
        
        // Height should be the limiting dimension
        #expect(thumbnail.size.height == maxSize)
        #expect(thumbnail.size.width == 150) // 300 * (400/800)
    }
    
    // MARK: - Image Data Conversion Tests
    
    @Test func validImageDataConvertsToUIImage() throws {
        let size = CGSize(width: 100, height: 100)
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { context in
            UIColor.cyan.setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }
        
        let data = image.pngData()
        #expect(data != nil, "Should produce valid PNG data")
        
        if let data = data {
            let recreatedImage = UIImage(data: data)
            #expect(recreatedImage != nil, "Should recreate image from data")
        }
    }
    
    @Test func nilImageDataReturnsNil() throws {
        let data: Data? = nil
        let image = data.flatMap { UIImage(data: $0) }
        #expect(image == nil)
    }
    
    @Test func emptyImageDataReturnsNil() throws {
        let data = Data()
        let image = UIImage(data: data)
        #expect(image == nil, "Empty data should not create an image")
    }
    
    @Test func corruptedImageDataReturnsNil() throws {
        // Create garbage data that isn't a valid image
        let corruptedData = "This is not an image".data(using: .utf8)!
        let image = UIImage(data: corruptedData)
        #expect(image == nil, "Corrupted data should not create an image")
    }
    
    @Test func randomBytesImageDataReturnsNil() throws {
        // Create random bytes
        var randomBytes = [UInt8](repeating: 0, count: 1000)
        _ = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        let randomData = Data(randomBytes)
        
        let image = UIImage(data: randomData)
        #expect(image == nil, "Random bytes should not create a valid image")
    }
    
    // MARK: - JPEG Compression Tests
    
    @Test func jpegCompressionProducesValidData() throws {
        let size = CGSize(width: 200, height: 200)
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { context in
            UIColor.yellow.setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }
        
        let jpegData = image.jpegData(compressionQuality: 0.75)
        #expect(jpegData != nil, "JPEG compression should produce data")
        
        if let jpegData = jpegData {
            let recreatedImage = UIImage(data: jpegData)
            #expect(recreatedImage != nil, "JPEG data should recreate image")
        }
    }
    
    @Test func jpegCompressionReducesFileSize() throws {
        let size = CGSize(width: 500, height: 500)
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { context in
            // Create a gradient for more realistic compression test
            for y in 0..<Int(size.height) {
                let color = UIColor(
                    red: CGFloat(y) / size.height,
                    green: 0.5,
                    blue: 1.0 - CGFloat(y) / size.height,
                    alpha: 1.0
                )
                color.setFill()
                context.fill(CGRect(x: 0, y: y, width: Int(size.width), height: 1))
            }
        }
        
        let pngData = image.pngData()
        let jpegData = image.jpegData(compressionQuality: 0.75)
        
        #expect(pngData != nil && jpegData != nil)
        
        if let pngData = pngData, let jpegData = jpegData {
            // JPEG should generally be smaller than PNG for photos
            // (though not always for simple solid colors)
            #expect(jpegData.count < pngData.count * 2, "JPEG should not be excessively larger than PNG")
        }
    }
    
    @Test func lowQualityJpegProducesSmallerFile() throws {
        let size = CGSize(width: 300, height: 300)
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { context in
            for y in 0..<Int(size.height) {
                let color = UIColor(
                    red: CGFloat(y) / size.height,
                    green: CGFloat(y) / size.height,
                    blue: 1.0,
                    alpha: 1.0
                )
                color.setFill()
                context.fill(CGRect(x: 0, y: y, width: Int(size.width), height: 1))
            }
        }
        
        let highQuality = image.jpegData(compressionQuality: 1.0)
        let lowQuality = image.jpegData(compressionQuality: 0.1)
        
        #expect(highQuality != nil && lowQuality != nil)
        
        if let highQuality = highQuality, let lowQuality = lowQuality {
            #expect(lowQuality.count < highQuality.count, "Lower quality should produce smaller file")
        }
    }
    
    // MARK: - Widget Size Constraints Tests
    
    @Test func smallWidgetImageSize() throws {
        // Small widget max size is 300
        let maxSize: CGFloat = 300
        
        let size = CGSize(width: 2000, height: 1500)
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { context in
            UIColor.gray.setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }
        
        let thumbnail = image.widgetThumbnail(maxSize: maxSize)
        let jpegData = thumbnail.jpegData(compressionQuality: 0.75)
        
        #expect(jpegData != nil)
        // Widget images should be reasonably small for memory constraints
        if let jpegData = jpegData {
            #expect(jpegData.count < 500_000, "Widget thumbnail should be under 500KB")
        }
    }
    
    @Test func largeWidgetImageSize() throws {
        // Large widget max size is 900
        let maxSize: CGFloat = 900
        
        let size = CGSize(width: 4000, height: 3000)
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { context in
            UIColor.gray.setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }
        
        let thumbnail = image.widgetThumbnail(maxSize: maxSize)
        let jpegData = thumbnail.jpegData(compressionQuality: 0.75)
        
        #expect(jpegData != nil)
        // Even large widget images should be memory-efficient
        if let jpegData = jpegData {
            #expect(jpegData.count < 2_000_000, "Large widget thumbnail should be under 2MB")
        }
    }
    
    // MARK: - Edge Cases
    
    @Test func thumbnailHandlesOneByOneImage() throws {
        let size = CGSize(width: 1, height: 1)
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { context in
            UIColor.black.setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }
        
        let thumbnail = image.widgetThumbnail(maxSize: 300)
        #expect(thumbnail.size.width == 1)
        #expect(thumbnail.size.height == 1)
    }
    
    @Test func thumbnailHandlesExactSizeImage() throws {
        // Image exactly at maxSize
        let size = CGSize(width: 300, height: 300)
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { context in
            UIColor.white.setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }
        
        let thumbnail = image.widgetThumbnail(maxSize: 300)
        #expect(thumbnail.size.width == 300)
        #expect(thumbnail.size.height == 300)
    }
    
    @Test func thumbnailHandlesVeryWideImage() throws {
        // Panoramic image
        let size = CGSize(width: 3000, height: 100)
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { context in
            UIColor.brown.setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }
        
        let maxSize: CGFloat = 600
        let thumbnail = image.widgetThumbnail(maxSize: maxSize)
        
        #expect(thumbnail.size.width == maxSize)
        #expect(thumbnail.size.height == 20) // 600 * (100/3000)
    }
    
    @Test func thumbnailHandlesVeryTallImage() throws {
        // Very tall image
        let size = CGSize(width: 100, height: 3000)
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { context in
            UIColor.magenta.setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }
        
        let maxSize: CGFloat = 600
        let thumbnail = image.widgetThumbnail(maxSize: maxSize)
        
        #expect(thumbnail.size.height == maxSize)
        #expect(thumbnail.size.width == 20) // 600 * (100/3000)
    }
}

// MARK: - Image Data Validation Helper Tests

@Suite("Image Data Validation Tests")
struct ImageDataValidationTests {
    
    @Test func validateImageDataWithValidPNG() throws {
        let size = CGSize(width: 100, height: 100)
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { context in
            UIColor.red.setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }
        
        let data = image.pngData()
        let isValid = validateImageData(data)
        #expect(isValid == true)
    }
    
    @Test func validateImageDataWithValidJPEG() throws {
        let size = CGSize(width: 100, height: 100)
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { context in
            UIColor.blue.setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }
        
        let data = image.jpegData(compressionQuality: 0.8)
        let isValid = validateImageData(data)
        #expect(isValid == true)
    }
    
    @Test func validateImageDataWithNil() throws {
        let isValid = validateImageData(nil)
        #expect(isValid == false)
    }
    
    @Test func validateImageDataWithEmpty() throws {
        let isValid = validateImageData(Data())
        #expect(isValid == false)
    }
    
    @Test func validateImageDataWithCorrupted() throws {
        let corruptedData = "not an image".data(using: .utf8)
        let isValid = validateImageData(corruptedData)
        #expect(isValid == false)
    }
    
    // Helper function to validate image data
    private func validateImageData(_ data: Data?) -> Bool {
        guard let data = data, !data.isEmpty else { return false }
        return UIImage(data: data) != nil
    }
}

// MARK: - Memory Pressure Tests

@Suite("Widget Image Memory Tests")
struct WidgetImageMemoryTests {
    
    @Test func multipleImageProcessingDoesNotExceedMemoryLimit() throws {
        // Simulate processing multiple cards with images (widget limit ~30MB)
        var totalDataSize = 0
        
        for i in 0..<10 {
            let size = CGSize(width: 2000, height: 1500)
            let renderer = UIGraphicsImageRenderer(size: size)
            let image = renderer.image { context in
                // Create unique colors for each image
                UIColor(
                    red: CGFloat(i) / 10.0,
                    green: 0.5,
                    blue: CGFloat(10 - i) / 10.0,
                    alpha: 1.0
                ).setFill()
                context.fill(CGRect(origin: .zero, size: size))
            }
            
            let thumbnail = image.widgetThumbnail(maxSize: 600)
            if let data = thumbnail.jpegData(compressionQuality: 0.75) {
                totalDataSize += data.count
            }
        }
        
        // 10 cards with images should be well under widget memory limit
        let limitMB = 30 * 1024 * 1024 // 30MB
        #expect(totalDataSize < limitMB, "Total image data should be under 30MB widget limit")
    }
    
    @Test func singleLargeImageProcessing() throws {
        // Test processing a very large image (simulating a high-res photo)
        let size = CGSize(width: 6000, height: 4000)
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { context in
            UIColor.systemBlue.setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }
        
        let thumbnail = image.widgetThumbnail(maxSize: 900)
        let jpegData = thumbnail.jpegData(compressionQuality: 0.75)
        
        #expect(jpegData != nil)
        if let data = jpegData {
            // Should be reasonable size after processing
            #expect(data.count < 1_000_000, "Processed large image should be under 1MB")
        }
    }
}
*/
