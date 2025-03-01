//
//  FlipIcon.swift
//  TopNote
//
//  Created by Zachary Sturman on 2/27/25.
//

import Foundation
import SwiftUI

struct FlipIcon: View {
    var removeBorder: Bool = false
    var iconSize: CGFloat = 1
    
    var body: some View {
        if removeBorder {
            IconContainer(
                          overlaySymbol: "rectangle.2.swap",
                          overlayScale: iconSize)
            
        } else {
            
            
        
            IconContainer(baseSymbol: "rectangle",
                          overlaySymbol: "rectangle.2.swap",
                          overlayScale: 0.5)
            
            
        }
    }
}
