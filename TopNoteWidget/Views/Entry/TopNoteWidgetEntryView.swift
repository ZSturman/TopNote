//
//  TopNoteWidgetEntryView.swift
//  TopNoteWidget
//
//  The next card, with the same actions as Up Next in the app.
//

import SwiftUI
import WidgetKit

struct TopNoteWidgetEntryView: View {
    var entry: CardEntry
    @Environment(\.widgetFamily) private var family

    private var isLarge: Bool { family == .systemLarge || family == .systemExtraLarge }
    private var card: CardEntity { entry.card }
    private var isFlipped: Bool {
        card.cardType == .flashcard && WidgetStateManager.shared.isFlipped(widgetID: entry.widgetIdentifier, cardID: card.id)
    }

    var body: some View {
        Group {
            if entry.selectedCardTypes.isEmpty {
                message(symbol: "slider.horizontal.3", title: "Nothing selected", detail: "Touch and hold, then Edit Widget to choose what to show.")
            } else if entry.queueCardCount == 0 && entry.card.content == "Unable to load cards." {
                message(symbol: "exclamationmark.triangle", title: "Couldn't load cards", detail: "Open Top Note to refresh.")
            } else if entry.queueCardCount == 0 {
                caughtUp
            } else if family == .systemSmall {
                SmallWidgetSummaryView(entry: entry)
            } else {
                cardView
            }
        }
        .containerBackground(for: .widget) {
            if entry.queueCardCount > 0 && !entry.selectedCardTypes.isEmpty {
                Rectangle().fill(WidgetPalette.background(for: card.cardType))
            } else {
                Color(uiColor: .secondarySystemBackground)
            }
        }
        .widgetURL(entry.queueCardCount > 0 ? TopNoteRoute.card(card.id).url : TopNoteRoute.upNext(nil).url)
    }

    // MARK: - Card

    private var cardView: some View {
        VStack(alignment: .leading, spacing: isLarge ? 12 : 8) {
            header
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            buttons
        }
        .padding(isLarge ? 18 : 14)
    }

    private var header: some View {
        HStack(spacing: 5) {
            Image(systemName: card.cardType.systemImage)
                .foregroundStyle(card.cardType.tintColor)
            Text(headerTitle)
                .font(.caption2.weight(.bold))
                .foregroundStyle(.secondary)
                .lineLimit(1)
            Spacer(minLength: 4)
            Text("\(entry.queueCardCount) ready")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
                .monospacedDigit()
        }
        .font(.caption)
    }

    private var headerTitle: String {
        let kind = card.cardType == .flashcard && isFlipped ? "ANSWER" : card.cardType.rawValue.uppercased()
        if let folder = card.folder?.name, !folder.isEmpty { return "\(kind) · \(folder.uppercased())" }
        return kind
    }

    @ViewBuilder
    private var content: some View {
        switch card.cardType {
        case .flashcard:
            if isFlipped {
                VStack(alignment: .leading, spacing: 4) {
                    Text(card.content)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(isLarge ? 2 : 1)
                    Text(card.answer ?? "")
                        .font(WidgetPalette.font(for: .flashcard, large: isLarge))
                        .lineLimit(isLarge ? 10 : 3)
                        .minimumScaleFactor(0.6)
                }
            } else {
                Text(card.content)
                    .font(WidgetPalette.font(for: .flashcard, large: isLarge))
                    .lineLimit(isLarge ? 10 : 4)
                    .minimumScaleFactor(0.6)
            }
        case .todo:
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Image(systemName: "circle")
                    .foregroundStyle(CardType.todo.tintColor)
                Text(card.content)
                    .font(WidgetPalette.font(for: .todo, large: isLarge))
                    .lineLimit(isLarge ? 10 : 4)
                    .minimumScaleFactor(0.6)
            }
        case .note:
            Text(plainNote(card.content))
                .font(WidgetPalette.font(for: .note, large: isLarge))
                .foregroundStyle(WidgetPalette.ink)
                .lineSpacing(2)
                .lineLimit(isLarge ? 12 : 4)
                .minimumScaleFactor(0.6)
        }
    }

    @ViewBuilder
    private var buttons: some View {
        switch card.cardType {
        case .flashcard:
            FlashcardButtonGroup(isCardFlipped: isFlipped, skipCount: card.skipCount, skipEnabled: card.skipEnabled, card: card, widgetID: entry.widgetIdentifier)
        case .todo:
            TodoCardButtonGroup(skipEnabled: card.skipEnabled, card: card, widgetID: entry.widgetIdentifier)
        case .note:
            NoteCardButtonGroup(skipEnabled: card.skipEnabled, card: card, widgetID: entry.widgetIdentifier)
        }
    }

    /// Widgets show notes as plain text; Markdown markers are removed.
    private func plainNote(_ text: String) -> AttributedString {
        (try? AttributedString(markdown: text, options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace))) ?? AttributedString(text)
    }

    // MARK: - Empty states

    private var caughtUp: some View {
        VStack(spacing: 6) {
            Image(systemName: "checkmark.seal.fill")
                .font(family == .systemSmall ? .title2 : .largeTitle)
                .foregroundStyle(.green)
            Text("All caught up")
                .font(.headline)
            if let next = entry.nextCardForQueue?.nextTimeInQueue {
                Text("Next \(next, style: .relative)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    private func message(symbol: String, title: String, detail: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: symbol).font(.title2).foregroundStyle(.secondary)
            Text(title).font(.headline)
            Text(detail).font(.caption).foregroundStyle(.secondary).multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}
