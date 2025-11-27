//
//  TagsSection.swift
//  TopNote
//
//  Created by Zachary Sturman on 3/1/25.
//


import SwiftUI
import SwiftData
import WidgetKit







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

