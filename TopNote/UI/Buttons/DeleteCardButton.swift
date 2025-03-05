//
//  DeleteCardButton.swift
//  TopNote
//
//  Created by Zachary Sturman on 2/24/25.
//

import Foundation
import SwiftUI
import SwiftData

struct DeleteCardButton: View {
    @Environment(\.modelContext) private var modelContext
    var card: Card
    
    var body: some View {
        Button(role: .destructive) {
            modelContext.delete(card)
            
        } label: {
            Label("Delete", systemImage: "trash")
        }
        .help("Delete this card")
    }
}
