//
//  SelectedCardView.swift
//  TopNote
//
//  Created by Zachary Sturman on 2/22/25.
//
import Foundation
import SwiftData
import SwiftUI

struct SelectedCardView: View {
    @Environment(\.modelContext) private var modelContext
    var card: Card?
    var onAddCard: () -> Void
    var isNew: Bool =  false
    @State private var showingTagSelection: Bool = false
    @State private var showingSpacedTimeframeOptions: Bool = false

    
    var body: some View {
        VStack {
            if let card = card {
                SelectedCardForm(card: card, isNew:isNew)
            }
        }
        .id(card?.id)
        .padding()
        .toolbar {
            if let card = card {
                    ToolbarItemGroup(placement: .automatic) {
                        Spacer()
                        selectedCardToolbar(card: card)
                    }
         
            }
        }
    }
    
    @ViewBuilder
    private func selectedCardToolbar(card: Card) -> some View {
        
        let iconSize: CGFloat = 35
        
        HStack {
            QueueOptions(card: card, iconSize:iconSize)
            
            Spacer()
            if UIDevice.current.userInterfaceIdiom == .phone {
                Button {
                    DispatchQueue.main.async {
                        onAddCard()
                    }
                } label: {
                    Image(systemName: "square.and.pencil")
                }
            }
        }
    }
}


#if DEBUG
struct SelectedCardView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            
            // Preview with a dummy card
            SelectedCardView(card: Card.preview, onAddCard: {})
                .previewDisplayName("With Card")
                .previewLayout(.sizeThatFits)
        }
        
    }
}
#endif

#if DEBUG
extension Card {
    static var preview: Card {
        return Card(
            createdAt: Date(),
            cardType: .flashCard,
            priorityTypeRaw: .none,
            isEssential: true,
            skipCount: 1,
            seenCount: 5,
            archived: true
            
        )
    }
}
#endif
