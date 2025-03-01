//
//  TagIcon.swift
//  TopNote
//
//  Created by Zachary Sturman on 2/27/25.
//

import Foundation
import SwiftUI

struct TagIcon: View {
    var iconSize: CGFloat = 1
    var body: some View {
   
 
            IconContainer(
                                              overlaySymbol: "tag",
                                              overlayScale: iconSize)
            
        
    }
}
