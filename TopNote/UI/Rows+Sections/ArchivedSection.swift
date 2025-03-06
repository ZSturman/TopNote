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
    @Query var folders: [Folder]
    
    @State private var cardForFolderChange: Card?
    @State private var selectedFolder: Folder?

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
                    UnarchiveButton(card: card)
                    MoveToFolderPicker(card: card)
                    Divider()
                    DeleteCardButton(card: card)
                    
                }
                .swipeActions(edge: .leading) {
                    UnarchiveButton(card: card)
                    Button {
                        // Set the card to update and initialize the selected folder.
                        cardForFolderChange = card
                        selectedFolder = card.folder
                    } label: {
                        Label("Move", systemImage: "folder")
                    }
                    .tint(.blue)
                    
                }
                .swipeActions(edge: .trailing) {
                    DeleteCardButton(card: card)
          
                }
            }
            
        }
        // Present a sheet when a card is selected for folder change.
        .sheet(item: $cardForFolderChange) { card in
            FolderPickerView(card: card,
                             folders: folders,
                             selectedFolder: $selectedFolder)
        }
    }
    
}
