//
//  TagInputView.swift
//  TopNote
//
//  Created by Zachary Sturman on 2/23/25.
//

import SwiftUI
import SwiftData
import WidgetKit

struct TagInputView: View {
    @Environment(\.modelContext) private var modelContext
    // Query all tags from your data store.
    @Query private var allTags: [Tag]
    
    var card: Card
    
    @State private var newTag: String = ""
    @FocusState private var isTagFieldFocused: Bool
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    // Return all available tags (if no input) or filter based on input.
    private var availableTags: [Tag] {
        let trimmedInput = newTag.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return allTags.filter { tag in
            let isAlreadyAdded = card.unwrappedTags.contains(where: { $0.id == tag.id })
            if trimmedInput.isEmpty {
                return !isAlreadyAdded
            } else {
                return tag.name.lowercased().contains(trimmedInput) && !isAlreadyAdded
            }
        }
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            TextField("Add a tag", text: $newTag, onCommit: {
                addTag()
                
            })
            .textFieldStyle(RoundedBorderTextFieldStyle())
            .focused($isTagFieldFocused)
            
            // For non-compact devices, show suggestions as a dropdown below the text field.
            if horizontalSizeClass != .compact, isTagFieldFocused, !availableTags.isEmpty {
                TagSuggestionsView(tags: availableTags) { tag in
                    addExistingTag(tag)
                }
                .transition(.opacity)
                .animation(.easeInOut, value: availableTags)
            }
            
            // Display the tags already added to the card.
            if !card.unwrappedTags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(card.unwrappedTags, id: \.id) { tag in
                            HStack(spacing: 4) {
                                Text(tag.name)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.gray.opacity(0.2))
                                    .cornerRadius(8)
                                Button(action: { removeTag(tag) }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.red)
                                }
                                .accessibilityLabel("Remove \(tag.name)")
                            }
                        }
                    }
                }
            }
        }
        .padding(.horizontal)
        // Tap on the background dismisses focus.
        .background(
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture {
                    isTagFieldFocused = false
                }
        )
        // For compact devices, add a toolbar with a Done button to dismiss focus.
        .toolbar {
            if horizontalSizeClass == .compact, isTagFieldFocused {
                ToolbarItem(placement: .keyboard) {
                    HStack {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack {
                                ForEach(availableTags, id: \.id) { tag in
                                    Button(action: {
                                        addExistingTag(tag)
                                    }) {
                                        Text(tag.name)
                                            .padding(8)
                                            .background(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .fill(Color.blue.opacity(0.2))
                                            )
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                        }
                        Button("Done") {
                            isTagFieldFocused = false
                        }
                    }
                }
            }
        }
    }
    
    private func addTag() {
        let trimmed = newTag.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        let tag = getOrCreateTag(withName: trimmed)
        if !card.unwrappedTags.contains(where: { $0.id == tag.id }) {
            if card.tags == nil {
                card.tags = [tag]
            } else {
                card.tags?.append(tag)
            }
        }
        newTag = ""
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    private func addExistingTag(_ tag: Tag) {
        if !card.unwrappedTags.contains(where: { $0.id == tag.id }) {
            if card.tags == nil {
                card.tags = [tag]
            } else {
                card.tags?.append(tag)
            }
        }
        newTag = ""
        WidgetCenter.shared.reloadAllTimelines()

    }
    
    private func removeTag(_ tag: Tag) {
        card.tags?.removeAll { $0.id == tag.id }
        if tag.unwrappedCards.isEmpty {
            modelContext.delete(tag)
        }
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    private func getOrCreateTag(withName name: String) -> Tag {
        let normalizedName = name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if let existingTag = allTags.first(where: {
            $0.name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == normalizedName
        }) {
            return existingTag
        }
        let newTag = Tag(name: name)
        modelContext.insert(newTag)
        WidgetCenter.shared.reloadAllTimelines()
        return newTag
    }
}

struct TagSuggestionsView: View {
    let tags: [Tag]
    let onSelect: (Tag) -> Void
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: true) {
            LazyVStack(alignment: .leading, spacing: 4) {
                ForEach(tags, id: \.id) { tag in
                    Button(action: {
                        onSelect(tag)
                    }) {
                        Text(tag.name)
                            .padding(10)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.blue.opacity(0.1))
                            )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(8)
        }
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.systemBackground))
        )
        .shadow(radius: 4)
        .padding(.vertical, 4)
    }
}
