//  CardList.swift
//  TopNote
//
//  Created by Zachary Sturman on 7/28/25.
//

import Foundation
import SwiftData
import SwiftUI
import TipKit

extension CardFilterOption {
    var asCardType: CardType? {
        switch self {
        case .todo: return .todo
        case .flashcard: return .flashcard
        case .note: return .note
        default: return nil
        }
    }
}

struct SimpleCardImport: Decodable {
    var cardType: String?
    var content: String?
    var answer: String?
}

extension CardType {
    init(caseInsensitiveRawValue: String) {
        let lower = caseInsensitiveRawValue.lowercased()
        self =
            CardType.allCases.first(where: { $0.rawValue.lowercased() == lower }
            ) ?? .todo
    }
}

private struct SortOrderKey: EnvironmentKey {
    static let defaultValue: Bool = true
}

extension EnvironmentValues {
    var ascending: Bool {
        get { self[SortOrderKey.self] }
        set { self[SortOrderKey.self] = newValue }
    }
}

struct CardListView: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject var selectedCardModel: SelectedCardModel

    @Query private var cards: [Card]

    @Query var tags: [CardTag]

    @Binding var selectedFolder: FolderSelection?
    var tagSelectionStates: [UUID: TagSelectionState]

    // Editing state
    @State private var sortCriteria: CardSortCriteria = .enqueuedAt
    @State private var ascending: Bool = true
    @State private var filterOptions: [CardFilterOption] = CardFilterOption
        .allCases

    // State to show/hide the add card confirmation dialog anchored to the FAB
    @State private var showAddCardActionSheet = false

    @State private var showShareSheet = false
    @State private var exportedFileURL: URL?

    // NEW: Expand/collapse states for sections
    @State private var isQueueExpanded = true
    @State private var isUpcomingExpanded = true
    @State private var isArchivedExpanded = false

    // NEW: Settings, import, selection mode
    @State private var showImportPicker = false
    @State private var selectionMode = false
    @State private var selectedCards = Set<Card>()

    @State private var showImportSuccessAlert = false
    @State private var importErrorMessage: String? = nil
    
    // Search functionality
    @State private var searchText = ""

    // Added property for programmatic scrolling, as requested
    @State private var scrollToCardID: UUID? = nil  // Used for programmatic scrolling
    
    // Tip tracking
    @State private var appOpenCount = 0
    @State private var hasViewedQueueCard = false
    
    let addFirstCardTip = FirstNoteTip()
    let addWidgetTip = AddWidgetTip()
    let firstQueueCardTip = FirstQueueCardTip()
    let customizeWidgetTip = CustomizeWidgetTip()
    let getStartedTip = GetStartedTip()
    let firstNoteTip = FirstNoteTip_Skip()
    let firstTodoTip = FirstTodoTip_Skip()
    let firstFlashcardTip = FirstFlashcardTip_Skip()
    
    //let importExportTip = ImportExportTip()

    private struct CardListTaskID: Equatable {
        let sortCriteria: CardSortCriteria
        let ascending: Bool
        let folderSelection: FolderSelection?
        let filterOptions: [CardFilterOption]
        let tagStates: [UUID: TagSelectionState]
    }

    init(
        selectedFolder: Binding<FolderSelection?>,
        tagSelectionStates: [UUID: TagSelectionState]
    ) {
        _selectedFolder = selectedFolder
        self.tagSelectionStates = tagSelectionStates

    }

    // MARK: - Helpers for selection

    private var allSelectableCards: [Card] {
        filteredCards
    }

    private var allCardsSelected: Bool {
        !allSelectableCards.isEmpty
            && selectedCards.count == allSelectableCards.count
    }

    private func selectAllCards() {
        selectedCards = Set(allSelectableCards)
    }

    private func deselectAllCards() {
        selectedCards.removeAll()
    }

    // MARK: - Fetch bridge

    private func currentSelectedTagIDs() -> [UUID] {
        tagSelectionStates.compactMap { (id, state) in
            state == .selected ? id : nil
        }
    }
    private func currentDeselectedTagIDs() -> [UUID] {
        tagSelectionStates.compactMap { (id, state) in
            state == .deselected ? id : nil
        }
    }

    // Filter cards based on selectedFolder and tag selection states
    private var filteredCards: [Card] {
        // Extract which type and status filters are selected, if any
        let typeFilters = Set(
            filterOptions.filter { CardFilterOption.typeFilters.contains($0) }
        )
        let selectedCardTypes = Set(typeFilters.compactMap { $0.asCardType })
        let statusFilters = Set(
            filterOptions.filter { CardFilterOption.statusFilters.contains($0) }
        )

        // Apply type filter if any type options selected
        let typeFiltered: [Card] =
            selectedCardTypes.isEmpty
            ? cards
            : cards.filter { selectedCardTypes.contains($0.cardType) }

        // Apply status filter if any status options selected
        let statusFiltered: [Card] =
            statusFilters.isEmpty
            ? typeFiltered
            : typeFiltered.filter { card in
                let isEnqueue =
                    card.isEnqueue(currentDate: .now) && !card.isArchived
                let isUpcoming =
                    !card.isEnqueue(currentDate: .now) && !card.isArchived
                let isArchived = card.isArchived
                var matched = false
                if statusFilters.contains(.enqueue), isEnqueue {
                    matched = true
                }
                if statusFilters.contains(.upcoming), isUpcoming {
                    matched = true
                }
                if statusFilters.contains(.archived), isArchived {
                    matched = true
                }
                return matched
            }

        // Folder filtering as before
        let folderFiltered: [Card] = {
            guard let selected = selectedFolder else { return statusFiltered }
            switch selected {
            case .folder(let folder):
                return statusFiltered.filter { $0.folder?.id == folder.id }
            case .allCards:
                return statusFiltered
            }
        }()

        // Tag selection filtering as before
        let selectedTagIDs = currentSelectedTagIDs()
        let deselectedTagIDs = currentDeselectedTagIDs()

        let tagFiltered = folderFiltered.filter { card in
            let tagIDs = Set(card.unwrappedTags.map { $0.id })
            // Must contain all selected tag IDs
            if !selectedTagIDs.isEmpty
                && !selectedTagIDs.allSatisfy({ tagIDs.contains($0) })
            {
                return false
            }
            // Must not contain any deselected tag IDs
            if !deselectedTagIDs.isEmpty
                && deselectedTagIDs.contains(where: { tagIDs.contains($0) })
            {
                return false
            }
            return true
        }
        
        // Apply search filter if search text is not empty
        if searchText.trimmingCharacters(in: .whitespaces).isEmpty {
            return tagFiltered
        }
        
        let searchTerm = searchText.lowercased()
        return tagFiltered.filter { card in
            // Search in content
            if card.content.lowercased().contains(searchTerm) {
                return true
            }
            // Search in answer (for flashcards)
            if let answer = card.answer, answer.lowercased().contains(searchTerm) {
                return true
            }
            // Search in tags
            if card.unwrappedTags.contains(where: { $0.name.lowercased().contains(searchTerm) }) {
                return true
            }
            return false
        }
    }

    // Helper to group cards by day (used for .createdAt sorting)
    private func groupCardsByDay(_ cards: [Card]) -> [Date: [Card]] {
        let calendar = Calendar.current
        return Dictionary(grouping: cards) { card in
            calendar.startOfDay(for: card.createdAt)
        }
    }

    // Helper to get display string like "Today", "Yesterday", or date string
    private func displayDateHeader(for date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .none
            return formatter.string(from: date)
        }
    }

    private var taskID: CardListTaskID {
        CardListTaskID(
            sortCriteria: sortCriteria,
            ascending: ascending,
            folderSelection: selectedFolder,
            filterOptions: filterOptions,
            tagStates: tagSelectionStates
        )
    }

    private var queueCards: [Card] {
        filteredCards.filter {
            $0.isEnqueue(currentDate: .now) && !$0.isArchived
        }
    }
    private var upcomingCards: [Card] {
        filteredCards.filter {
            !$0.isEnqueue(currentDate: .now) && !$0.isArchived
        }
    }
    private var archivedCards: [Card] {
        filteredCards.filter { $0.isArchived }.sorted { card1, card2 in
            let date1 = card1.removals.last ?? card1.createdAt
            let date2 = card2.removals.last ?? card2.createdAt
            return date1 > date2 // Most recent first
        }
    }
    private var groupedByDay: [Date: [Card]] {
        groupCardsByDay(filteredCards)
    }
    private var sortedKeys: [Date] {
        let keysArray: [Date] = Array(groupedByDay.keys)
        if ascending {
            return keysArray.sorted(by: { $0 < $1 })
        } else {
            return keysArray.sorted(by: { $0 > $1 })
        }
    }

    // MARK: - Extracted Sections for .enqueuedAt sortCriteria

    private var queueSection: some View {
        Section(
            header:
                HStack {
                    Text("Queue")
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
                        onDelete: delete
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

    private var upcomingSection: some View {
        Section(
            header:
                HStack {
                    Text("Upcoming")
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
                    onDelete: delete
                )
                .environment(\.ascending, ascending)
            }
        }
        .padding(.bottom, isUpcomingExpanded ? 0 : 8)
    }

    private var archivedSection: some View {
        Section(
            header:
                HStack {
                    Text("Archived")
                    Spacer()
                    Image(
                        systemName: isArchivedExpanded
                            ? "chevron.down" : "chevron.right"
                    )
                }
                .contentShape(Rectangle())
                .onTapGesture { isArchivedExpanded.toggle() }
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
                    onDelete: delete
                )
                .environment(\.ascending, ascending)
            }
        }
        .padding(.bottom, isArchivedExpanded ? 0 : 8)
    }

    // MARK: - Toolbar helpers
    @ToolbarContentBuilder
    private var leadingToolbarItems: some ToolbarContent {
        ToolbarItemGroup(placement: .navigationBarLeading) {
            if selectionMode {
                Button(allCardsSelected ? "Deselect All" : "Select All") {
                    if allCardsSelected {
                        deselectAllCards()
                    } else {
                        selectAllCards()
                    }
                }
                Button("Cancel", role: .cancel) {
                    selectionMode = false
                    selectedCards.removeAll()
                }
            } else if selectedCardModel.selectedCard != nil {
                // When a single card is selected, show Cancel on the leading side
                Button("Cancel", role: .cancel) {
                    cancelEdits()
                }
            }
        }
    }

    @ToolbarContentBuilder
    private var trailingToolbarItems: some ToolbarContent {
        ToolbarItemGroup(placement: .navigationBarTrailing) {
            if selectionMode {
                Button("Export") {
                    exportCardsAsJSON(Array(selectedCards))
                    selectionMode = false
                    selectedCards.removeAll()
                }
                .disabled(selectedCards.isEmpty)
            } else if selectedCardModel.selectedCard != nil {
                // Only show Done when a card is selected; hide sort/filter/settings
                Button("Done") {
                    finishEdits()
                }
            } else {
                Menu {
                    Button("Export Filtered Cards") {
//                        Task {
//                            await ImportExportTip.openedSettingsEvent.donate()
//                        }
//                        importExportTip.invalidate(reason: .actionPerformed)
                        exportCardsAsJSON(filteredCards)
                    }
                    Button("Import Cards") { 
//                        Task {
//                            await ImportExportTip.openedSettingsEvent.donate()
//                        }
//                        importExportTip.invalidate(reason: .actionPerformed)
                        showImportPicker = true 
                    }
                } label: {
                    Image(systemName: "gear")
                }
                //.popoverTip(importExportTip, arrowEdge: .bottom)
                Menu {
                    ForEach(CardSortCriteria.allCases) { opt in
                        Button(opt.localizedName) { sortCriteria = opt }
                    }
                    Divider()
                    Button(ascending ? "Ascending" : "Descending") {
                        ascending.toggle()
                    }
                } label: {
                    Label("Sort", systemImage: "arrow.up.arrow.down")
                }
                .accessibilityIdentifier("Sort")
                // Show filter menu only for enqueuedAt and createdAt
                if sortCriteria == .enqueuedAt || sortCriteria == .createdAt {
                    CardFilterMenu(selectedOptions: $filterOptions)
                }
            }
        }
    }

    // MARK: - Done / Cancel actions

    private func finishEdits() {
        // Commit changes; if card is empty, delete it
        if let card = selectedCardModel.selectedCard {
            let isEmpty = card.content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            if isEmpty {
                context.delete(card)
            }
            try? context.save()
        }
        selectedCardModel.clearSelection()
    }

    private func cancelEdits() {
        if let card = selectedCardModel.selectedCard {
            if selectedCardModel.isNewlyCreated {
                // New card -> delete entirely
                context.delete(card)
                try? context.save()
            } else {
                // Existing card -> restore snapshot
                selectedCardModel.restoreSnapshotIfAvailable()
                try? context.save()
            }
        }
        selectedCardModel.clearSelection()
    }

    var body: some View {
        // Wrapped entire body content with ScrollViewReader for programmatic scrolling
        ScrollViewReader { proxy in
            Group {
                switch sortCriteria {
                case .enqueuedAt:
                    List {
                        if !selectedCardModel.isNewlyCreated {
                            TipView(addWidgetTip)
                        }
                        TipView(customizeWidgetTip)
                        queueSection
                        upcomingSection
                        archivedSection
                    }
                case .createdAt:
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
                                            CardRow(card: card)
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
                case .skipCount:
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
                                        CardRow(card: card)
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
                                        CardRow(card: card)
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
                case .seenCount:
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
                                    CardRow(card: card)
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
            .listStyle(.plain)
            .navigationTitle(selectedFolder?.name ?? "All Cards")
            .searchable(text: $searchText, prompt: "Search cards")
            .toolbar {
                leadingToolbarItems
                trailingToolbarItems
            }
            .onAppear {
                appOpenCount += 1
                Task {
                    await CustomizeWidgetTip.appOpenedEvent.donate()
                    await GetStartedTip.appOpenedWithoutActionEvent.donate()
                }
            }
            .overlay(alignment: .bottomTrailing) {
                Button(action: {
                    showAddCardActionSheet.toggle()
                    addFirstCardTip.invalidate(reason: .actionPerformed)
                }) {
                    Image(systemName: "square.and.pencil")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 56, height: 56)
                        .background(Circle().fill(Color.accentColor))
                        .shadow(
                            color: Color.black.opacity(0.3),
                            radius: 4,
                            x: 0,
                            y: 2
                        )
                }
                .popoverTip(addFirstCardTip)
                .padding(.trailing, 16)
                .padding(.bottom, 16)
                .accessibilityLabel("Add Card")
                .confirmationDialog(
                    "Add Card",
                    isPresented: $showAddCardActionSheet,
                    titleVisibility: .visible
                ) {
                    Button("Note") { addCard(ofType: .note) }
                    Button("Todo") { addCard(ofType: .todo) }
                    Button("Flashcard") { addCard(ofType: .flashcard) }
                    Button("Cancel", role: .cancel) {}
                }
            }
            .sheet(isPresented: $showShareSheet) {
                if let exportedFileURL {
                    ShareSheet(activityItems: [exportedFileURL])
                }
            }
            // Added onChange for scrollToCardID to perform scrolling via proxy
            .onChange(of: scrollToCardID) { _, newID in
                guard let id = newID else { return }
                // Scroll to new card if visible, or to the upcoming section if not
                // Try scrolling to the card row. If not found, scroll to Upcoming section.
                withAnimation {
                    proxy.scrollTo(id, anchor: .center)
                }
                // Reset scrollToCardID after scrolling
                scrollToCardID = nil
            }
            .onChange(of: selectedCardModel.selectedCard?.id) { _, newID in
                guard let id = newID else { return }
                scrollToCardID = id
            }
            .fileImporter(
                isPresented: $showImportPicker,
                allowedContentTypes: [.json]
            ) { result in
                print("Importer: Entered fileImporter closure")
                if case .success(let url) = result {
                    print("Importer: Attempting to read file at URL:", url)
                    do {
                        let data = try Data(contentsOf: url)
                        print("Importer: Loaded data from", url)
                        do {
                            print("Importer: Attempting JSON parse...")
                            let jsonObj =
                                try JSONSerialization.jsonObject(with: data)
                                as? [[String: Any]]
                            print("Importer: Parsed JSON object:", jsonObj as Any)
                            if let dictArray = jsonObj {
                                print(
                                    "Importer: Looping through array of card dictionaries (count:",
                                    dictArray.count,
                                    ")"
                                )
                                for dict in dictArray {
                                    print(
                                        "Importer: Attempting to make card from dict:",
                                        dict
                                    )
                                    if let card = Self.makeCard(
                                        from: dict,
                                        context: context
                                    ) {
                                        print(
                                            "Importer: Successfully created Card:",
                                            card
                                        )
                                        context.insert(card)
                                    } else {
                                        print(
                                            "Importer: Failed to create Card from dict:",
                                            dict
                                        )
                                    }
                                }
                                print("Importer: Import complete.")
                                showImportSuccessAlert = true
                            }
                        } catch {
                            importErrorMessage =
                                "Failed to parse JSON: \(error.localizedDescription)"
                            print("Importer: Import failed with error:", error)
                            #if DEBUG
                                print("Import failed with error: \(error)")
                            #endif
                        }
                    } catch {
                        importErrorMessage =
                            "Failed to load data from file: \(error.localizedDescription)"
                        print("Importer: Failed to load data from \(url):", error)
                    }
                } else {
                    print("Importer: fileImporter result was not success:", result)
                }
            }
            .alert("Import Successful!", isPresented: $showImportSuccessAlert) {
                Button("OK", role: .cancel) {}
            }
            .alert(
                "Import Failed",
                isPresented: .constant(importErrorMessage != nil)
            ) {
                Button("OK", role: .cancel) { importErrorMessage = nil }
            } message: {
                Text(importErrorMessage ?? "Unknown error")
            }
        }
    }

    private func addCard(ofType type: CardType) {
        let wasEmptyBeforeInsert = cards.isEmpty
        // Force Upcoming filter and remove Enqueue filter to avoid conflicts
        if !filterOptions.contains(.upcoming) {
            filterOptions.append(.upcoming)
        }
        // Expand Upcoming section for focus on new card
        // Keep Queue section state as-is to avoid confusing the user
        isUpcomingExpanded = true

        let folderForNew: Folder? = {
            guard let sel = selectedFolder else { return nil }
            if case .folder(let f) = sel { return f }
            return nil
        }()

        // Gather tags corresponding to selected tag IDs
        let selectedTagIDs = currentSelectedTagIDs()
        let tagsForNew: [CardTag] = self.tags.filter { selectedTagIDs.contains($0.id) }

        // Set type-specific properties
        let isRecurring = true
        let skipEnabled: Bool
        let skipPolicy: RepeatPolicy
        let resetRepeatIntervalOnComplete: Bool
        let repeatInterval: Int

        switch type {
        case .flashcard:
            skipEnabled = false
            skipPolicy = .none
            resetRepeatIntervalOnComplete = false
            repeatInterval = 1440
        case .todo:
            skipEnabled = true
            skipPolicy = .aggressive
            resetRepeatIntervalOnComplete = true
            repeatInterval = 720
        case .note:
            skipEnabled = true
            skipPolicy = .mild
            resetRepeatIntervalOnComplete = false
            repeatInterval = 2880
        }

        let newCard = Card(
            createdAt: Date(),
            cardType: type,
            priorityTypeRaw: .none,
            content: "",
            isRecurring: isRecurring,
            skipCount: 0,
            seenCount: 0,
            repeatInterval: repeatInterval,
            initialRepeatInterval: repeatInterval,
            folder: folderForNew,
            tags: tagsForNew,
            skipPolicy: skipPolicy,
            ratingEasyPolicy: .mild,
            ratingMedPolicy: .none,
            ratingHardPolicy: .aggressive,
            isComplete: false,
            resetRepeatIntervalOnComplete: resetRepeatIntervalOnComplete,
            skipEnabled: skipEnabled
           
        )

        context.insert(newCard)
        selectedCardModel.selectedCard = newCard
        selectedCardModel.setIsNewlyCreated(true)
        // Capture snapshot of the brand-new state so Cancel can delete instead of revert
        selectedCardModel.captureSnapshot()
        
        if wasEmptyBeforeInsert {
            Task {
                await AddWidgetTip.createdFirstCardEvent.donate()
                await GetStartedTip.userTookActionEvent.donate()
            }
        } else {
            Task {
                await GetStartedTip.userTookActionEvent.donate()
            }
        }
        
        // Donate to card-type-specific events
        Task {
            switch type {
            case .note:
                await FirstNoteTip_Skip.createdFirstNoteEvent.donate()
            case .todo:
                await FirstTodoTip_Skip.createdFirstTodoEvent.donate()
            case .flashcard:
                await FirstFlashcardTip_Skip.createdFirstFlashcardEvent.donate()
            }
        }

        // Scroll to new card after a brief delay to ensure it's rendered
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            scrollToCardID = newCard.id
        }
    }

    private func delete(cards sectionCards: [Card], at offsets: IndexSet) {
        let toDelete = offsets.map { sectionCards[$0] }
        toDelete.forEach { context.delete($0) }
        do {
            try context.save()
        } catch {
            // Handle error here if desired
        }
        // After deleting cards, clean up orphan tags
        do {
            let fetchDescriptor = FetchDescriptor<CardTag>()
            let allTags = try context.fetch(fetchDescriptor)
            let orphanTags = allTags.filter { $0.unwrappedCards.isEmpty }
            orphanTags.forEach { context.delete($0) }
            if !orphanTags.isEmpty {
                try context.save()
            }
        } catch {
            // Optionally handle error if desired
            print("Failed to delete orphaned tags: \(error)")
        }
        // If the deleted card was selected, clear selection and snapshot
        if let selectedCard = selectedCardModel.selectedCard,
            toDelete.contains(where: { $0.id == selectedCard.id })
        {
            selectedCardModel.clearSelection()
        }
    }

    // Single-select logic: selecting a card deselects any previously selected card
    private func select(_ card: Card) {
        if selectedCardModel.selectedCard?.id == card.id {
            // Deselecting by tapping selected card: treat as Done behavior
            finishEdits()
        } else {
            selectedCardModel.selectedCard = card
            selectedCardModel.setIsNewlyCreated(false)
            selectedCardModel.captureSnapshot()
        }
    }

    private func exportCardsAsJSON(_ cards: [Card]) {
        do {
            let jsonData = try Card.exportCardsToJSON(cards)
            let fileManager = FileManager.default
            if let dir = fileManager.urls(
                for: .documentDirectory,
                in: .userDomainMask
            ).first {
                let fileURL = dir.appendingPathComponent("exported_cards.json")
                try jsonData.write(to: fileURL)
                print("Exported to \(fileURL)")
                exportedFileURL = fileURL
                showShareSheet = true
            }
        } catch {
            print("Export failed: \(error)")
        }
    }
}

// MARK: - CardStatusSection: Shows a section for a given status, lists all cards in that status
// without grouping by cardType, sorted by nextTimeInQueue ascending/descending per current sort order.
// Used only for .enqueuedAt sort.

struct CardStatusSection: View {
    @Environment(\.modelContext) private var context
    let title: String
    let cards: [Card]

    @EnvironmentObject var selectedCardModel: SelectedCardModel
    let onDelete: ([Card], IndexSet) -> Void

    @Environment(\.ascending) private var ascending: Bool

    private var sortedCards: [Card] {
        cards.sorted(by: { card1, card2 in
            // First sort by priority (lower sortValue = higher priority)
            if card1.priority.sortValue != card2.priority.sortValue {
                return card1.priority.sortValue < card2.priority.sortValue
            }
            // Then sort by nextTimeInQueue
            return ascending
                ? card1.nextTimeInQueue < card2.nextTimeInQueue
                : card1.nextTimeInQueue > card2.nextTimeInQueue
        })
    }

    var body: some View {
        Section {
            ForEach(sortedCards) { card in
                CardRow(
                    card: card,
                )
                // Added .id(card.id) for programmatic scrolling support
                .id(card.id)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .contentShape(Rectangle())
                .onTapGesture { select(card) }
                .accessibilityAddTraits(.isButton)

                .animation(.default, value: selectedCardModel.selectedCard?.id)
            }
            .onDelete { offsets in
                onDelete(sortedCards, offsets)
            }
        }
    }

    // Single-select logic: selecting a card deselects any previously selected card
    private func select(_ card: Card) {
        if selectedCardModel.selectedCard?.id == card.id {
            // Deselecting by tapping selected card: treat as Done behavior
            if let selected = selectedCardModel.selectedCard {
                let isEmpty = selected.content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                if isEmpty {
                    context.delete(selected)
                }
                try? context.save()
            }
            selectedCardModel.clearSelection()
        } else {
            selectedCardModel.selectedCard = card
            selectedCardModel.setIsNewlyCreated(false)
            selectedCardModel.captureSnapshot()
        }
    }

}

// MARK: - CardFilterMenu: Provides a filter menu for CardFilterOption
struct CardFilterMenu: View {
    @Binding var selectedOptions: [CardFilterOption]

    var body: some View {
        Menu {
            Section("Type") {
                ForEach(CardFilterOption.typeFilters, id: \.self) { option in
                    let isTypeSelected = selectedOptions.contains(option)
                    let numSelectedTypes = selectedOptions.filter { CardFilterOption.typeFilters.contains($0) }.count
                    Button(action: {
                        if let idx = selectedOptions.firstIndex(of: option) {
                            selectedOptions.remove(at: idx)
                        } else {
                            selectedOptions.append(option)
                        }
                    }) {
                        Label(
                            option.localizedName,
                            systemImage: isTypeSelected ? "checkmark.circle.fill" : "circle"
                        )
                    }
                    .disabled(isTypeSelected && numSelectedTypes == 1)
                }
            }
            Section("Status") {
                ForEach(CardFilterOption.statusFilters, id: \.self) { option in
                    Button(action: {
                        if let idx = selectedOptions.firstIndex(of: option) {
                            selectedOptions.remove(at: idx)
                        } else {
                            selectedOptions.append(option)
                        }
                    }) {
                        Label(
                            option.localizedName,
                            systemImage: selectedOptions.contains(option)
                                ? "checkmark.circle.fill" : "circle"
                        )
                    }
                }
            }
        } label: {
            Label("Filter", systemImage: "line.3.horizontal.decrease.circle")
        }
        .accessibilityIdentifier("Filter")
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: nil
        )
    }
    func updateUIViewController(
        _ controller: UIActivityViewController,
        context: Context
    ) {}
}

extension CardListView {
    static func makeCard(from dict: [String: Any], context: ModelContext)
        -> Card?
    {
        // Helper: Folder lookup or creation by name
        func folderForName(_ name: String) -> Folder? {
            guard !name.isEmpty else { return nil }
            let request = FetchDescriptor<Folder>(
                predicate: #Predicate { $0.name == name }
            )
            if let found = try? context.fetch(request).first { return found }
            let f = Folder(name: name)
            context.insert(f)
            return f
        }

        // Helper: Tag lookup or creation by name
        func tagsForNames(_ names: [String]) -> [CardTag] {
            names.compactMap { tagName in
                guard !tagName.isEmpty else { return nil }
                let req = FetchDescriptor<CardTag>(
                    predicate: #Predicate { $0.name == tagName }
                )
                if let found = try? context.fetch(req).first { return found }
                let t = CardTag(name: tagName)
                context.insert(t)
                return t
            }
        }

        // Extract and sanitize fields with defaults using separate let bindings
        let rawCardType: String
        if let str = dict["cardType"] as? String {
            rawCardType = str
        } else {
            rawCardType = "todo"
        }
        let cardType = CardType(caseInsensitiveRawValue: rawCardType)

        let contentValue: String
        if let contentStr = dict["content"] as? String, !contentStr.isEmpty {
            contentValue = contentStr
        } else {
            contentValue = "Untitled"
        }

        let answerValue: String?
        if cardType == .flashcard {
            if let ans = dict["answer"] as? String, !ans.isEmpty {
                answerValue = ans
            } else {
                answerValue = "(No answer)"
            }
        } else {
            answerValue = nil
        }

        let createdAtValue: Date
        if let createdStr = dict["createdAt"] as? String,
            let date = ISO8601DateFormatter().date(from: createdStr)
        {
            createdAtValue = date
        } else {
            createdAtValue = Date()
        }

        let nextTimeInQueueValue: Date
        if let nextTimeStr = dict["nextTimeInQueue"] as? String,
            let date = ISO8601DateFormatter().date(from: nextTimeStr)
        {
            nextTimeInQueueValue = date
        } else {
            nextTimeInQueueValue = Date()
        }

        // Updated logic for defaults based on cardType

        // isRecurring
        let isRecurringValue: Bool = {
            if let val = dict["isRecurring"] as? Bool {
                return val
            } else {
                return true
            }
        }()

        // repeatInterval
        let repeatIntervalValue: Int = {
            if let val = dict["repeatInterval"] as? Int {
                return val
            } else {

                return 720

            }
        }()

        // initialRepeatInterval
        let initialRepeatIntervalValue: Int = {
            if let val = dict["initialRepeatInterval"] as? Int {
                return val
            } else {

                return repeatIntervalValue

            }
        }()

        // folder
        let folderNameValue: String
        if let val = dict["folder"] as? String {
            folderNameValue = val
        } else {
            folderNameValue = ""
        }
        let folderValue = folderForName(folderNameValue)

        // tags
        let tagNamesValue: [String]
        if let val = dict["tags"] as? [String] {
            tagNamesValue = val
        } else {
            tagNamesValue = []
        }
        let tagsValue = tagsForNames(tagNamesValue)

        // isArchived
        let isArchivedValue: Bool
        if let val = dict["isArchived"] as? Bool {
            isArchivedValue = val
        } else {
            isArchivedValue = false
        }

        // skipPolicy
        let skipPolicyValue: RepeatPolicy = {
            if let val = dict["skipPolicy"] as? String,
                let policy = RepeatPolicy(rawValue: val)
            {
                return policy
            } else {
                switch cardType {
                case .flashcard:
                    return .none
                case .todo:
                    return .aggressive
                default:
                    return .mild
                }
            }
        }()

        // ratingEasyPolicy
        let ratingEasyPolicyValue: RepeatPolicy = {
            if let val = dict["ratingEasyPolicy"] as? String,
                let policy = RepeatPolicy(rawValue: val)
            {
                return policy
            } else {
                if cardType == .flashcard {
                    return .mild
                } else {
                    // For other types, no default mentioned, keep as .mild for safety
                    return .mild
                }
            }
        }()

        // ratingMedPolicy
        let ratingMedPolicyValue: RepeatPolicy = {
            if let val = dict["ratingMedPolicy"] as? String,
                let policy = RepeatPolicy(rawValue: val)
            {
                return policy
            } else {
                if cardType == .flashcard {
                    return .none
                } else {
                    return .none
                }
            }
        }()

        // ratingHardPolicy
        let ratingHardPolicyValue: RepeatPolicy = {
            if let val = dict["ratingHardPolicy"] as? String,
                let policy = RepeatPolicy(rawValue: val)
            {
                return policy
            } else {
                if cardType == .flashcard {
                    return .aggressive
                } else {
                    return .aggressive
                }
            }
        }()

        // isComplete
        let isCompleteValue: Bool
        if let val = dict["isComplete"] as? Bool {
            isCompleteValue = val
        } else {
            isCompleteValue = false
        }

        // answerRevealed (always false for flashcard, else default false)
        let answerRevealedValue: Bool = {
            if cardType == .flashcard {
                return false
            } else {
                if let val = dict["answerRevealed"] as? Bool {
                    return val
                } else {
                    return false
                }
            }
        }()

        // resetRepeatIntervalOnComplete
        let resetRepeatIntervalOnCompleteValue: Bool = {
            if let val = dict["resetRepeatIntervalOnComplete"] as? Bool {
                return val
            } else {
                if cardType == .todo {
                    return true
                } else {
                    return true
                }
            }
        }()

        // skipEnabled
        let skipEnabledValue: Bool = {
            if let val = dict["skipEnabled"] as? Bool {
                return val
            } else {
                switch cardType {
                case .flashcard:
                    return true
                case .todo:
                    return true
                default:
                    return false
                }
            }
        }()

        let ratingValue: [[RatingType: Date]] = []

        return Card(
            createdAt: createdAtValue,
            cardType: cardType,
            priorityTypeRaw: .none,
            content: contentValue,
            isRecurring: isRecurringValue,
            skipCount: dict["skipCount"] as? Int ?? 0,
            seenCount: dict["seenCount"] as? Int ?? 0,
            repeatInterval: repeatIntervalValue,
            initialRepeatInterval: initialRepeatIntervalValue,
            nextTimeInQueue: nextTimeInQueueValue,
            folder: folderValue,
            tags: tagsValue,
            answer: answerValue,
            rating: ratingValue,
            isArchived: isArchivedValue,
            answerRevealed: answerRevealedValue,
            skipPolicy: skipPolicyValue,
            ratingEasyPolicy: ratingEasyPolicyValue,
            ratingMedPolicy: ratingMedPolicyValue,
            ratingHardPolicy: ratingHardPolicyValue,
            isComplete: isCompleteValue,
            resetRepeatIntervalOnComplete: resetRepeatIntervalOnCompleteValue,
            skipEnabled: skipEnabledValue
        )
    }
}

