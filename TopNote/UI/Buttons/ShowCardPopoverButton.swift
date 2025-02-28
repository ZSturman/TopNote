//
//  ShowCardPopoverButton.swift
//  TopNote
//
//  Created by Zachary Sturman on 2/24/25.
//

import Foundation
import SwiftUI

struct ShowCardPopoverButton: View {
    @Binding var showInspector: Bool
    
    var body: some View {
        Button(action: {showInspector.toggle()}, label: {
            Image(systemName: "ellipsis")
                .frame(width: 32, height: 32)
        })
    }
}

