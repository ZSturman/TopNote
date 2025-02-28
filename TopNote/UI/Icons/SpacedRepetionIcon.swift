//
//  SpacedRepetionIcon.swift
//  TopNote
//
//  Created by Zachary Sturman on 2/27/25.
//

import Foundation
import SwiftUI

struct SpacedRepitionTimeframeIcon: View {
    var body: some View {
        // Dynamic: arrow.triangle.2.circlepath + bolt.fill
 
            IconContainer(                    baseSymbol: "arrow.2.circlepath",
                                              overlaySymbol: "hourglass.bottomhalf.fill",
                                              overlayScale: 0.3)
              
        
    }
}
