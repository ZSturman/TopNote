//
//  TagsSection.swift
//  TopNote
//
//  Created by Zachary Sturman on 3/1/25.
//

import Foundation
import SwiftUI
import SwiftData

struct TagsSection: View {
    @Environment(\.modelContext) private var modelContext
    var tags: [Tag]
    @Binding var tagSelectionStates:  [UUID: TagSelectionState]
    
    
    var body: some View {
        Section(header: Text("Tags")) {
            ForEach(tags.sorted { $0.name < $1.name }) { tag in
                HStack {
                    Text(tag.name)
                    // Show a textual indicator of the current tag state.
                    switch tagSelectionStates[tag.id] ?? .neutral {
                    case .neutral:
                        Text("Neutral")
                            .foregroundColor(.gray)
                    case .selected:
                        Text("Selected")
                            .foregroundColor(.green)
                    case .deselected:
                        Text("Deselected")
                            .foregroundColor(.red)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    // Cycle the state: neutral -> selected -> deselected -> neutral.
                    let currentState = tagSelectionStates[tag.id] ?? .neutral
                    let newState: TagSelectionState
                    switch currentState {
                    case .neutral:
                        newState = .selected
                    case .selected:
                        newState = .deselected
                    case .deselected:
                        newState = .neutral
                    }
                    tagSelectionStates[tag.id] = newState
                }
                .swipeActions(edge: .trailing) {
                    Button(role: .destructive) {
                        modelContext.delete(tag)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                    
                }
            }
        }
    }
}
