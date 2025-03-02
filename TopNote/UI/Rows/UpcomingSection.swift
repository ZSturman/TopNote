//
//  UpcomingSection.swift
//  TopNote
//
//  Created by Zachary Sturman on 3/1/25.
//

import Foundation
import SwiftUI
import SwiftData

struct UpcomingSection: View {
    @Environment(\.modelContext) private var modelContext
    var upcomingCardsSorted: [Card]
    
    var body: some View {
        Section(header: Text("Upcoming")) {
            ForEach(upcomingCardsSorted) { card in
                NavigationLink(value: card) {
                    HStack {
                        SelectedCardType(cardType: card.cardType)
                        Text(card.content)
                            .lineLimit(1)
                    }
                }
                .contextMenu {
                    Button(action: {
                        Task {
                            do {
                                try await card.addCardToQueue(currentDate: Date())
                            } catch {
                                print("Error removing card from archive: \(error)")
                            }
                        }
                    }) {
                        Label("Enqueue", systemImage: "rectangle.stack")
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
                                try await card.addCardToQueue(currentDate: Date())
                            } catch {
                                print("Error removing card from archive: \(error)")
                            }
                        }
                    }) {
                        Label("Enqueue", systemImage: "rectangle.stack")
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
