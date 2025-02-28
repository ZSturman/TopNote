//
//  DynamicIcon.swift
//  TopNote
//
//  Created by Zachary Sturman on 2/27/25.
//

import Foundation
import SwiftUI

struct DynamicIcon: View {
    var body: some View {
        // Dynamic: arrow.triangle.2.circlepath + bolt.fill
 
            IconContainer(baseSymbol: "arrow.triangle.2.circlepath",
                        overlaySymbol: "bolt.fill",
                        overlayScale: 0.5)
          
        
    }
}
