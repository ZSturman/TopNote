//
//  NextIcon.swift
//  TopNote
//
//  Created by Zachary Sturman on 2/27/25.
//

import Foundation
import SwiftUI

struct NextIcon: View {
    var removeBorder: Bool = false
    var iconSize: CGFloat = 1
    
    var body: some View {
        if removeBorder {
            IconContainer(overlaySymbol: "checkmark.rectangle.stack",
                          overlayScale: iconSize)
        } else {
            
            
            
            IconContainer(baseSymbol: "rectangle",
                          overlaySymbol: "checkmark.rectangle.stack",
                          overlayScale: 0.5)
        }
        
    }
}
