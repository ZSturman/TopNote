//
//  UpNextView.swift
//  TopNote
//
//  The card that matters right now, and only that card. Each kind of card has its own stage:
//  flashcards flip and rate, to-dos check off, notes are read and set aside.
//

import SwiftUI
import SwiftData
import TipKit
import WidgetKit

struct UpNextView: View {
    @Environment(\.modelContext) private var context
    @Environment(AppRouter.self) private var router
    @Environment(\.scenePhase) private var scenePhase

    @Query(filter: #Predicate<Card> { $0.deletedAt == nil && $0.isArchived == false })
    private var activeCards: [Card]

    @State private var now = Date()
    @State private var stats = ActivityStats()
    @State private var editingCard: Card?
    @State private var reviewsAhead = false
    @State private var lastAction: LastAction?
    @State private var feedbackTrigger = 0

    private let tipGroup = TopNoteTips.upNextGroup()
    private let addFirstCardTip = AddFirstCardTip()

    struct LastAction: Equatable {
        let message: String
        let cardID: UUID
    }

    private var filter: CardType? { router.upNextFilter }

    private func matchesFilter(_ card: Card) -> Bool {
        filter == nil || card.cardType == filter
    }

    /// Ready now, in the same order as the widget: priority first, then longest waiting.
    private var queue: [Card] {
        activeCards
            .filter { $0.nextTimeInQueue <= now && matchesFilter($0) }
            .sorted { ($0.priority.sortValue, $0.nextTimeInQueue) < ($1.priority.sortValue, $1.nextTimeInQueue) }
    }

    /// Flashcards are never overdue, so you can always study ahead (as in Recallable).
    private var aheadFlashcards: [Card] {
        activeCards
            .filter { $0.cardType == .flashcard && $0.nextTimeInQueue > now && (filter == nil || filter == .flashcard) }
            .sorted { $0.nextTimeInQueue < $1.nextTimeInQueue }
    }

    private var stage: [Card] { queue.isEmpty && reviewsAhead ? aheadFlashcards : queue }

    private var nextUpcoming: Card? {
        activeCards
            .filter { $0.nextTimeInQueue > now && matchesFilter($0) }
            .min { $0.nextTimeInQueue < $1.nextTimeInQueue }
    }

    private func count(_ type: CardType?) -> Int {
        activeCards.filter { $0.nextTimeInQueue <= now && (type == nil || $0.cardType == type) }.count
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    header
                    filterBar
                    TipView(tipGroup.currentTip, arrowEdge: nil) { action in
                        handleTipAction(action.id)
                    }
                    .tipBackground(Theme.cardSurface)

                    if let card = stage.first {
                        CardStage(card: card, isReviewingAhead: queue.isEmpty, perform: { perform($0, on: card) }, edit: { editingCard = card })
                            .id(card.id)
                            .transition(.asymmetric(
                                insertion: .move(edge: .trailing).combined(with: .opacity),
                                removal: .move(edge: .leading).combined(with: .opacity)
                            ))
                        if stage.count > 1 {
                            ThenList(cards: Array(stage.dropFirst().prefix(4)), remaining: max(0, stage.count - 5))
                        }
                    } else if activeCards.isEmpty {
                        EmptyLibraryView(addTip: addFirstCardTip) { router.capture($0) }
                    } else {
                        CaughtUpView(
                            filter: filter,
                            nextCard: nextUpcoming,
                            aheadCount: aheadFlashcards.count,
                            now: now,
                            reviewAhead: { withAnimation(.snappy) { reviewsAhead = true } },
                            capture: { router.capture() }
                        )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
                .frame(maxWidth: 640)
                .frame(maxWidth: .infinity)
            }
            .background(Theme.screen)
            .navigationTitle("Up Next")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        ForEach(CardType.allCases) { type in
                            Button { router.capture(type) } label: {
                                Label("New \(type.rawValue)", systemImage: type.systemImage)
                            }
                        }
                    } label: {
                        Label("Add", systemImage: "plus")
                    } primaryAction: {
                        router.capture()
                    }
                    .accessibilityIdentifier("captureButton")
                }
            }
            .overlay(alignment: .bottom) {
                if let lastAction {
                    UndoToast(message: lastAction.message) { undo() }
                        .padding(.bottom, 12)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .sensoryFeedback(.success, trigger: feedbackTrigger)
            .sheet(item: $editingCard) { card in
                CardDetailView(card: card, moveAction: {}, tagAction: {})
            }
            .task(id: scenePhase) {
                guard scenePhase == .active else { return }
                refresh()
                while !Task.isCancelled {
                    try? await Task.sleep(for: .seconds(30))
                    now = Date()
                }
            }
            .onChange(of: activeCards.count) { _, _ in refresh() }
            .onChange(of: router.upNextFilter) { _, _ in reviewsAhead = false }
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(headline)
                .font(.title3.weight(.semibold))
                .contentTransition(.numericText())
                .accessibilityIdentifier("upNextHeadline")
            HStack(spacing: 14) {
                if stats.handledToday > 0 {
                    Label("\(stats.handledToday) done today", systemImage: "checkmark.circle")
                }
                if stats.streakDays > 1 {
                    Label("\(stats.streakDays)-day streak", systemImage: "flame")
                }
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
        .padding(.top, 4)
    }

    private var headline: String {
        let count = queue.count
        if reviewsAhead && queue.isEmpty { return "Reviewing flashcards ahead" }
        switch count {
        case 0: return "Nothing waiting"
        case 1: return "1 card ready"
        default: return "\(count) cards ready"
        }
    }

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                TypeFilterChip(title: "All", systemImage: "square.stack", count: count(nil), tint: .accentColor, isOn: filter == nil) {
                    router.upNextFilter = nil
                }
                ForEach([CardType.note, .flashcard, .todo]) { type in
                    TypeFilterChip(title: type.pluralName, systemImage: type.systemImage, count: count(type), tint: type.tintColor, isOn: filter == type) {
                        router.upNextFilter = filter == type ? nil : type
                    }
                }
            }
        }
        .scrollClipDisabled()
    }

    // MARK: - Actions

    private func perform(_ action: CardAction, on card: Card) {
        let date = Date()
        undoSnapshot = (card.id, CardUndoSnapshot(card))
        let message: String
        switch action {
        case .rate(let rating):
            let hours = card.previewIntervalHours(for: rating)
            card.submitFlashcardRating(rating, at: date)
            message = card.isRecurring || hours > 0 ? "\(rating.rawValue) · back \(IntervalText.long(hours: card.repeatInterval))" : "\(rating.rawValue) · archived"
        case .complete:
            card.markAsComplete(at: date)
            message = card.isRecurring ? "Done · back \(IntervalText.long(hours: card.repeatInterval))" : "Done"
        case .next:
            card.next(at: date)
            message = card.isRecurring ? "Got it · back \(IntervalText.long(hours: card.repeatInterval))" : "Got it · archived"
        case .skip:
            card.skip(at: date)
            message = "Later · back \(IntervalText.long(hours: card.repeatInterval))"
        case .archive:
            card.archive(at: date)
            message = "Archived"
        case .addThought(let thought):
            let stamp = date.formatted(date: .abbreviated, time: .omitted)
            card.content += "\n\n— \(stamp): \(thought)"
            card.next(at: date)
            message = "Thought added · back \(IntervalText.long(hours: card.repeatInterval))"
        }
        save()
        withAnimation(.snappy) {
            lastAction = LastAction(message: message, cardID: card.id)
            now = Date()
        }
        feedbackTrigger += 1
        TopNoteTips.donate(TopNoteTips.cardHandled)
        let actionID = lastAction
        let isTodo = card.cardType == .todo
        Task {
            try? await Task.sleep(for: .seconds(4))
            if lastAction == actionID { withAnimation { lastAction = nil } }
            // Reminders hear about it once Undo is no longer offered.
            if isTodo { await RemindersSync.shared.sync(context: context) }
        }
    }

    /// Undo restores the card exactly as it was before the last action.
    @State private var undoSnapshot: (UUID, CardUndoSnapshot)?

    private func undo() {
        guard let lastAction, let (id, snapshot) = undoSnapshot, id == lastAction.cardID,
              let card = activeCardsIncludingArchived(id: id) else {
            withAnimation { self.lastAction = nil }
            return
        }
        snapshot.restore(card)
        save()
        withAnimation(.snappy) {
            self.lastAction = nil
            now = Date()
        }
    }

    private func activeCardsIncludingArchived(id: UUID) -> Card? {
        try? context.fetch(FetchDescriptor<Card>(predicate: #Predicate { $0.id == id })).first
    }

    private func save() {
        do {
            try context.save()
        } catch {
            TopNoteLogger.cardMutation.error("Up Next save failed: \(error.localizedDescription)")
        }
        TopNoteShared.reloadWidgets()
        refresh()
    }

    private func refresh() {
        now = Date()
        let all = (try? context.fetch(FetchDescriptor<Card>())) ?? []
        stats = ActivityStats(cards: all, now: now)
    }

    private func handleTipAction(_ id: String) {
        switch id {
        case WidgetTip.showMeHow: router.sheet = .widgetGuide
        case TodoRemindersTip.connect: router.open(.settings("reminders"))
        case SiriTip.showShortcuts: router.sheet = .shortcutsGuide
        default: break
        }
    }
}

/// Everything an Up Next action can change, so Undo can put it back.
struct CardUndoSnapshot {
    let content: String
    let isArchived: Bool
    let isComplete: Bool
    let nextTimeInQueue: Date
    let repeatInterval: Int
    let skipCount: Int
    let ratingData: Data?
    let completeData: Data?
    let removalData: Data?
    let skipData: Data?

    init(_ card: Card) {
        content = card.content
        isArchived = card.isArchived
        isComplete = card.isComplete
        nextTimeInQueue = card.nextTimeInQueue
        repeatInterval = card.repeatInterval
        skipCount = card.skipCount
        ratingData = card.ratingData
        completeData = card.completeData
        removalData = card.removalData
        skipData = card.skipData
    }

    func restore(_ card: Card) {
        card.content = content
        card.isArchived = isArchived
        card.isComplete = isComplete
        card.nextTimeInQueue = nextTimeInQueue
        card.repeatInterval = repeatInterval
        card.skipCount = skipCount
        card.ratingData = ratingData
        card.completes = (try? completeData.map { try JSONDecoder().decode([Date].self, from: $0) }) ?? []
        card.removals = (try? removalData.map { try JSONDecoder().decode([Date].self, from: $0) }) ?? []
        card.skips = (try? skipData.map { try JSONDecoder().decode([Date].self, from: $0) }) ?? []
        card.answerRevealed = false
    }
}

enum CardAction: Equatable {
    case rate(RatingType)
    case complete
    case next
    case skip
    case archive
    case addThought(String)
}

// MARK: - Pieces

struct TypeFilterChip: View {
    let title: String
    let systemImage: String
    let count: Int
    let tint: Color
    let isOn: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: systemImage)
                Text(title)
                if count > 0 {
                    Text("\(count)")
                        .monospacedDigit()
                        .padding(.horizontal, 6)
                        .padding(.vertical, 1)
                        .background(isOn ? Color.white.opacity(0.25) : tint.opacity(0.15), in: Capsule())
                }
            }
            .font(.subheadline.weight(.semibold))
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .foregroundStyle(isOn ? Color.white : tint)
            .background(isOn ? tint : tint.opacity(0.1), in: Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(title), \(count) ready")
        .accessibilityAddTraits(isOn ? .isSelected : [])
    }
}

struct UndoToast: View {
    let message: String
    let undo: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            Text(message)
                .font(.subheadline.weight(.medium))
                .lineLimit(1)
            Button("Undo", action: undo)
                .font(.subheadline.weight(.bold))
                .accessibilityIdentifier("undoButton")
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
        .background(.regularMaterial, in: Capsule())
        .shadow(color: .black.opacity(0.12), radius: 12, y: 4)
    }
}

/// The few cards waiting behind the current one.
struct ThenList: View {
    let cards: [Card]
    let remaining: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Then")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
            VStack(spacing: 0) {
                ForEach(cards) { card in
                    HStack(spacing: 12) {
                        Image(systemName: card.cardType.systemImage)
                            .foregroundStyle(card.cardType.tintColor)
                            .frame(width: 22)
                        Text(String(NoteText.attributed(card.content.firstLine).characters))
                            .lineLimit(1)
                            .font(card.cardType == .note ? .system(.body, design: .serif) : .body)
                        Spacer(minLength: 0)
                        if card.priority == .high {
                            Image(systemName: "flag.fill").foregroundStyle(.orange).font(.caption)
                        }
                    }
                    .padding(.vertical, 10)
                    .padding(.horizontal, 14)
                    if card.id != cards.last?.id { Divider().padding(.leading, 48) }
                }
            }
            .background(Theme.cardSurface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            if remaining > 0 {
                Text("and \(remaining) more")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

struct CaughtUpView: View {
    let filter: CardType?
    let nextCard: Card?
    let aheadCount: Int
    let now: Date
    let reviewAhead: () -> Void
    let capture: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 56))
                .foregroundStyle(.green.gradient)
                .padding(.top, 24)
            Text("You're all caught up")
                .font(.title2.weight(.bold))
            if let nextCard {
                Text("Next: a \(nextCard.cardType.rawValue.lowercased()) \(nextCard.nextTimeInQueue.formatted(.relative(presentation: .named)))")
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            VStack(spacing: 10) {
                if aheadCount > 0 {
                    Button(action: reviewAhead) {
                        Label("Review \(aheadCount) flashcard\(aheadCount == 1 ? "" : "s") ahead", systemImage: "rectangle.on.rectangle.angled")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(CardType.flashcard.tintColor)
                    .controlSize(.large)
                }
                Button(action: capture) {
                    Label("Capture something new", systemImage: "plus")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
            }
            .padding(.top, 8)
            Text("Flashcards are never overdue. Study whenever you like and each card stays on its own schedule.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .opacity(aheadCount > 0 ? 1 : 0)
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(Theme.cardSurface, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .accessibilityIdentifier("caughtUp")
    }
}

struct EmptyLibraryView: View {
    let addTip: AddFirstCardTip
    let capture: (CardType) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Start with one thing")
                .font(.title2.weight(.bold))
            Text("Top Note shows you one card at a time: here, on your Home Screen and with Siri. Pick what to capture first.")
                .foregroundStyle(.secondary)
            TipView(addTip)
            ForEach([CardType.note, .flashcard, .todo]) { type in
                Button { capture(type) } label: {
                    HStack(spacing: 14) {
                        Image(systemName: type.filledSymbol)
                            .font(.title2)
                            .foregroundStyle(type.tintColor)
                            .frame(width: 36)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("New \(type.rawValue)").font(.headline)
                            Text(type.purpose).font(.subheadline).foregroundStyle(.secondary)
                        }
                        Spacer(minLength: 0)
                        Image(systemName: "chevron.right").foregroundStyle(.tertiary)
                    }
                    .padding(16)
                    .background(Theme.cardSurface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("emptyCapture-\(type.routeName)")
            }
        }
    }
}

extension String {
    /// The first non-empty line, for one-line previews.
    var firstLine: String {
        split(whereSeparator: \.isNewline).first.map(String.init)?.trimmingCharacters(in: .whitespaces) ?? self
    }
}
