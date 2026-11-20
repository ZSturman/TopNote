import SwiftUI
import SwiftData
import TipKit
import WidgetKit

/// Up Next for what's ready now, Library for everything, Settings for connections and help.
struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityVoiceOverEnabled) private var voiceOverEnabled
    @State private var router = AppRouter()
    @State private var splashDone = false
    @ObservedObject private var reminders = RemindersSync.shared

    var body: some View {
        TabView(selection: $router.tab) {
            Tab("Up Next", systemImage: "rectangle.stack.fill", value: AppRouter.Tab.upNext) {
                UpNextView()
            }
            Tab("Library", systemImage: "books.vertical.fill", value: AppRouter.Tab.library) {
                LibraryView()
            }
            Tab("Settings", systemImage: "gearshape.fill", value: AppRouter.Tab.settings) {
                SettingsView()
            }
        }
        .tabViewStyle(.sidebarAdaptable)
        .environment(router)
        .sheet(item: $router.sheet) { sheet in
            switch sheet {
            case .capture(let type):
                CaptureSheet(initialType: type)
                    .environment(router)
            case .widgetGuide:
                WidgetGuideView()
            case .shortcutsGuide:
                ShortcutsGuideView()
            case .whatsNew:
                WhatsNewView()
            case .onboarding:
                OnboardingView()
                    .environment(router)
                    .interactiveDismissDisabled()
            }
        }
        .accessibilityHidden(!splashDone)
        .overlay {
            if !splashDone {
                LaunchSplash()
                    .transition(.opacity)
            }
        }
        .animation(.easeOut(duration: 0.35), value: splashDone)
        .task {
            let hold = LaunchSplash.hold(voiceOver: voiceOverEnabled)
            if hold > .zero { try? await Task.sleep(for: hold) }
            splashDone = true
            TopNoteTips.donate(TopNoteTips.appOpened)
            let hasCards = ((try? modelContext.fetchCount(FetchDescriptor<Card>())) ?? 0) > 0
            if router.sheet == nil, let welcome = WelcomeState.sheetForLaunch(hasCards: hasCards) {
                router.sheet = welcome
            }
        }
        #if DEBUG
        .task {
            // Device test setup only: asks for Reminders access so the EventKit suite can run.
            if ProcessInfo.processInfo.arguments.contains("-TopNoteRequestRemindersAccess") {
                _ = await reminders.requestAccess()
            }
        }
        #endif
        .task {
            LibraryMaintenance.runOnLaunch(context: modelContext)
            reminders.startObserving(container: modelContext.container)
            await reminders.sync(context: modelContext)
        }
        .onChange(of: scenePhase) { _, phase in
            guard phase == .active else { return }
            Task { await reminders.sync(context: modelContext) }
        }
        .onOpenURL { url in
            guard let route = TopNoteRoute(url: url) else { return }
            router.open(route) { id in
                let now = Date()
                let descriptor = FetchDescriptor<Card>(predicate: #Predicate { $0.id == id })
                guard let card = try? modelContext.fetch(descriptor).first else { return false }
                return card.isEnqueue(currentDate: now) && !card.isDeleted
            }
        }
    }
}

/// Every card, organized by folder and tag (the 1.x main screen).
struct LibraryView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AppRouter.self) private var router
    @State var tagSelectionStates: [UUID: TagSelectionState] = [:]
    @State private var selectedFolder: FolderSelection? = .allCards
    @StateObject var selectedCardModel = SelectedCardModel()
    @State private var deepLinkedCardID: UUID? = nil

    var body: some View {
        NavigationSplitView {
            FolderList(selectedFolder: $selectedFolder, tagSelectionStates: $tagSelectionStates)
        } detail: {
            CardListView(
                selectedFolder: $selectedFolder,
                tagSelectionStates: $tagSelectionStates,
                deepLinkedCardID: $deepLinkedCardID
            )
            .environmentObject(selectedCardModel)
        }
        .onAppear(perform: consumeDeepLink)
        .onChange(of: router.libraryCardID) { _, _ in consumeDeepLink() }
    }

    private func consumeDeepLink() {
        guard let id = router.libraryCardID else { return }
        router.libraryCardID = nil
        selectedFolder = .allCards
        deepLinkedCardID = id
        selectedCardModel.selectCard(with: id, modelContext: modelContext, isNew: false)
    }
}
