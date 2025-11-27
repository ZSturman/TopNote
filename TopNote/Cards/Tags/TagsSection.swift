//
//  TagsSection.swift
//  TopNote
//
//  Created by Zachary Sturman on 11/27/25.
//

import SwiftUI

struct TagsSection: View {
    @Environment(\.modelContext) private var modelContext
    
    var tags: [CardTag]
    @Binding var tagSelectionStates: [UUID: TagSelectionState]
    
    @State private var showEditTagsSheet = false
    
    var body: some View {
        Section(header:
            HStack {
                Text("Tags")
                Spacer()
                Button("Edit Tags") {
                    showEditTagsSheet = true
                }
            }
        ) {
            // A scroll view so we can see wrapping if the list of tags gets longer
            ScrollView(.vertical) {
                FlowLayout(spacing: 8) {
                    ForEach(tags.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }) { tag in
                        let currentState = tagSelectionStates[tag.id] ?? .neutral
                        
                        TagButton(tag: tag,
                                  selectionState: currentState) {
                            // Cycle the state on tap
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
                        .contextMenu {
                            Button(role: .destructive) {
                                modelContext.delete(tag)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
                .padding(.vertical, 8)
            }
        }
        .sheet(isPresented: $showEditTagsSheet) {
            EditTagsSheet()
        }
    }
}
