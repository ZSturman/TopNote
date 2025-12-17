//
//  TopNoteWidgetEntryView.swift
//  TopNote
//
//  Created by Zachary Sturman on 12/13/25.
//

import SwiftUI
import WidgetKit

struct TopNoteWidgetEntryView: View {
    var entry: CardEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        Group {
            if family == .systemSmall {
                SmallWidgetSummaryView(
                    queueCount: entry.queueCardCount,
                    topCardDate: entry.card.nextTimeInQueue,
                    currentDate: entry.date,
                    selectedCardTypes: entry.selectedCardTypes,
                    selectedFolders: entry.selectedFolders
                )
            } else {
                GeometryReader { geometry in
                    ZStack {
                        backgroundColor()

                        VStack(spacing: 6) {
                            if isNoCardTypesSelected {
                                VStack {
                                    Image(systemName: "slider.horizontal.3")
                                        .font(.largeTitle)
                                        .foregroundColor(.gray)
                                    Text("No card types selected.")
                                        .font(.caption)
                                        .multilineTextAlignment(.center)
                                        .padding(.top, 4)
                                    Text("Tap and edit this widget to choose what to display!")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .multilineTextAlignment(.center)
                                        .padding(.top, 2)
                                }
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                            } else if entry.queueCardCount == 0 {
                                VStack {
                                    HStack {
                                        ForEach(entry.selectedCardTypes, id: \.self) { type in
                                            Image(systemName: type.systemImage)
                                                .imageScale(.medium)
                                                .foregroundColor(.secondary)
                                                .accessibilityLabel(Text(type.rawValue))
                                        }
                                    }
                                    AllCaughtUpWidgetView(
                                        selectedCardTypes: entry.selectedCardTypes,
                                        selectedFolders: entry.selectedFolders,
                                        nextCardDate: entry.nextCardForQueue?.nextTimeInQueue
                                    )
                                }
                                .padding()
                                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                            } else {
                                ZStack(alignment: .top) {

                                    headerRow
//                                        .opacity(hideText ? 0 : 1)
//                                        .accessibilityHidden(hideText)
                                        .padding(.horizontal, 14)
                                        .padding(.top, 10)
                                }
                                .frame(height: 28, alignment: .top)

                                cardContentView(for: entry.card, widgetID: entry.widgetIdentifier)
                                    .frame(maxWidth: .infinity, alignment: .topLeading)
                                    .padding(.horizontal, 14)
                                    .padding(.top, 2)
                                    .animation(.easeInOut(duration: 0.3), value: entry.card.answerRevealed)

                                Spacer(minLength: 0)

                                cardButtonsView(for: entry.card, widgetID: entry.widgetIdentifier)
                                    .padding(.horizontal, 10)
                                    .padding(.bottom, 6)
                            }
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
                .containerBackground(.clear, for: .widget)
                .widgetURL(URL(string: "topnote://card/\(entry.card.id.uuidString)"))
            }
        }
        .onAppear {
            let shared = UserDefaults(suiteName: "group.com.zacharysturman.topnote")
            shared?.set(true, forKey: "hasWidget")
        }
    }

    // MARK: Header

    private var headerRow: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                combinedFoldersTagsView
            }
            .font(.caption)
            .lineLimit(1)
            .truncationMode(.tail)

            Spacer()

            countBadge(count: entry.queueCardCount)
        }
        .font(.caption2)
    }

    private var combinedFoldersTagsView: some View {
        let tags = entry.card.tags
        let folder = entry.card.folder

        return HStack(spacing: 8) {
            if let folder {
                HStack(spacing: 2) {
                    Image(systemName: "folder")
                        .imageScale(.small)
                    Text(folder.name)
                        .font(.caption2)
                        .minimumScaleFactor(0.7)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
                .foregroundColor(.secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .accessibilityLabel(Text(folder.name))
            }

            if let tags, !tags.isEmpty {
                HStack(spacing: 2) {
                    Image(systemName: "tag")
                        .imageScale(.small)
                    Text(tags.joined(separator: ", "))
                        .font(.caption2)
                        .minimumScaleFactor(0.7)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
                .foregroundColor(.secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .accessibilityLabel(Text("Tags: \(tags.joined(separator: ", "))"))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func countBadge(count: Int) -> some View {

        return HStack(spacing: 4) {
            ForEach(entry.selectedCardTypes, id: \.self) { type in
                Image(systemName: type.systemImage)
                    .font(.caption2)
                    .minimumScaleFactor(0.7)
                    .imageScale(.medium)
                    .accessibilityLabel(Text(type.rawValue))
            }

            Text("\(count)")
                .font(.caption2).bold()
                .minimumScaleFactor(0.7)
                .foregroundColor( .secondary)
                .monospacedDigit()
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text("Items: \(count)"))
    }

    private var isNoCardTypesSelected: Bool {
        entry.selectedCardTypes.isEmpty
    }

    private func backgroundColor() -> Color {
        entry.card.cardType.tintColor.opacity(0.10)
    }

    private func isEmptyText(_ text: String?) -> Bool {
        (text ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }



    @ViewBuilder
    private func cardButtonsView(for card: CardEntity, widgetID: String) -> some View {
        let isFlipped = card.cardType == .flashcard &&
            WidgetStateManager.shared.isFlipped(widgetID: widgetID, cardID: card.id)

        switch card.cardType {
        case .flashcard:
            FlashcardButtonGroup(
                isCardFlipped: isFlipped,
                skipCount: card.skipCount,
                skipEnabled: card.skipEnabled,
                card: card,
                widgetID: widgetID,
            )
        case .todo:
            TodoCardButtonGroup(
                skipEnabled: card.skipEnabled,
                card: card,
                widgetID: widgetID,
            )
        case .note:
            NoteCardButtonGroup(
                skipEnabled: card.skipEnabled,
                card: card,
                widgetID: widgetID,
            )
        }
    }


    @ViewBuilder
    private func cardContentView(for card: CardEntity, widgetID: String) -> some View {
        let isFlipped = card.cardType == .flashcard &&
            WidgetStateManager.shared.isFlipped(widgetID: widgetID, cardID: card.id)

        switch card.cardType {
        case .flashcard:
            if isFlipped {
                let isLargeWidget = family == .systemLarge || family == .systemExtraLarge
                let contentHeight: CGFloat = isLargeWidget ? 50 : 28

                VStack(spacing: isLargeWidget ? 4 : 2) {
                    HStack(alignment: .top, spacing: 6) {
                        if !isEmptyText(card.content) {
                            Text(card.content)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                                .lineLimit(isLargeWidget ? 2 : 1)
                                .minimumScaleFactor(0.6)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .frame(height: contentHeight)

                    VStack(alignment: .leading, spacing: 2) {
                        if let answer = card.answer, !isEmptyText(answer) {
                            Text(answer)
                                .font(isLargeWidget ? .title3 : .subheadline)
                                .fontWeight(.regular)
                                .foregroundColor(.primary)
                                .lineLimit(isLargeWidget ? 15 : 6)
                                .minimumScaleFactor(0.5)
                                .fixedSize(horizontal: false, vertical: false)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
                .padding(0)
            } else {
                if !isEmptyText(card.content) {
                    Text(card.content)
                        .font(family == .systemLarge || family == .systemExtraLarge ? .title3 : .subheadline)
                        .fontWeight(.regular)
                        .foregroundColor(.primary)
                        .lineLimit(family == .systemLarge || family == .systemExtraLarge ? 12 : 5)
                        .minimumScaleFactor(0.5)
                        .fixedSize(horizontal: false, vertical: false)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        case .todo, .note:
            if !isEmptyText(card.content) {
                Text(card.content)
                    .font(family == .systemLarge || family == .systemExtraLarge ? .title3 : .subheadline)
                    .fontWeight(.regular)
                    .foregroundColor(.primary)
                    .lineLimit(family == .systemLarge || family == .systemExtraLarge ? 12 : 5)
                    .minimumScaleFactor(0.5)
                    .fixedSize(horizontal: false, vertical: false)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}

