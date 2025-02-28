//
//  FlashcardCard.swift
//  TopNote
//
//  Created by Zachary Sturman on 2/18/25.
//

import SwiftUI
import SwiftData

struct FlashCardForm: View {
    @Environment(\.modelContext) private var modelContext

    var card: Card

    var body: some View {
        Form {
            Section(header: Text("Front")) {
                TextField("Enter front content", text: Binding(
                    get: { card.content },
                    set: { newValue in
                        card.content = newValue
                        try? modelContext.save()
                    }
                ))
            }
            
            Section(header: Text("Back")) {
                TextField("Enter back content", text: Binding(
                    get: { card.back ?? "" },
                    set: { newValue in
                        card.back = newValue
                        try? modelContext.save()
                    }
                ))
            }
        }
    }
}
