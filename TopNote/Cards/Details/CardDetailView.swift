//
//  CardDetailView.swift
//  TopNote
//
//  Created by Zachary Sturman on 8/6/25.
//

// Features/Cards/Detail/CardDetailView.swift
import SwiftUI
import SwiftData
import TipKit

struct CardDetailView: View {
    var card: Card
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) var context

    var moveAction: () -> Void
    var tagAction: () -> Void

    @Query var folders: [Folder]
    @Query var tags: [CardTag]

    @State var showDeleteConfirm = false
    @State var showShareSheet = false
    @State var exportedFileURL: URL?

    @State var showOrganize = true
    @State var showTiming = false
    @State var showPolicies = false
    @State var showHistory = false

    @State var showMoveFullScreen = false
    @State var showTagFullScreen = false

    var body: some View {
        NavigationStack {
            Form {
                CardDetailContentSection(card: card)
                
                CardDetailAnswerSection(card: card)

                CardDetailOrganizeSection(
                    card: card,
                    folders: folders,
                    tags: tags,
                    isExpanded: $showOrganize,
                    showMoveFullScreen: $showMoveFullScreen,
                    showTagFullScreen: $showTagFullScreen
                )

                CardDetailTimingSection(
                    card: card,
                    isExpanded: $showTiming
                )

                CardDetailPoliciesSection(
                    card: card,
                    isExpanded: $showPolicies
                )

                CardDetailHistorySection(
                    card: card,
                    isExpanded: $showHistory
                )
                
                Section {
                    CardDetailBottomActions(
                        card: card,
                        showDeleteConfirm: $showDeleteConfirm
                    )
                }
            }
            .navigationTitle("Details")
            .navigationBarTitleDisplayMode(.inline)
            .onDisappear { try? context.save() }
            .toolbar { toolbarContent }
            .confirmationDialog(
                "Are you sure you want to delete this card?",
                isPresented: $showDeleteConfirm,
                titleVisibility: .visible
            ) {
                Button("Delete", role: .destructive) { deleteCard() }
                Button("Cancel", role: .cancel) {}
            }
            .fullScreenCover(isPresented: $showMoveFullScreen) {
                NavigationStack { UpdateCardFolderView(card: card) }
            }
            .fullScreenCover(isPresented: $showTagFullScreen) {
                NavigationStack { AddNewTagSheet(card: card) }
            }
            .sheet(isPresented: $showShareSheet) {
                if let exportedFileURL {
                    ShareSheet(activityItems: [exportedFileURL])
                }
            }
        }
    }
}


