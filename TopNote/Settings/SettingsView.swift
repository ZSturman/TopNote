//
//  SettingsView.swift
//  TopNote
//

import SwiftUI
import SwiftData
import AppIntents
import EventKit

struct SettingsView: View {
    @Environment(AppRouter.self) private var router
    @Environment(\.modelContext) private var context
    @ObservedObject private var reminders = RemindersSync.shared
    @Query private var cards: [Card]
    @State private var showsExport = false
    @State private var path = NavigationPath()
    @State private var tipsResetConfirmed = false

    private var version: String {
        let info = Bundle.main.infoDictionary
        return "\(info?["CFBundleShortVersionString"] as? String ?? "") (\(info?["CFBundleVersion"] as? String ?? ""))"
    }

    var body: some View {
        NavigationStack(path: $path) {
            Form {
                Section {
                    NavigationLink(value: "reminders") {
                        Label {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Apple Reminders")
                                Text(reminders.isActive ? "Synced with \(reminders.selectedList?.title ?? "a list")" : "Not connected")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        } icon: {
                            Image(systemName: "list.bullet.circle.fill").foregroundStyle(CardType.todo.tintColor)
                        }
                    }
                    .accessibilityIdentifier("settingsReminders")
                } header: {
                    Text("Connections")
                }

                Section("Everywhere") {
                    Button { router.sheet = .widgetGuide } label: {
                        Label("Add the Home Screen widget", systemImage: "widget.medium")
                    }
                    Button { router.sheet = .shortcutsGuide } label: {
                        Label("Siri, Shortcuts and Control Center", systemImage: "mic.circle")
                    }
                }

                Section("Help") {
                    Button { router.sheet = .onboarding } label: {
                        Label("How Top Note works", systemImage: "questionmark.circle")
                    }
                    Button { router.sheet = .whatsNew } label: {
                        Label("What's new in 2.0", systemImage: "sparkles")
                    }
                    Button {
                        TopNoteTips.resetOnNextLaunch()
                        tipsResetConfirmed = true
                    } label: {
                        Label("Show tips again", systemImage: "lightbulb")
                    }
                    if cards.isEmpty {
                        Button {
                            CardFactory.insertExamples(into: context)
                            router.tab = .upNext
                        } label: {
                            Label("Add example cards", systemImage: "rectangle.stack.badge.plus")
                        }
                    }
                }

                Section {
                    Button { showsExport = true } label: {
                        Label("Export, import and share", systemImage: "square.and.arrow.up.on.square")
                    }
                } header: {
                    Text("Your cards")
                } footer: {
                    Text("Your cards stay on your devices and in your private iCloud. Top Note has no account, ads or tracking.")
                }

                Section {
                    LabeledContent("Version", value: version)
                }
            }
            .navigationTitle("Settings")
            .navigationDestination(for: String.self) { destination in
                if destination == "reminders" { RemindersSettingsView() }
            }
            .sheet(isPresented: $showsExport) {
                ExportImportSheet(filteredCards: cards, allCards: cards)
            }
            .alert("Tips will appear again", isPresented: $tipsResetConfirmed) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("The next time you open Top Note, tips start over from the beginning.")
            }
            .onAppear(perform: consumeRoute)
            .onChange(of: router.showsRemindersSettings) { _, _ in consumeRoute() }
        }
    }

    private func consumeRoute() {
        guard router.showsRemindersSettings else { return }
        router.showsRemindersSettings = false
        path = NavigationPath(["reminders"])
    }
}

// MARK: - Reminders

struct RemindersSettingsView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.openURL) private var openURL
    @ObservedObject private var reminders = RemindersSync.shared
    @State private var isWorking = false
    @State private var errorMessage: String?

    var body: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: 10) {
                    Image(systemName: "list.bullet.circle.fill")
                        .font(.largeTitle)
                        .foregroundStyle(CardType.todo.tintColor)
                    Text("To-dos and Reminders, in sync")
                        .font(.title3.weight(.semibold))
                    Text("Choose a Reminders list. Check something off in either app and it's done in both. New reminders in that list show up in Up Next when they're due, and to-dos you add here appear in Reminders, Siri and on your Apple Watch.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 6)
            }

            switch reminders.authorization {
            case .fullAccess:
                connectedSections
            case .denied, .restricted, .writeOnly:
                Section {
                    Text("Top Note doesn't have permission to see your reminders.")
                    Button("Open Settings") {
                        if let url = URL(string: UIApplication.openSettingsURLString) { openURL(url) }
                    }
                } footer: {
                    Text("Allow Full Access for Top Note under Settings › Privacy & Security › Reminders.")
                }
            default:
                Section {
                    Button {
                        Task {
                            isWorking = true
                            if await reminders.requestAccess() {
                                connect(listID: nil)
                            }
                            isWorking = false
                        }
                    } label: {
                        HStack {
                            Text("Connect Reminders")
                            if isWorking { Spacer(); ProgressView() }
                        }
                    }
                    .accessibilityIdentifier("connectReminders")
                } footer: {
                    Text("Top Note creates a list called “Top Note” unless you pick another one.")
                }
            }
        }
        .navigationTitle("Reminders")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { reminders.refreshAuthorization() }
        .alert("Couldn't connect", isPresented: .constant(errorMessage != nil)) {
            Button("OK") { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
    }

    @ViewBuilder
    private var connectedSections: some View {
        Section("List") {
            Picker("Sync with", selection: Binding(
                get: { reminders.isEnabled ? reminders.listID : nil },
                set: { newValue in
                    if let newValue { connect(listID: newValue) } else { reminders.disconnect() }
                }
            )) {
                Text("Off").tag(String?.none)
                ForEach(reminders.lists, id: \.calendarIdentifier) { list in
                    Label {
                        Text(list.title)
                    } icon: {
                        Image(systemName: "circle.fill").foregroundStyle(Color(cgColor: list.cgColor))
                    }
                    .tag(Optional(list.calendarIdentifier))
                }
            }
            .pickerStyle(.navigationLink)
            .accessibilityIdentifier("remindersListPicker")
            if !reminders.lists.contains(where: { $0.title == "Top Note" }) {
                Button("Create a “Top Note” list") { connect(listID: nil) }
            }
        }

        if reminders.isActive {
            Section {
                Toggle("Bring in new reminders", isOn: $reminders.importsNewReminders)
                Toggle("Add new to-dos to Reminders", isOn: $reminders.addsNewTodos)
            } footer: {
                Text("Reminders you add to this list become Top Note to-dos. Turn off “Add new to-dos” to choose for each one when you create it.")
            }

            Section {
                Button {
                    Task {
                        isWorking = true
                        await reminders.sync(context: context)
                        isWorking = false
                    }
                } label: {
                    HStack {
                        Text("Sync now")
                        Spacer()
                        if isWorking { ProgressView() }
                    }
                }
                .accessibilityIdentifier("syncRemindersNow")
            } footer: {
                if let report = reminders.lastReport, let date = reminders.lastSyncDate {
                    Text("\(report.summary) Last synced \(date.formatted(.relative(presentation: .named))).")
                }
            }
        }
    }

    private func connect(listID: String?) {
        do {
            try reminders.connect(listID: listID)
            Task { await reminders.sync(context: context) }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

// MARK: - Widget guide

struct WidgetGuideView: View {
    @Environment(\.dismiss) private var dismiss

    private let steps: [(symbol: String, title: String, detail: String)] = [
        ("hand.tap", "Edit your Home Screen", "Touch and hold an empty spot until the apps jiggle, then tap Edit › Add Widget."),
        ("magnifyingglass", "Find Top Note", "Search for Top Note, choose a size and tap Add Widget. Medium and Large have buttons; Small shows what's next."),
        ("hand.point.up.left", "Use it right there", "Flip a flashcard and rate it, check off a to-do, or tap Got it on a note. The next card appears without opening the app."),
        ("slider.horizontal.3", "Give it a job", "Touch and hold the widget › Edit Widget to show only certain kinds of cards or folders. Add a few with different choices."),
        ("lock", "Lock Screen too", "On the Lock Screen, tap the clock › Add Widgets › Top Note to see how many cards are ready and the next one.")
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    WidgetPreviewDrawing()
                        .frame(maxWidth: .infinity)
                        .accessibilityLabel("Example of the medium Top Note widget showing a flashcard with Show answer and Skip buttons")
                    ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                        HStack(alignment: .top, spacing: 14) {
                            ZStack {
                                Circle().fill(Color.accentColor.opacity(0.14)).frame(width: 40, height: 40)
                                Image(systemName: step.symbol).foregroundStyle(Color.accentColor)
                            }
                            .accessibilityHidden(true)
                            VStack(alignment: .leading, spacing: 4) {
                                Text("\(index + 1). \(step.title)").font(.headline)
                                Text(step.detail).font(.subheadline).foregroundStyle(.secondary)
                            }
                        }
                        .accessibilityElement(children: .combine)
                    }
                }
                .padding(24)
            }
            .navigationTitle("Add the widget")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } }
            }
        }
    }
}

/// A drawing of the medium widget, matching the real one's layout.
private struct WidgetPreviewDrawing: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 5) {
                Image(systemName: CardType.flashcard.systemImage).foregroundStyle(CardType.flashcard.tintColor)
                Text("FLASHCARD").font(.caption2.weight(.bold)).foregroundStyle(.secondary)
                Spacer()
                Text("4 ready").font(.caption2.weight(.semibold)).foregroundStyle(.secondary)
            }
            Text("What is the capital of Australia?")
                .font(.system(.headline, design: .rounded))
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            HStack(spacing: 6) {
                Label("Show answer", systemImage: "arrow.2.squarepath")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity, minHeight: 34)
                    .foregroundStyle(.white)
                    .background(CardType.flashcard.tintColor, in: Capsule())
                Text("Skip")
                    .font(.subheadline.weight(.semibold))
                    .padding(.horizontal, 16)
                    .frame(minHeight: 34)
                    .background(Color.secondary.opacity(0.15), in: Capsule())
            }
        }
        .padding(16)
        .frame(width: 338, height: 158)
        .background(CardType.flashcard.tintColor.opacity(0.08), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .background(Theme.cardSurface, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: .black.opacity(0.12), radius: 18, y: 8)
    }
}

// MARK: - Siri and Shortcuts

struct ShortcutsGuideView: View {
    @Environment(\.dismiss) private var dismiss

    private let phrases: [(String, String)] = [
        ("Add a note in Top Note", "Saves a note without opening the app"),
        ("Add a to-do in Top Note", "Saves a to-do, and adds it to Reminders if connected"),
        ("Add a flashcard in Top Note", "Asks for a question and an answer"),
        ("What's next in Top Note", "Reads your next card"),
        ("How many cards are ready in Top Note", "Counts what's waiting"),
        ("Study flashcards in Top Note", "Opens Up Next with flashcards only")
    ]

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(phrases, id: \.0) { phrase, detail in
                        VStack(alignment: .leading, spacing: 3) {
                            Text("“\(phrase)”").font(.headline)
                            Text(detail).font(.subheadline).foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 2)
                    }
                } header: {
                    Text("Say to Siri")
                }
                Section {
                    Label("Add a Top Note button to Control Center: swipe down, tap +, then Add a Control and search for Top Note.", systemImage: "switch.2")
                    Label("On iPhone with an Action button: Settings › Action Button › Shortcut › Top Note.", systemImage: "button.horizontal.top.press")
                    Label("Every action is in the Shortcuts app, ready for your own automations.", systemImage: "square.2.layers.3d")
                } header: {
                    Text("More ways in")
                }
                Section {
                    ShortcutsLink()
                        .shortcutsLinkStyle(.automaticOutline)
                        .frame(maxWidth: .infinity)
                        .listRowBackground(Color.clear)
                }
            }
            .navigationTitle("Siri and Shortcuts")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } }
            }
        }
    }
}
