//
//  FlowLayout.swift
//  TopNote
//
//  Created by Zachary Sturman on 11/27/25.
//

import SwiftUI

struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize,
                      subviews: Subviews,
                      cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var width: CGFloat = 0
        var height: CGFloat = 0
        
        var currentRowWidth: CGFloat = 0
        var currentRowHeight: CGFloat = 0
        
        for subview in subviews {
            let subviewSize = subview.sizeThatFits(.unspecified)
            
            if currentRowWidth + subviewSize.width > maxWidth {
                width = max(width, currentRowWidth)
                height += currentRowHeight + spacing
                currentRowWidth = subviewSize.width
                currentRowHeight = subviewSize.height
            } else {
                currentRowWidth += subviewSize.width + spacing
                currentRowHeight = max(currentRowHeight, subviewSize.height)
            }
        }
        
        width = max(width, currentRowWidth)
        height += currentRowHeight
        
        return CGSize(width: width, height: height)
    }
    
    func placeSubviews(in bounds: CGRect,
                       proposal: ProposedViewSize,
                       subviews: Subviews,
                       cache: inout ()) {
        let maxWidth = bounds.width
        var x = bounds.minX
        var y = bounds.minY
        var currentRowHeight: CGFloat = 0
        
        for subview in subviews {
            let subviewSize = subview.sizeThatFits(.unspecified)
            
            // If it doesn't fit, wrap to next row
            if x + subviewSize.width > maxWidth {
                x = bounds.minX
                y += currentRowHeight + spacing
                currentRowHeight = 0
            }
            
            subview.place(at: CGPoint(x: x, y: y),
                          proposal: .unspecified)
            
            x += subviewSize.width + spacing
            currentRowHeight = max(currentRowHeight, subviewSize.height)
        }
    }
}

