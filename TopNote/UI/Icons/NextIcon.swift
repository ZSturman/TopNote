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
    
    var body: some View {
        if removeBorder {
            IconContainer(baseSymbol: "",
                          overlaySymbol: "checkmark.rectangle.stack",
                          overlayScale: 1.2)
        } else {
            
            
            
            IconContainer(baseSymbol: "rectangle",
                          overlaySymbol: "checkmark.rectangle.stack",
                          overlayScale: 0.5)
        }
        
    }
}
