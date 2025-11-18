import SwiftUI
import SwiftData
import WidgetKit

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @State var tagSelectionStates: [UUID: TagSelectionState] = [:]
    @State private var selectedFolder: FolderSelection? = .allCards
    @StateObject var selectedCardModel = SelectedCardModel()
    
    @State private var showNewFolderInput: Bool = false
    @State var urlId: String = ""
    
    var body: some View {
        NavigationSplitView {
            FolderList(selectedFolder: $selectedFolder, tagSelectionStates: $tagSelectionStates)
    
        } detail: {
            
            // Pass selectedCardID for deep-link URL selection
            CardListView(selectedFolder: $selectedFolder, tagSelectionStates: tagSelectionStates)
                .environmentObject(selectedCardModel)
        }
        .sheet(isPresented: $showNewFolderInput) {
            NavigationStack {
                NewFolderForm(selectedFolder: $selectedFolder)
            }
        }
        .presentationDetents([.medium])
        .onOpenURL { url in
            guard url.scheme == "topnote", url.host == "card" else {
                return
            }
            let cardId = url.pathComponents[1]
            
            self.urlId = cardId
            if let uuid = UUID(uuidString: cardId) {
                selectedCardModel.selectCard(with: uuid, modelContext: modelContext, isNew: false)
            }
        }
        
    }
}
