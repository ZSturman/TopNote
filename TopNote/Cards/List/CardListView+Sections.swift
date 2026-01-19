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
    
    /// Navigation title view with card type SF Symbol toggle buttons based on active filters
    var cardTypeSelectedFilteredOption: some View {
        HStack(spacing: 12) {
            Button {
                toggleFilterOption(.todo)
            } label: {
                HStack(spacing: 2) {
                    Image(systemName: CardType.todo.systemImage)
                    Text("\(toDoCardCount)")
                }
            }
    
            .buttonStyle(.plain)
            .foregroundColor(filterOptions.contains(.todo) ? CardType.todo.tintColor : .gray)
            
            Button {
                toggleFilterOption(.note)
            } label: {
                HStack(spacing: 2) {
                    Image(systemName: CardType.note.systemImage)
                    Text("\(noteCardCount)")
                }
            
            }
            .buttonStyle(.plain)
            .foregroundColor(filterOptions.contains(.note) ? CardType.note.tintColor : .gray)
            
            Button {
                toggleFilterOption(.flashcard)
            } label: {
                HStack(spacing: 2) {
                    Image(systemName: CardType.flashcard.systemImage)
                    Text("\(flashcardCount)")
                }
            }
         
            .buttonStyle(.plain)
            .foregroundColor(filterOptions.contains(.flashcard) ? CardType.flashcard.tintColor : .gray)
           
        }
        .font(.caption)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
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
    
    var emptyTypeFilterView: some View {
        VStack(spacing: 8) {
            Text("No card types selected")
                .font(.headline)
            Text("Tap the icons above or use Filters to select card types.")
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
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
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
                        lastDeselectedCardID: lastDeselectedCardID,
                        selectionMode: selectionMode,
                        selectedCards: $selectedCards
                    )
                    .environment(\.ascending, ascending)
                    .environment(\.sortCriteria, sortCriteria)
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
                    Image(systemName: "calendar")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
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
                    lastDeselectedCardID: lastDeselectedCardID,
                    selectionMode: selectionMode,
                    selectedCards: $selectedCards
                )
                .environment(\.ascending, ascending)
                .environment(\.sortCriteria, sortCriteria)
            }
        }
        .padding(.bottom, isUpcomingExpanded ? 0 : 8)
    }
    var archivedSection: some View {
        Section(
            header:
                HStack {
                    Image(systemName: "archivebox")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
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
                    lastDeselectedCardID: lastDeselectedCardID,
                    selectionMode: selectionMode,
                    selectedCards: $selectedCards
                )
                .environment(\.ascending, ascending)
                .environment(\.sortCriteria, sortCriteria)
            }
        }
        .padding(.bottom, isArchivedExpanded ? 0 : 8)
    }
    
    var deletedSection: some View {
        Section(
            header:
                HStack {
                    Image(systemName: "trash")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text("Deleted")
                    Text("(\(deletedCards.count))")
                        .foregroundColor(.secondary)
                        .font(.subheadline)
                    Spacer()
                    Image(
                        systemName: isDeletedExpanded
                            ? "chevron.down" : "chevron.right"
                    )
                }
                .contentShape(Rectangle())
                .onTapGesture { isDeletedExpanded.toggle() }
                .accessibilityIdentifier("DeletedSectionHeader")
        ) {
            if isDeletedExpanded {
                if deletedCards.isEmpty {
                    VStack(spacing: 8) {
                        Text("No deleted cards")
                            .foregroundColor(.secondary)
                        Text("Cards you delete will appear here for recovery.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.vertical, 16)
                    .frame(maxWidth: .infinity)
                } else {
                    VStack(spacing: 4) {
                        Text("Cards will be permanently deleted after 30 days")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    CardStatusSection(
                        title: "Deleted",
                        cards: deletedCards,
                        folders: folders,
                        onDelete: permanentlyDeleteCards,
                        onPriorityChanged: nil,
                        priorityChangedForCardID: nil,
                        lastDeselectedCardID: lastDeselectedCardID,
                        selectionMode: selectionMode,
                        selectedCards: $selectedCards
                    )
                    .environment(\.ascending, ascending)
                    .environment(\.sortCriteria, sortCriteria)
                }
            }
        }
        .padding(.bottom, isDeletedExpanded ? 0 : 8)
    }

    
    var createdAtSection: some View {
        List {
            Section {
                cardTypeSelectedFilteredOption
            }
            .listRowInsets(EdgeInsets())
            .listRowBackground(Color.clear)
            
            if !selectedCardModel.isNewlyCreated {
                TipView(addWidgetTip)
            }
            TipView(customizeWidgetTip)
            
            if activeTypeFilters.isEmpty {
                emptyTypeFilterView
            } else {
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
    }
    var skipCountSection: some View {
        List {
            Section {
                cardTypeSelectedFilteredOption
            }
            .listRowInsets(EdgeInsets())
            .listRowBackground(Color.clear)
            
            if activeTypeFilters.isEmpty {
                emptyTypeFilterView
            } else {
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
    }
    var seenCountSection: some View {
        List {
            Section {
                cardTypeSelectedFilteredOption
            }
            .listRowInsets(EdgeInsets())
            .listRowBackground(Color.clear)
            
            if activeTypeFilters.isEmpty {
                emptyTypeFilterView
            } else {
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
    }
    
    var contentSortSection: some View {
        List {
            Section {
                cardTypeSelectedFilteredOption
            }
            .listRowInsets(EdgeInsets())
            .listRowBackground(Color.clear)
            
            if activeTypeFilters.isEmpty {
                emptyTypeFilterView
            } else {
                ForEach(
                    filteredCards.sorted(by: {
                        let comparison = $0.content.localizedStandardCompare($1.content)
                        return ascending
                            ? comparison == .orderedAscending
                            : comparison == .orderedDescending
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
    }
    
    @ViewBuilder
    var contentListView: some View {
        switch sortCriteria {
        case .enqueuedAt:
            List {
                
                    cardTypeSelectedFilteredOption
                    .listRowSeparator(.hidden)
                
                
                if !selectedCardModel.isNewlyCreated { TipView(addWidgetTip) }
                TipView(customizeWidgetTip)
                

                if activeTypeFilters.isEmpty {
                    emptyTypeFilterView
                } else if activeStatusFilters.isEmpty {
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
                    // Deleted section appears at the very bottom
                    if shouldShowDeletedSection {
                        deletedSection
                    }
                }
            }
        case .createdAt:
            createdAtSection
        case .skipCount:
            skipCountSection
        case .seenCount:
            seenCountSection
        case .content:
            contentSortSection
        }
    }
    
    
}

