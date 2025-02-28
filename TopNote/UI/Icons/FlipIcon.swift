//
//  FlipIcon.swift
//  TopNote
//
//  Created by Zachary Sturman on 2/27/25.
//

import Foundation
import SwiftUI

struct FlipIcon: View {
    var body: some View {

            IconContainer(baseSymbol: "rectangle",
                        overlaySymbol: "rectangle.2.swap",
                        overlayScale: 0.5)
           
        
    }
}
