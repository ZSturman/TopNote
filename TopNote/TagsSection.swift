//
//  TagsSection.swift
//  TopNote
//
//  Created by Zachary Sturman on 3/1/25.
//

// Tag comparisons are now case-insensitive and whitespace-trimmed, duplicates prevented and tags can be edited.

import SwiftUI
import SwiftData
import WidgetKit


struct FlowLayout: Layout {
    // You can customize spacing and alignment if desired.
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize,
                      subviews: Subviews,
                      cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var width: CGFloat = 0
        var height: CGFloat = 0
        
        var currentRowWidth: CGFloat = 0
        var currentRowHeight: CGFloat = 0
        
        for subview in subviews {
            let subviewSize = subview.sizeThatFits(.unspecified)
            
            // If this subview doesn't fit in the current row, move to the next row
            if currentRowWidth + subviewSize.width > maxWidth {
                width = max(width, currentRowWidth)
                height += currentRowHeight + spacing
                currentRowWidth = subviewSize.width
                currentRowHeight = subviewSize.height
            } else {
                currentRowWidth += subviewSize.width + spacing
                currentRowHeight = max(currentRowHeight, subviewSize.height)
            }
        }
        
        width = max(width, currentRowWidth)
        height += currentRowHeight
        
        return CGSize(width: width, height: height)
    }
    
    func placeSubviews(in bounds: CGRect,
                       proposal: ProposedViewSize,
                       subviews: Subviews,
                       cache: inout ()) {
        let maxWidth = bounds.width
        var x = bounds.minX
        var y = bounds.minY
        var currentRowHeight: CGFloat = 0
        
        for subview in subviews {
            let subviewSize = subview.sizeThatFits(.unspecified)
            
            // If it doesn't fit, wrap to next row
            if x + subviewSize.width > maxWidth {
                x = bounds.minX
                y += currentRowHeight + spacing
                currentRowHeight = 0
            }
            
            subview.place(at: CGPoint(x: x, y: y),
                          proposal: .unspecified)
            
            x += subviewSize.width + spacing
            currentRowHeight = max(currentRowHeight, subviewSize.height)
        }
    }
}

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

struct EditTagsSheet: View {
    @Environment(\.modelContext) var modelContext
    @Environment(\.dismiss) var dismiss
    @Query var tags: [CardTag]
    
    @State private var editingTagIDs: Set<UUID> = []
    @State private var editedNames: [UUID: String] = [:]
    @State private var errors: [UUID: String] = [:]
    
    var body: some View {
        NavigationView {
            List {
                ForEach(tags.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }) { tag in
                    HStack {
                        if editingTagIDs.contains(tag.id) {
                            TextField("Tag name", text: Binding(
                                get: {
                                    editedNames[tag.id] ?? tag.name
                                },
                                set: { newValue in
                                    editedNames[tag.id] = newValue
                                    validateName(newValue, for: tag)
                                }
                            ))
                            .textFieldStyle(.roundedBorder)
                            .autocorrectionDisabled(true)
                            .autocapitalization(.none)
                            
                            if let error = errors[tag.id] {
                                Text(error)
                                    .font(.caption)
                                    .foregroundColor(.red)
                                    .lineLimit(1)
                                    .padding(.leading, 4)
                            }
                        } else {
                            Text(tag.name)
                        }
                        Spacer()
                        if editingTagIDs.contains(tag.id) {
                            Button {
                                commitEdit(for: tag)
                            } label: {
                                Text("Save")
                            }
                            .disabled(errors[tag.id] != nil || ((editedNames[tag.id]?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true)))
                            
                            Button(role: .cancel) {
                                cancelEdit(for: tag)
                            } label: {
                                Text("Cancel")
                            }
                        } else {
                            Button("Edit") {
                                startEdit(for: tag)
                            }
                        }
                        
                        Button(role: .destructive) {
                            modelContext.delete(tag)
                        } label: {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("Edit Tags")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func startEdit(for tag: CardTag) {
        editingTagIDs.insert(tag.id)
        editedNames[tag.id] = tag.name
        errors[tag.id] = nil
    }
    
    private func cancelEdit(for tag: CardTag) {
        editingTagIDs.remove(tag.id)
        editedNames[tag.id] = nil
        errors[tag.id] = nil
    }
    
    private func commitEdit(for tag: CardTag) {
        guard let newName = editedNames[tag.id]?.trimmingCharacters(in: .whitespacesAndNewlines), !newName.isEmpty else {
            errors[tag.id] = "Name cannot be empty"
            return
        }
        let lowercasedNewName = newName.lowercased()
        
        // Check for duplicates (case-insensitive, trimmed), excluding current tag
        let duplicate = tags.contains { existingTag in
            existingTag.id != tag.id &&
            existingTag.name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == lowercasedNewName
        }
        if duplicate {
            errors[tag.id] = "Duplicate name"
            return
        }
        
        // Commit change
        tag.name = newName
        do {
            try modelContext.save()
            DispatchQueue.main.async {
                cancelEdit(for: tag)
            }
        } catch {
            // Handle save error here if needed
        }
    }
    
    private func validateName(_ name: String, for tag: CardTag) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            errors[tag.id] = "Name cannot be empty"
            return
        }
        let lowercasedNewName = trimmed.lowercased()
        let duplicate = tags.contains { existingTag in
            existingTag.id != tag.id &&
            existingTag.name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == lowercasedNewName
        }
        if duplicate {
            errors[tag.id] = "Duplicate name"
        } else {
            errors[tag.id] = nil
        }
    }
}

