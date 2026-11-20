//
//  CaptureSheet.swift
//  TopNote
//
//  One place to capture any kind of card. The type picker stays at the top; the fields below
//  change to fit: a page for notes, question and answer for flashcards, when and repeat for to-dos.
//

import SwiftUI
import SwiftData
import TipKit

struct CaptureSheet: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Environment(AppRouter.self) private var router
    @ObservedObject private var reminders = RemindersSync.shared
    @Query(sort: \Folder.name) private var folders: [Folder]

    var defaultFolder: Folder? = nil
    var onSave: ((Card) -> Void)? = nil

    @State private var type: CardType
    @State private var text = ""
    @State private var answer = ""
    @State private var noteReturn: CardFactory.NoteReturn = .month
    @State private var when: TodoWhen = .now
    @State private var customDate = Date().addingTimeInterval(3600)
    @State private var todoRepeat: CardFactory.TodoRepeat = .never
    @State private var addToReminders = true
    @State private var folder: Folder?
    @State private var priority: PriorityType = .none
    @State private var showsMore = false
    @State private var addedCount = 0
    @State private var showsAI = false
    @State private var savedTrigger = 0
    @FocusState private var focus: Field?

    enum Field { case text, answer }

    enum TodoWhen: String, CaseIterable, Identifiable {
        case now = "Now"
        case tonight = "Tonight"
        case tomorrow = "Tomorrow"
        case nextWeek = "Next week"
        case pick = "Pick…"
        var id: String { rawValue }

        func date(custom: Date, now: Date = Date(), calendar: Calendar = .current) -> Date {
            let startOfToday = calendar.startOfDay(for: now)
            switch self {
            case .now: return now
            case .tonight:
                let evening = calendar.date(bySettingHour: 18, minute: 0, second: 0, of: now) ?? now
                return max(evening, now)
            case .tomorrow:
                return calendar.date(byAdding: DateComponents(day: 1, hour: 9), to: startOfToday) ?? now
            case .nextWeek:
                return calendar.date(byAdding: DateComponents(day: 7, hour: 9), to: startOfToday) ?? now
            case .pick: return custom
            }
        }
    }

    init(initialType: CardType, defaultFolder: Folder? = nil, onSave: ((Card) -> Void)? = nil) {
        _type = State(initialValue: initialType)
        _folder = State(initialValue: defaultFolder)
        self.defaultFolder = defaultFolder
        self.onSave = onSave
    }

    private var trimmedText: String { text.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var canSave: Bool {
        type == .flashcard
            ? !trimmedText.isEmpty && !answer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            : !trimmedText.isEmpty
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    typePicker
                    switch type {
                    case .note: noteFields
                    case .flashcard: flashcardFields
                    case .todo: todoFields
                    }
                    moreOptions
                }
                .padding(20)
            }
            .background(Theme.screen)
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle(addedCount > 0 ? "\(addedCount) added" : "New \(type.rawValue)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(addedCount > 0 ? "Done" : "Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save(keepOpen: false) }
                        .fontWeight(.semibold)
                        .disabled(!canSave)
                        .accessibilityIdentifier("captureSave")
                }
                if #available(iOS 26.0, *) {
                    ToolbarItem(placement: .topBarLeading) {
                        Button { showsAI = true } label: { Label("Generate with AI", systemImage: "sparkles") }
                            .accessibilityIdentifier("captureAI")
                    }
                }
            }
            .sensoryFeedback(.success, trigger: savedTrigger)
            .sheet(isPresented: $showsAI) {
                AICardGeneratorWrapper(currentFolder: folder, currentTagIDs: [], onCardsCreated: { cards in
                    TopNoteShared.reloadWidgets()
                    cards.forEach { onSave?($0) }
                    dismiss()
                })
            }
            .onAppear {
                focus = .text
                addToReminders = reminders.isActive && reminders.addsNewTodos
            }
            .onChange(of: type) { _, newType in
                router.lastCaptureType = newType
                focus = .text
            }
        }
        .presentationDetents([.large])
    }

    // MARK: - Type picker

    private var typePicker: some View {
        HStack(spacing: 8) {
            ForEach([CardType.note, .flashcard, .todo]) { option in
                Button {
                    withAnimation(.snappy) { type = option }
                } label: {
                    VStack(spacing: 6) {
                        Image(systemName: option.systemImage).font(.title3)
                        Text(option.rawValue).font(.subheadline.weight(.semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .foregroundStyle(type == option ? Color.white : option.tintColor)
                    .background(type == option ? AnyShapeStyle(option.tintColor.gradient) : AnyShapeStyle(option.tintColor.opacity(0.1)),
                                in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(type == option ? .isSelected : [])
                .accessibilityIdentifier("captureType-\(option.routeName)")
            }
        }
    }

    // MARK: - Notes

    private var noteFields: some View {
        VStack(alignment: .leading, spacing: 16) {
            ZStack(alignment: .topLeading) {
                NotePaper()
                if text.isEmpty {
                    Text(CardType.note.capturePrompt)
                        .font(Theme.noteFont)
                        .foregroundStyle(Theme.ink.opacity(0.4))
                        .padding(.horizontal, 21)
                        .padding(.vertical, 24)
                        .allowsHitTesting(false)
                }
                TextEditor(text: $text)
                    .font(Theme.noteFont)
                    .foregroundStyle(Theme.ink)
                    .lineSpacing(6)
                    .scrollContentBackground(.hidden)
                    .focused($focus, equals: .text)
                    .padding(16)
                    .accessibilityIdentifier("captureText")
            }
            .frame(minHeight: 220)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .shadow(color: .brown.opacity(0.12), radius: 10, y: 4)

            Text("Markdown works: **bold**, *italic*, [links](https://apple.com).")
                .font(.caption)
                .foregroundStyle(.secondary)

            sectionTitle("Bring it back")
            ChipRow(options: CardFactory.NoteReturn.allCases, selection: $noteReturn, tint: CardType.note.tintColor) { $0.rawValue }
            Text(noteReturn.explanation)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Flashcards

    private var flashcardFields: some View {
        VStack(alignment: .leading, spacing: 14) {
            fieldCard(title: "Question", tint: CardType.flashcard.tintColor) {
                TextField("What do you want to be asked?", text: $text, axis: .vertical)
                    .font(Theme.questionFont)
                    .lineLimit(2...6)
                    .focused($focus, equals: .text)
                    .submitLabel(.next)
                    .onSubmit { focus = .answer }
                    .accessibilityIdentifier("captureText")
            }
            fieldCard(title: "Answer", tint: CardType.flashcard.tintColor) {
                TextField("What should you remember?", text: $answer, axis: .vertical)
                    .font(.title3)
                    .lineLimit(1...8)
                    .focused($focus, equals: .answer)
                    .accessibilityIdentifier("captureAnswer")
            }
            Button {
                save(keepOpen: true)
            } label: {
                Label("Save and add another", systemImage: "plus.rectangle.on.rectangle")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .tint(CardType.flashcard.tintColor)
            .controlSize(.large)
            .disabled(!canSave)
            .accessibilityIdentifier("captureSaveAnother")
            Text("New flashcards are ready to study now. Hard brings a card back sooner; Good and Easy space it out, starting from 3 days.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - To-dos

    private var todoFields: some View {
        VStack(alignment: .leading, spacing: 16) {
            fieldCard(title: nil, tint: CardType.todo.tintColor) {
                HStack(alignment: .firstTextBaseline, spacing: 12) {
                    Image(systemName: "circle")
                        .font(.title3)
                        .foregroundStyle(CardType.todo.tintColor)
                    TextField(CardType.todo.capturePrompt, text: $text, axis: .vertical)
                        .font(.title3.weight(.semibold))
                        .lineLimit(1...4)
                        .focused($focus, equals: .text)
                        .accessibilityIdentifier("captureText")
                }
            }
            sectionTitle("When")
            ChipRow(options: TodoWhen.allCases, selection: $when, tint: CardType.todo.tintColor) { $0.rawValue }
            if when == .pick {
                DatePicker("Due", selection: $customDate, in: Date()..., displayedComponents: [.date, .hourAndMinute])
                    .datePickerStyle(.compact)
            } else {
                Text(when == .now ? "Shows up in Up Next right away." : "Shows up \(when.date(custom: customDate).formatted(.relative(presentation: .named))).")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            sectionTitle("Repeat")
            ChipRow(options: CardFactory.TodoRepeat.allCases, selection: $todoRepeat, tint: CardType.todo.tintColor) { $0.rawValue }

            if reminders.isActive {
                Toggle(isOn: $addToReminders) {
                    Label("Add to Reminders · \(reminders.selectedList?.title ?? "")", systemImage: "list.bullet.circle")
                }
                .tint(CardType.todo.tintColor)
                .padding(14)
                .background(Theme.cardSurface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                .accessibilityIdentifier("captureAddToReminders")
            } else {
                Button {
                    dismiss()
                    router.open(.settings("reminders"))
                } label: {
                    Label("Keep to-dos in sync with Apple Reminders", systemImage: "list.bullet.circle")
                        .font(.subheadline)
                }
            }
        }
    }

    // MARK: - More options

    private var moreOptions: some View {
        DisclosureGroup(isExpanded: $showsMore) {
            VStack(spacing: 12) {
                Picker("Folder", selection: $folder) {
                    Text("None").tag(Folder?.none)
                    ForEach(folders) { folder in
                        Text(folder.name).tag(Optional(folder))
                    }
                }
                Picker("Priority", selection: $priority) {
                    ForEach(PriorityType.allCases) { priority in
                        Label(priority.displayName, systemImage: priority.iconName).tag(priority)
                    }
                }
            }
            .padding(.top, 8)
        } label: {
            Text("Folder and priority")
                .font(.subheadline.weight(.semibold))
        }
        .padding(14)
        .background(Theme.cardSurface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    // MARK: - Helpers

    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.footnote.weight(.semibold))
            .foregroundStyle(.secondary)
            .textCase(.uppercase)
    }

    private func fieldCard<Content: View>(title: String?, tint: Color, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            if let title {
                Text(title.uppercased())
                    .font(.caption.weight(.bold))
                    .tracking(1)
                    .foregroundStyle(tint)
            }
            content()
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.cardSurface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func save(keepOpen: Bool) {
        guard canSave else { return }
        let card: Card
        switch type {
        case .note:
            card = CardFactory.makeNote(content: trimmedText, returns: noteReturn, folder: folder, priority: priority)
        case .flashcard:
            card = CardFactory.makeFlashcard(question: trimmedText, answer: answer.trimmingCharacters(in: .whitespacesAndNewlines), folder: folder, priority: priority)
        case .todo:
            card = CardFactory.makeTodo(content: trimmedText, due: when.date(custom: customDate), repeatHours: todoRepeat.hours, folder: folder, priority: priority)
        }
        context.insert(card)
        do {
            try context.save()
        } catch {
            TopNoteLogger.cardMutation.error("Capture save failed: \(error.localizedDescription)")
        }
        if type == .todo, addToReminders {
            reminders.addReminder(for: card)
        }
        TopNoteShared.reloadWidgets()
        TopNoteTips.donate(TopNoteTips.cardCreated)
        if type == .todo { TopNoteTips.donate(TopNoteTips.todoCreated) }
        onSave?(card)
        savedTrigger += 1
        router.lastCaptureType = type

        if keepOpen {
            addedCount += 1
            text = ""
            answer = ""
            focus = .text
        } else {
            dismiss()
        }
    }
}

/// A row of selectable chips for a small set of choices.
struct ChipRow<Option: Hashable & Identifiable>: View {
    let options: [Option]
    @Binding var selection: Option
    let tint: Color
    let title: (Option) -> String

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(options) { option in
                    Button {
                        withAnimation(.snappy) { selection = option }
                    } label: {
                        Text(title(option))
                            .font(.subheadline.weight(.semibold))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .foregroundStyle(selection == option ? Color.white : tint)
                            .background(selection == option ? AnyShapeStyle(tint) : AnyShapeStyle(tint.opacity(0.1)), in: Capsule())
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(selection == option ? .isSelected : [])
                }
            }
        }
        .scrollClipDisabled()
    }
}
