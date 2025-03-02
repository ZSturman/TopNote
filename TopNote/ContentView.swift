import SwiftUI
import SwiftData
import WidgetKit


struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query var folders: [Folder]
    @Query var allCards: [Card]
    @Query var tags: [Tag]
 
    
    @State var tagSelectionStates: [UUID: TagSelectionState] = [:]
    @State private var selectedFolder: FolderSelection? = .allCards
    @State private var selectedCard: Card?
    @State private var showNewFolderInput: Bool = false
    
    @State private var isNew: Bool = false
    
    @State var urlId: String = ""
    
    

    
    private var selectedCardBinding: Binding<Card?> {
        Binding<Card?>(
            get: { self.selectedCard },
            set: { newValue in
                if newValue == nil, let card = self.selectedCard {
                    if card.content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        
                        modelContext.delete(card)
                        cleanupOrphanTags()
                        
                    }
                }
                self.selectedCard = newValue
            }
        )
    }
    
    
    // Filter cards based on the tag selection state.
    private func filterCards(cards: [Card]) -> [Card] {
        let selectedTagIDs = tagSelectionStates.filter { $0.value == .selected }.map { $0.key }
        let deselectedTagIDs = tagSelectionStates.filter { $0.value == .deselected }.map { $0.key }
        
        return cards.filter { card in
            let cardTagIDs = card.unwrappedTags.map { $0.id }
            // For selected tags: the card must contain each one.
            for id in selectedTagIDs {
                if !cardTagIDs.contains(id) {
                    return false
                }
            }
            // For deselected tags: the card must not have any.
            for id in deselectedTagIDs {
                if cardTagIDs.contains(id) {
                    return false
                }
            }
            return true
        }
    }
    
    private var filteredCards: [Card] {
        let cards: [Card]
        switch selectedFolder {
        case .allCards:
            cards = allCards
        case .folder(let folder):
            cards = folder.unwrappedCards
        default:
            cards = []
        }
        return filterCards(cards: cards)
    }
    
    
    
    var body: some View {
        NavigationSplitView {
            // Sidebar: display "All Cards" and each folder.
            List(selection: $selectedFolder) {
                Section(header: Text("Folders")) {
                    NavigationLink(value: FolderSelection.allCards) {
                        Text(FolderSelection.allCards.name)
                    }
                    ForEach(folders.sorted { $0.name < $1.name }) { folder in
                        NavigationLink(value: FolderSelection.folder(folder)) {
                            Text(folder.name)
                        }
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                modelContext.delete(folder)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                            
                        }
                    }
                }
                if tags.count > 0 {
                    TagsSection(tags: tags, tagSelectionStates: $tagSelectionStates)
                }

            }
            // .searchable
            .toolbar {
                if UIDevice.current.userInterfaceIdiom != .phone {
                    ToolbarItemGroup(placement: .bottomBar) {
                        Button {
                            showNewFolderInput.toggle()
                        } label: {
                            HStack {
                                Image(systemName: "folder.badge.plus")
                                Text("New Folder")
                            }
                        }
                        Spacer()
                    }
                }
            }
        } content: {
            // Content: show cards split into three sections.
            if let selection = selectedFolder {
                let currentDate = Date()
                let enqueuedCards = filteredCards.filter { $0.isEnqueue(currentDate: currentDate) && !$0.archived }
                let archivedCards = filteredCards.filter { $0.archived }
                let upcomingCards = filteredCards.filter { !$0.isEnqueue(currentDate: currentDate) && !$0.archived }
                


                // Sort the enqueue cards by priority, then by timeInQueue (using Date.distantFuture for nil values)
                let enqueuedCardsSorted = enqueuedCards.sorted { lhs, rhs in
                    let lhsTuple = (lhs.isEssential ? 0 : 1, sortOrder(for: lhs), lhs.timeInQueue ?? Date.distantFuture)
                    let rhsTuple = (rhs.isEssential ? 0 : 1, sortOrder(for: rhs), rhs.timeInQueue ?? Date.distantFuture)
                    return lhsTuple < rhsTuple
                }


                // Sort upcoming cards ensuring isEssential comes first, then by priority, then lastRemovedFromQueue
                let upcomingCardsSorted = upcomingCards.sorted { lhs, rhs in
                    let lhsTuple = (lhs.isEssential ? 0 : 1, sortOrder(for: lhs), lhs.lastRemovedFromQueue ?? Date.distantPast)
                    let rhsTuple = (rhs.isEssential ? 0 : 1, sortOrder(for: rhs), rhs.lastRemovedFromQueue ?? Date.distantPast)
                    return lhsTuple < rhsTuple
                }

                // Sort archived cards ensuring isEssential comes first, then by priority, then lastRemovedFromQueue
                let archivedCardsSorted = archivedCards.sorted { lhs, rhs in
                    let lhsTuple = (lhs.isEssential ? 0 : 1, sortOrder(for: lhs), lhs.lastRemovedFromQueue ?? Date.distantPast)
                    let rhsTuple = (rhs.isEssential ? 0 : 1, sortOrder(for: rhs), rhs.lastRemovedFromQueue ?? Date.distantPast)
                    return lhsTuple < rhsTuple
                }
                
                List(selection: selectedCardBinding) {
                    EnqueuedSection(enqueuedCardsSorted: enqueuedCardsSorted)
                    UpcomingSection(upcomingCardsSorted: upcomingCardsSorted)
                    ArchivedSection(archivedCardsSorted: archivedCardsSorted)
                }
                .navigationTitle(selection.name)
                .listStyle(.sidebar)
                
                
            }
                else {
                    Text("Select a folder")
                        .foregroundColor(.gray)
                //SelectedFolderStatView(folder: selectedFolder, cards: filteredCards)
            }
            
        } detail: {
            // Detail column: displays details for the selected item.
            NavigationStack {
                if let card = selectedCard {
                    SelectedCardView(card: card, onAddCard: { addCard() }, isNew:isNew)
                } else   {
    
                    VStack {
                
                        if selectedFolder != nil {
                            if filteredCards.count > 0 {
                                SelectedFolderStatView(cards: filteredCards)
                            } else {
                                Text("No cards")
                            }
                        } else {
                            Text("No cards")
                        }
                    }
                }
            }
            .onChange(of: allCards) { _, newAllCards in
                if let selected = selectedCard, !newAllCards.contains(where: { $0.id == selected.id }) {
                    selectedCard = nil
                    cleanupOrphanTags()
                }
            }

            .toolbar {
                if UIDevice.current.userInterfaceIdiom != .phone {
                    if selectedCard != nil {
                        
                        
                        ToolbarItemGroup(placement: .topBarLeading) {
                            Button {
                                selectedCard = nil
                            } label: {
                                Image(systemName: "chevron.left")
                            }
                        }
                    }
                    ToolbarItemGroup(placement: .topBarTrailing) {
                        Button {
                            addCard()
                        } label: {
                            Image(systemName: "square.and.pencil")
                        }
                    }
                    
                }
            }
        }
        .toolbar {
            if UIDevice.current.userInterfaceIdiom == .phone {
                ToolbarItemGroup(placement: .bottomBar) {
                    
                    if selectedFolder == nil && selectedCard == nil {
                        Button {
                            showNewFolderInput.toggle()
                        } label: {
                            Image(systemName: "folder.badge.plus")
                        }
                        Spacer()
                        Button {
                            addCard()
                        } label: {
                            Image(systemName: "square.and.pencil")
                        }
                    } else if selectedFolder != nil && selectedCard == nil {
                        if let selection = selectedFolder {
                            switch selection {
                            case .allCards:
                                Spacer()
                                Text(allCards.count.description)
                                Spacer()
                                Button {
                                    addCard()
                                } label: {
                                    Image(systemName: "square.and.pencil")
                                }
                            case .folder(let folder):
                                Spacer()
                                Text(folder.unwrappedCards.count.description)
                                Spacer()
                                Button {
                                    addCard()
                                } label: {
                                    Image(systemName: "square.and.pencil")
                                }
                            }
                        }
                    }
                    
                }
            }
            
        }
        .sheet(isPresented: $showNewFolderInput) {
            NewFolderForm(selectedFolder: $selectedFolder)
        }
        .onOpenURL { url in
            guard url.scheme == "topnote", url.host == "card" else {
                return
            }
            let cardId = url.pathComponents[1]
            
            self.urlId = cardId
        }
        .onChange(of: urlId) { _, newValue in
            if !newValue.isEmpty, let cardUUID = UUID(uuidString: newValue) {
                if let clickedCard = allCards.first(where: { $0.id == cardUUID }) {
                    selectedCard = clickedCard
                    
                }
            }
        }
        .onChange(of: selectedCard) {
            if !isNew {
                cleanupOrphanTags()
                cleanUpEmptyCards()
            }
        }
        .onChange(of: selectedFolder) {
            selectedCard = nil
        }
        
    }
    
    
    private func addCard() {
        
        let folderForNewCard: Folder?
        if let selection = selectedFolder {
            switch selection {
            case .allCards:
                folderForNewCard = nil
            case .folder(let folder):
                folderForNewCard = folder
            }
        } else {
            folderForNewCard = nil
        }
        
        
        let newCard = Card(
            createdAt: Date(),
            cardType: .none,
            priorityTypeRaw: .none,
            content: "",
            spacedTimeFrame: 240,
            dynamicTimeframe: true,
            nextTimeInQueue: Calendar.current.date(byAdding: .hour, value: 240, to: Date()) ?? Date(),
            folder: folderForNewCard
        )
        
        if let folder = folderForNewCard {
            if folder.cards == nil {
                folder.cards = [newCard]
            } else {
                folder.cards?.append(newCard)
            }
            selectedFolder = .folder(folder)
        } else {
            selectedFolder = .allCards
        }
        
        modelContext.insert(newCard)
        isNew = true
        selectedCard = newCard
    }
    
    func cleanupOrphanTags() {
        for tag in tags {
            if tag.unwrappedCards.isEmpty {
                modelContext.delete(tag)
            }
        }
    }
    
    func cleanUpEmptyCards() {
        for card in allCards {
            if card != selectedCard && card.content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                modelContext.delete(card)
            }
        }
    }
    
    private func sortOrder(for card: Card) -> Int {
        guard let priority = PriorityType(rawValue: card.priorityRaw) else {
            return 3 // Default to lowest priority if unknown
        }
        switch priority {
        case .high:
            return 0
        case .med:
            return 1
        case .low:
            return 2
        case .none:
            return 3
        }
    }
}


//#Preview {
//    var previewModelContainer: ModelContainer = {
//        let schema = Schema([Card.self, Folder.self, Tag.self])
//
//        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
//
//        do {
//            return try ModelContainer(for: schema, configurations: [modelConfiguration])
//        } catch {
//            fatalError("Could not create ModelContainer: \(error)")
//        }
//    }()
//    
//    ContentView()
//        .modelContainer(previewModelContainer)
//}
