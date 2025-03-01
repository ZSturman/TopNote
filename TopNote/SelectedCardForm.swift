//
//  CardForm.swift
//  TopNote
//
//  Created by Zachary Sturman on 2/27/25.
//

import Foundation
import SwiftUI

enum FormField: Hashable {
    case content
    case backContent
    case tags
    case spacedRepetitionInterval
    
    
}

struct SelectedCardForm: View {
    @Environment(\.modelContext) private var modelContext
    var card: Card
    var isNew: Bool = false
    @State private var isEditingSpacedRepetition = false
    @FocusState private var focusedField: FormField?
    var iconSize: CGFloat = 30
    
    var body: some View {
        VStack {
            Form {
                if card.cardType == .flashCard {
                    Section("Front") {
                        ContentInput(card: card, focusedField: $focusedField)
                    }
                    Section("Back") {
                        BackContentInput(card: card, focusedField: $focusedField)
                    }
                } else {
                    Section("Content") {
                        ContentInput(card: card, focusedField: $focusedField)
                    }
                }
                
                Section("Spaced repetition") {
                    HStack {
                        if isEditingSpacedRepetition {
                            SpacedTimeframeInputView(card: card, onFinished: {
                                isEditingSpacedRepetition = false
                            })
                            .id(card.spacedTimeFrame)
                        } else {
                            ReadOnlySpacedTimeframe(card: card)
                               .contentShape(Rectangle())
                               .onTapGesture {
                                   focusedField = nil
                                   isEditingSpacedRepetition = true
                               }
                        }
                    }
                }
                
                // 4. Single line text input
                Section("Tags") {
                    TagInputView(card: card)
                }
                
                Section("Type") {
                    CardTypePicker(card: card)
                    PriorityPickerView(card: card)
                }
                
                Section(header: Text("Essential"),
                        footer: Text("This toggle indicates whether the item is essential.")) {
                    IsEssentialToggle(card: card)
                }
                
                Section(header: Text("Dynamic"),
                        footer: Text("This toggle indicates whether the item is dynamic.")) {
                    IsDynamicToggle(card: card)
                }
                
                Section {
                    Button(role: .destructive) {
                        modelContext.delete(card)
                    } label: {
                        HStack {
                            Spacer()
                            Image(systemName: "trash")
                            Text("Delete")
                            Spacer()
                        }
                    }
                }
            }
            .toolbar {
                if focusedField != .tags {
                    ToolbarItem(placement: .keyboard) {
                        Button("Done") {
                            focusedField = nil
                        }
                    }
                }
            }
        }
        .onAppear {
            if isNew {
                focusedField = .content
            }
        }
        .onDisappear {
            focusedField = nil
        }
        
    }
    
    
    private func editSpacedTimeframe() {
        focusedField = nil
        isEditingSpacedRepetition = true
    }
    
    
}


#if DEBUG
struct ContentView2_Previews: PreviewProvider {
    static var previews: some View {
        
        // Preview with a dummy card
        SelectedCardForm(card: Card.preview)
            .previewDisplayName("With Card")
            .previewLayout(.sizeThatFits)
    }
    
}

#endif
