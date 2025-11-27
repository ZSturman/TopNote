//
//  TagButton.swift
//  TopNote
//
//  Created by Zachary Sturman on 11/27/25.
//

import SwiftUI

struct TagButton: View {
    let tag: CardTag
    let selectionState: TagSelectionState
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            Text(tag.name)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .font(.subheadline)
                .foregroundColor(foregroundColor)
                .background(backgroundColor)
                .cornerRadius(8)
        }
    }
    
    private var backgroundColor: Color {
        switch selectionState {
        case .neutral:
            return Color.gray.opacity(0.2)
        case .selected:
            return Color.green.opacity(0.2)
        case .deselected:
            return Color.red.opacity(0.2)
        }
    }
    
    private var foregroundColor: Color {
        switch selectionState {
        case .neutral:
            return .gray
        case .selected:
            return .green
        case .deselected:
            return .red
        }
    }
}
