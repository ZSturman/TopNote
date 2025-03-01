//
//  EnqueueIcon.swift
//  TopNote
//
//  Created by Zachary Sturman on 2/27/25.
//

import Foundation

import SwiftUI

struct EnqueueIcon: View {
    var iconSize: CGFloat = 1
    
    var body: some View {
        IconContainer(overlaySymbol: "rectangle.stack", overlayScale: iconSize)
    }
}


