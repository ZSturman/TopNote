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
                
                Section("Tags") {
                    TagInputView(card: card)
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
                    if card.archived {
                        Button() {
                            Task {
                                do {
                                    try await card.removeCardFromArchive()
                                } catch {
                                    print("Error removing card from queue: \(error)")
                                }
                            }
                        } label: {
                            HStack {
                                Spacer()
                                Image(systemName: "tray.and.arrow.up")
                                Text("Archive")
                                Spacer()
                            }
                        }
                    
                    } else {
                        
                        
                        Button() {
                            Task {
                                do {
                                    try await card.removeFromQueue(at: Date(), isSkip: false, toArchive: true)
                                } catch {
                                    print("Error removing card from queue: \(error)")
                                }
                            }
                        } label: {
                            HStack {
                                Spacer()
                                Image(systemName: "archivebox")
                                Text("Archive")
                                Spacer()
                            }
                        }
                    }
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
