//
//  EnqueuedSection.swift
//  TopNote
//
//  Created by Zachary Sturman on 3/1/25.
//

import Foundation
import SwiftUI
import SwiftData

struct EnqueuedSection: View {
    @Environment(\.modelContext) private var modelContext
    var enqueuedCardsSorted: [Card]
    
    var body: some View {
        Section(header: Text("Enqueue")) {
            ForEach(enqueuedCardsSorted) { card in
                NavigationLink(value: card) {
                    HStack {
                        SelectedCardType(cardType: card.cardType)
                        Text(card.content)
                            .lineLimit(1)
                    }
                }
                .contextMenu {
                    
                    Button {
                        Task {
                            do {
                                if card.isEssential {
                                    try await card.removeFromQueue(at: Date(), isSkip: true)
                                } else {
                                    try await card.removeFromQueue(at: Date(), isSkip: false)
                                }
                            } catch {
                                print("Error removing card from archive: \(error)")
                            }
                        }
                    } label: {
                        if card.isEssential {
                            Label("Skip", systemImage: "arrow.trianglehead.counterclockwise.rotate.90")
                        } else {
                            Label("Next", systemImage: "checkmark.rectangle.stack")
                        }
                    }
                    
                    
                    Button {
                        Task {
                            do {
                                try await card.removeFromQueue(at: Date(), isSkip: false, toArchive: true)
                            } catch {
                                print("Error removing card from archive: \(error)")
                            }
                        }
                    } label: {
                        Label("Archive", systemImage: "archivebox")
                    }
                    

                    
                    Divider()

                    Button(role: .destructive) {
                        modelContext.delete(card)
                        
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                 
                }
                .swipeActions(edge: .leading) {
                    Button(action: {
                        Task {
                            do {
                                try await card.removeFromQueue(at: Date(), isSkip: false, toArchive: true)
                            } catch {
                                print("Error removing card from archive: \(error)")
                            }
                        }
                    }) {
                        Label("Archive", systemImage: "archive")
                    }
                    
                    Button(action: {
                        Task {
                            do {
                                if card.isEssential {
                                    try await card.removeFromQueue(at: Date(), isSkip: true)
                                } else {
                                    try await card.removeFromQueue(at: Date(), isSkip: false)
                                }
                               
                            } catch {
                                print("Error removing card from archive: \(error)")
                            }
                        }
                    }) {
                        if card.isEssential {
                            Label("Skip", systemImage: "arrow.trianglehead.counterclockwise.rotate.90")
                        } else {
                            Label("Next", systemImage: "checkmark.rectangle.stack")
                            
                        }
                      
                    }
                }
                
                
                .swipeActions(edge: .trailing) {
                    Button(role: .destructive) {
                   
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                    
                    
                }
            }
        }
    }
}
