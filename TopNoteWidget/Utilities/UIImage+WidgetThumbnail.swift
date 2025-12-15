//
//  UIImage+WidgetThumbnail.swift
//  TopNote
//
//  Created by Zachary Sturman on 12/13/25.
//

import UIKit

extension UIImage {
    func widgetThumbnail(maxSize: CGFloat) -> UIImage {
        let size = self.size
        let ratio = max(size.width, size.height) / maxSize

        if ratio <= 1 {
            return self
        }

        let newSize = CGSize(width: size.width / ratio, height: size.height / ratio)

        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            self.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}
