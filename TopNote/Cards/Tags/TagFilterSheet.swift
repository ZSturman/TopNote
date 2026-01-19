//
//  TagFilterSheet.swift
//  TopNote
//
//  Created by Zachary Sturman on 1/7/26.
//

import SwiftUI

/// A reusable sheet for filtering by tags, with tri-state selection and Edit Tags access.
/// Used identically from both the sidebar and the CardListView filter menu.
struct TagFilterSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    var tags: [CardTag]
    @Binding var tagSelectionStates: [UUID: TagSelectionState]
    
    @State private var showEditTagsSheet = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Instructions
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Tap to cycle: neutral → include → exclude")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        HStack(spacing: 12) {
                            HStack(spacing: 4) {
                                Circle().fill(Color.gray.opacity(0.3)).frame(width: 8, height: 8)
                                Text("Neutral").font(.caption2).foregroundColor(.secondary)
                            }
                            HStack(spacing: 4) {
                                Circle().fill(Color.green).frame(width: 8, height: 8)
                                Text("Include").font(.caption2).foregroundColor(.secondary)
                            }
                            HStack(spacing: 4) {
                                Circle().fill(Color.red).frame(width: 8, height: 8)
                                Text("Exclude").font(.caption2).foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                    
                    // Tags flow layout
                    if tags.isEmpty {
                        VStack(spacing: 8) {
                            Text("No tags yet")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            Text("Create tags by adding them to cards, or use Edit Tags.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                    } else {
                        FlowLayout(spacing: 8) {
                            ForEach(tags.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }) { tag in
                                let currentState = tagSelectionStates[tag.id] ?? .neutral
                                
                                TagButton(tag: tag, selectionState: currentState) {
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
                        .padding(.horizontal)
                    }
                    
                    Spacer(minLength: 20)
                }
            }
            .navigationTitle("Filter by Tags")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("Edit Tags") {
                        showEditTagsSheet = true
                    }
                }
            }
            .sheet(isPresented: $showEditTagsSheet) {
                EditTagsSheet()
            }
        }
    }
}
