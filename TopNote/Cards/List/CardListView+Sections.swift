//
//  CardListView+Sections.swift
//  TopNote
//
//  Created by Zachary Sturman on 11/27/25.
//

import Foundation
import TipKit
import SwiftUI

extension CardListView {
    
    var emptyStatusFilterView: some View {
        VStack(spacing: 8) {
            Text("No statuses selected")
                .font(.headline)
            Text("Enable Queue, Upcoming, or Archived in Filters to see your cards here.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .font(.subheadline)
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.vertical, 16)
    }
    
    
    var queueSection: some View {
        Section(
            header:
                HStack {
                    Text("Queue")
                    Text("(\(queueCards.count))")
                        .foregroundColor(.secondary)
                        .font(.subheadline)
                    Spacer()
                    Image(
                        systemName: isQueueExpanded
                            ? "chevron.down" : "chevron.right"
                    )
                }
                .contentShape(Rectangle())
                .onTapGesture { isQueueExpanded.toggle() }
                // Added id for queue section header for scrolling
                .id("queue-section")
                .accessibilityIdentifier("QueueSectionHeader")
        ) {
            if isQueueExpanded {
                if queueCards.isEmpty {
                    Text("No cards in Queue")
                        .foregroundColor(.secondary)
                        .padding(.vertical, 16)
                        .frame(maxWidth: .infinity)
                } else {
                    CardStatusSection(
                        title: "Queue",
                        cards: queueCards,
                        folders: folders,
                        onDelete: delete,
                        onPriorityChanged: { cardID in
                            priorityChangedForCardID = cardID
                        },
                        priorityChangedForCardID: priorityChangedForCardID,
                        lastDeselectedCardID: lastDeselectedCardID
                    )
                    .environment(\.ascending, ascending)
                    .popoverTip(firstQueueCardTip, arrowEdge: .top)
                    .onAppear {
                        if !hasViewedQueueCard && !queueCards.isEmpty {
                            hasViewedQueueCard = true
                            Task {
                                await FirstQueueCardTip.viewedFirstQueueCardEvent.donate()
                            }
                        }
                    }
                }
            }
        }
        .padding(.bottom, isQueueExpanded ? 0 : 8)  // Add padding only when expanded
    }
    var upcomingSection: some View {
        Section(
            header:
                HStack {
                    Text("Upcoming")
                    Text("(\(upcomingCards.count))")
                        .foregroundColor(.secondary)
                        .font(.subheadline)
                    Spacer()
                    Image(
                        systemName: isUpcomingExpanded
                            ? "chevron.down" : "chevron.right"
                    )
                }
                .contentShape(Rectangle())
                .onTapGesture { isUpcomingExpanded.toggle() }
                // Added id for upcoming section header for scrolling
                .id("upcoming-section")
                .accessibilityIdentifier("UpcomingSectionHeader")
        ) {
            if isUpcomingExpanded {
                if upcomingCards.isEmpty {
                    Text("No cards in Upcoming")
                        .foregroundColor(.secondary)
                        .padding(.vertical, 16)
                        .frame(maxWidth: .infinity)
                }
                CardStatusSection(
                    title: "Upcoming",
                    cards: upcomingCards,
                    folders: folders,
                    onDelete: delete,
                    onPriorityChanged: { cardID in
                        priorityChangedForCardID = cardID
                    },
                    priorityChangedForCardID: priorityChangedForCardID,
                    lastDeselectedCardID: lastDeselectedCardID
                )
                .environment(\.ascending, ascending)
            }
        }
        .padding(.bottom, isUpcomingExpanded ? 0 : 8)
    }
    var archivedSection: some View {
        Section(
            header:
                HStack {
                    Text("Archived")
                    Text("(\(archivedCards.count))")
                        .foregroundColor(.secondary)
                        .font(.subheadline)
                    Spacer()
                    Image(
                        systemName: isArchivedExpanded
                            ? "chevron.down" : "chevron.right"
                    )
                }
                .contentShape(Rectangle())
                .onTapGesture { isArchivedExpanded.toggle() }
                .accessibilityIdentifier("ArchivedSectionHeader")
        ) {
            if isArchivedExpanded {
                if archivedCards.isEmpty {
                    Text("No cards in Archived")
                        .foregroundColor(.secondary)
                        .padding(.vertical, 16)
                        .frame(maxWidth: .infinity)
                }
                CardStatusSection(
                    title: "Archived",
                    cards: archivedCards,
                    folders: folders,
                    onDelete: delete,
                    onPriorityChanged: { cardID in
                        priorityChangedForCardID = cardID
                    },
                    priorityChangedForCardID: priorityChangedForCardID,
                    lastDeselectedCardID: lastDeselectedCardID
                )
                .environment(\.ascending, ascending)
            }
        }
        .padding(.bottom, isArchivedExpanded ? 0 : 8)
    }

    
    var createdAtSection: some View {
        List {
            if !selectedCardModel.isNewlyCreated {
                TipView(addWidgetTip)
            }
            TipView(customizeWidgetTip)
            ForEach(sortedKeys.indices, id: \.self) { idx in
                let day = sortedKeys[idx]
                Section(header: Text(displayDateHeader(for: day))) {
                    let cardsForDay = groupedByDay[day] ?? []
                    ForEach(cardsForDay) { card in
                        if selectionMode {
                            HStack {
                                Image(
                                    systemName: selectedCards.contains(
                                        card
                                    )
                                        ? "checkmark.circle.fill"
                                        : "circle"
                                )
                                .foregroundColor(
                                    selectedCards.contains(card)
                                        ? .accentColor : .secondary
                                )
                                CardRow(card: card, folders: folders, lastDeselectedCardID: lastDeselectedCardID)
                                    // Added id for card row for scrolling
                                    .id(card.id)
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                if selectedCards.contains(card) {
                                    selectedCards.remove(card)
                                } else {
                                    selectedCards.insert(card)
                                }
                            }
                        } else {
                            CardRow(
                                card: card,
                                folders: folders,
                                lastDeselectedCardID: lastDeselectedCardID
                            )
                            // Added id for card row for scrolling
                            .id(card.id)
                            .clipShape(
                                RoundedRectangle(cornerRadius: 10)
                            )
                            .contentShape(Rectangle())
                            .onTapGesture { select(card) }
                            .accessibilityAddTraits(.isButton)
                            .animation(
                                .default,
                                value: selectedCardModel.selectedCard?
                                    .id
                            )
                        }
                    }
                    .onDelete { offsets in
                        delete(cards: cardsForDay, at: offsets)
                    }
                }
                if idx < sortedKeys.count - 1 {
                    Divider().padding(.vertical, 4)
                }
            }
        }
    }
    var skipCountSection: some View {
        List {
            let skipEnabledCards = filteredCards.filter {
                $0.skipEnabled
            }.sorted(by: {
                ascending
                    ? $0.skipCount < $1.skipCount
                    : $0.skipCount > $1.skipCount
            })
            let skipDisabledCards = filteredCards.filter {
                !$0.skipEnabled
            }.sorted(by: {
                ascending
                    ? $0.skipCount < $1.skipCount
                    : $0.skipCount > $1.skipCount
            })

            Section(header: Text("Cards")) {
                ForEach(skipEnabledCards) { card in
                    if selectionMode {
                        HStack {
                            Image(
                                systemName: selectedCards.contains(card)
                                    ? "checkmark.circle.fill" : "circle"
                            )
                            .foregroundColor(
                                selectedCards.contains(card)
                                    ? .accentColor : .secondary
                            )
                            CardRow(card: card, folders: folders)
                                // Added id for card row for scrolling
                                .id(card.id)
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if selectedCards.contains(card) {
                                selectedCards.remove(card)
                            } else {
                                selectedCards.insert(card)
                            }
                        }
                    } else {
                        CardRow(
                            card: card,
                            folders: folders
                        )
                        // Added id for card row for scrolling
                        .id(card.id)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .contentShape(Rectangle())
                        .onTapGesture { select(card) }
                        .accessibilityAddTraits(.isButton)
                        .animation(
                            .default,
                            value: selectedCardModel.selectedCard?.id
                        )
                    }
                }
                .onDelete { offsets in
                    delete(cards: skipEnabledCards, at: offsets)
                }
            }

            Section(header: Text("Skip Disabled")) {
                ForEach(skipDisabledCards) { card in
                    if selectionMode {
                        HStack {
                            Image(
                                systemName: selectedCards.contains(card)
                                    ? "checkmark.circle.fill" : "circle"
                            )
                            .foregroundColor(
                                selectedCards.contains(card)
                                    ? .accentColor : .secondary
                            )
                            CardRow(card: card, folders: folders, lastDeselectedCardID: lastDeselectedCardID)
                                // Added id for card row for scrolling
                                .id(card.id)
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if selectedCards.contains(card) {
                                selectedCards.remove(card)
                            } else {
                                selectedCards.insert(card)
                            }
                        }
                    } else {
                        CardRow(
                            card: card,
                            folders: folders,
                            lastDeselectedCardID: lastDeselectedCardID
                        )
                        // Added id for card row for scrolling
                        .id(card.id)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .contentShape(Rectangle())
                        .onTapGesture { select(card) }
                        .accessibilityAddTraits(.isButton)
                        .animation(
                            .default,
                            value: selectedCardModel.selectedCard?.id
                        )
                    }
                }
                .onDelete { offsets in
                    delete(cards: skipDisabledCards, at: offsets)
                }
            }
        }
    }
    var seenCountSection: some View {
        List {
            ForEach(
                filteredCards.sorted(by: {
                    ascending
                        ? $0.seenCount < $1.seenCount
                        : $0.seenCount > $1.seenCount
                })
            ) { card in
                if selectionMode {
                    HStack {
                        Image(
                            systemName: selectedCards.contains(card)
                                ? "checkmark.circle.fill" : "circle"
                        )
                        .foregroundColor(
                            selectedCards.contains(card)
                                ? .accentColor : .secondary
                        )
                        CardRow(card: card, folders: folders, lastDeselectedCardID: lastDeselectedCardID)
                            // Added id for card row for scrolling
                            .id(card.id)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        if selectedCards.contains(card) {
                            selectedCards.remove(card)
                        } else {
                            selectedCards.insert(card)
                        }
                    }
                } else {
                    CardRow(
                        card: card,
                        folders: folders,
                        lastDeselectedCardID: lastDeselectedCardID
                    )
                    // Added id for card row for scrolling
                    .id(card.id)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .contentShape(Rectangle())
                    .onTapGesture { select(card) }
                    .accessibilityAddTraits(.isButton)
                    .animation(
                        .default,
                        value: selectedCardModel.selectedCard?.id
                    )
                }
            }
            .onDelete { offsets in
                delete(cards: filteredCards, at: offsets)
            }
        }
    }
    
    @ViewBuilder
    var contentListView: some View {
        switch sortCriteria {
        case .enqueuedAt:
            List {
                if !selectedCardModel.isNewlyCreated { TipView(addWidgetTip) }
                TipView(customizeWidgetTip)
                if activeStatusFilters.isEmpty {
                    emptyStatusFilterView
                } else {
                    if shouldShowQueueSection {
                        queueSection
                    }
                    if shouldShowUpcomingSection {
                        upcomingSection
                    }
                    if shouldShowArchivedSection {
                        archivedSection
                    }
                }
            }
        case .createdAt:
            createdAtSection
        case .skipCount:
            skipCountSection
        case .seenCount:
            seenCountSection
        }
    }
    
    
}
