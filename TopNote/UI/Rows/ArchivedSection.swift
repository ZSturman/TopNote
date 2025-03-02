//
//  ArchivedSection.swift
//  TopNote
//
//  Created by Zachary Sturman on 3/1/25.
//

import Foundation
import SwiftUI
import SwiftData

struct ArchivedSection: View {
    @Environment(\.modelContext) private var modelContext
    var archivedCardsSorted: [Card]
    

    var body: some View {
        Section(header: Text("Archived")) {
            ForEach(archivedCardsSorted) { card in
                NavigationLink(value: card) {
                    HStack {
                        SelectedCardType(cardType: card.cardType)
                        Text(card.content)
                            .lineLimit(1)
                    }
                }.contextMenu {
                    Button(action: {
                        Task {
                            do {
                                try await card.removeCardFromArchive()
                            } catch {
                                print("Error removing card from archive: \(error)")
                            }
                        }
                    }) {
                        Label("Unarchive", systemImage: "tray.and.arrow.up")
                    }
                    
                }
                .swipeActions(edge: .leading) {
                    Button(action: {
                        Task {
                            do {
                                try await card.removeCardFromArchive()
                            } catch {
                                print("Error removing card from archive: \(error)")
                            }
                        }
                    }) {
                        Label("Unarchive", systemImage: "tray.and.arrow.up")
                    }
                }
                .swipeActions(edge: .trailing) {
                    Button(role: .destructive) {
                        modelContext.delete(card)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
          
                }
            }
            
        }
    }
    
}
