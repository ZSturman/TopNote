import SwiftUI
import SwiftData
import WidgetKit


struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var folders: [Folder]
    @Query private var allCards: [Card]
    @Query private var tags: [Tag]
    //@State private var selectedTags: [Tag] = []
    //@State private var deselectedTags: [Tag] = []
    
    @State private var tagSelectionStates: [UUID: TagSelectionState] = [:]
    @State private var selectedFolder: FolderSelection? = .allCards
    @State private var selectedCard: Card?
    @State private var showNewFolderInput: Bool = false
    
    @State private var isNew: Bool = false
    
    @State var urlId: String = ""
    
    enum TagSelectionState {
        case selected, deselected, neutral
    }
    
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
                
                Section(header: Text("Tags")) {
                    ForEach(tags.sorted { $0.name < $1.name }) { tag in
                        HStack {
                            Text(tag.name)
                            // Show a textual indicator of the current tag state.
                            switch tagSelectionStates[tag.id] ?? .neutral {
                            case .neutral:
                                Text("Neutral")
                                    .foregroundColor(.gray)
                            case .selected:
                                Text("Selected")
                                    .foregroundColor(.green)
                            case .deselected:
                                Text("Deselected")
                                    .foregroundColor(.red)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            // Cycle the state: neutral -> selected -> deselected -> neutral.
                            let currentState = tagSelectionStates[tag.id] ?? .neutral
                            let newState: TagSelectionState
                            switch currentState {
                            case .neutral:
                                newState = .selected
                            case .selected:
                                newState = .deselected
                            case .deselected:
                                newState = .neutral
                            }
                            tagSelectionStates[tag.id] = newState
                        }
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                modelContext.delete(tag)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                            
                        }
                    }
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
                    
                    Section(header: Text("Enqueue")) {
                        ForEach(enqueuedCardsSorted) { card in
                            NavigationLink(value: card) {
                                HStack {
                                    selectedCardType(cardType: card.cardType)
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
                                    cleanupOrphanTags()
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
                                    modelContext.delete(card)
                                    cleanupOrphanTags()
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                                
                                
                            }
                        }
                    }
                    
                    
                    Section(header: Text("Upcoming")) {
                        ForEach(upcomingCardsSorted) { card in
                            NavigationLink(value: card) {
                                HStack {
                                    selectedCardType(cardType: card.cardType)
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
                                    cleanupOrphanTags()
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
                                    cleanupOrphanTags()
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                                
                            }
                        }
                        
                    }
                    
                    Section(header: Text("Archived")) {
                        ForEach(archivedCardsSorted) { card in
                            NavigationLink(value: card) {
                                HStack {
                                    selectedCardType(cardType: card.cardType)
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
                            
                            Divider()
                            
                            
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    modelContext.delete(card)
                                    cleanupOrphanTags()
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                      
                            }
                        }
                        
                    }
                }
                .navigationTitle(selection.name)
                
                
            } else {
                Text("Select a folder")
                    .foregroundColor(.gray)
            }
            
        } detail: {
            // Detail column: displays details for the selected item.
            NavigationStack {
                if let card = selectedCard {
                    SelectedCardView(card: card, onAddCard: { addCard() }, isNew:isNew)
                } else {
                    Text("Select a card")
                        .foregroundColor(.gray)
                }
            }
            .onChange(of: allCards) { _, newAllCards in
                if let selected = selectedCard, !newAllCards.contains(where: { $0.id == selected.id }) {
                    selectedCard = nil
                }
            }
            .toolbar {
                if UIDevice.current.userInterfaceIdiom != .phone {
                    ToolbarItemGroup(placement: .topBarLeading) {
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
    
    @ViewBuilder
    private func selectedCardType(cardType: CardType) -> some View {
        switch cardType {
        case .flashCard:
            FlashCardIcon()
                .frame(width: 40, height: 40)
        case .none:
            PlainCardIcon()
                .frame(width: 40, height: 40)
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
//    ContentView()
//        .modelContainer(previewContainer)
//}
