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
                        widgetBackgroundView(for: entry.card, widgetID: entry.widgetIdentifier)
                            .frame(width: geometry.size.width, height: geometry.size.height)
                            .clipped()

                        let hideText = effectiveTextHidden(for: entry.card, widgetID: entry.widgetIdentifier)

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
                                        .opacity(hideText ? 0 : 1)
                                        .accessibilityHidden(hideText)
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
            let shared = UserDefaults(suiteName: "group.com.zacharysturman.TopNote")
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
        let hasImage = hasBackgroundImage(for: entry.card)

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
                .foregroundColor(hasImage ? .white : .secondary)
                .shadow(color: hasImage ? .black.opacity(0.7) : .clear, radius: 2, x: 0, y: 1)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(hasImage ? Color.black.opacity(0.3) : Color.clear)
                .clipShape(Capsule())
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
                .foregroundColor(hasImage ? .white : .secondary)
                .shadow(color: hasImage ? .black.opacity(0.7) : .clear, radius: 2, x: 0, y: 1)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(hasImage ? Color.black.opacity(0.3) : Color.clear)
                .clipShape(Capsule())
                .accessibilityLabel(Text("Tags: \(tags.joined(separator: ", "))"))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func countBadge(count: Int) -> some View {
        let hasImage = hasBackgroundImage(for: entry.card)

        return HStack(spacing: 4) {
            ForEach(entry.selectedCardTypes, id: \.self) { type in
                Image(systemName: type.systemImage)
                    .font(.caption2)
                    .minimumScaleFactor(0.7)
                    .imageScale(.medium)
                    .foregroundColor(hasImage ? .white : .accentColor)
                    .shadow(color: hasImage ? .black.opacity(0.7) : .clear, radius: 2, x: 0, y: 1)
                    .accessibilityLabel(Text(type.rawValue))
            }

            Text("\(count)")
                .font(.caption2).bold()
                .minimumScaleFactor(0.7)
                .foregroundColor(hasImage ? .white : .secondary)
                .shadow(color: hasImage ? .black.opacity(0.7) : .clear, radius: 2, x: 0, y: 1)
                .monospacedDigit()
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(hasImage ? Color.black.opacity(0.3) : Color.clear)
        .clipShape(Capsule())
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

    private func shouldShowTextToggle(for card: CardEntity) -> Bool {
        switch card.cardType {
        case .flashcard:
            if card.answerRevealed {
                let hasAnswerImage = card.answerImageData != nil
                let hasAnyText = !isEmptyText(card.content) || !isEmptyText(card.answer)
                return hasAnswerImage && hasAnyText
            } else {
                let hasContentImage = card.contentImageData != nil
                let hasContentText = !isEmptyText(card.content)
                return hasContentImage && hasContentText
            }
        case .todo, .note:
            let hasContentImage = card.contentImageData != nil
            let hasContentText = !isEmptyText(card.content)
            return hasContentImage && hasContentText
        }
    }

    private func effectiveTextHidden(for card: CardEntity, widgetID: String) -> Bool {
        if shouldShowTextToggle(for: card) {
            return WidgetStateManager.shared.isTextHidden(widgetID: widgetID, cardID: card.id)
        }
        return false
    }

    @ViewBuilder
    private func widgetBackgroundView(for card: CardEntity, widgetID: String) -> some View {
        let isFlipped = card.cardType == .flashcard &&
            WidgetStateManager.shared.isFlipped(widgetID: widgetID, cardID: card.id)

        if card.cardType == .flashcard, isFlipped {
            if let data = card.answerImageData, let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
            } else {
                backgroundColor()
            }
        } else {
            if let data = card.contentImageData, let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
            } else {
                backgroundColor()
            }
        }
    }

    @ViewBuilder
    private func cardButtonsView(for card: CardEntity, widgetID: String) -> some View {
        let showTextToggle = shouldShowTextToggle(for: card)
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
                showTextToggle: showTextToggle
            )
        case .todo:
            TodoCardButtonGroup(
                skipEnabled: card.skipEnabled,
                card: card,
                widgetID: widgetID,
                showTextToggle: showTextToggle
            )
        case .note:
            NoteCardButtonGroup(
                skipEnabled: card.skipEnabled,
                card: card,
                widgetID: widgetID,
                showTextToggle: showTextToggle
            )
        }
    }

    private func hasBackgroundImage(for card: CardEntity, isFlipped: Bool = false) -> Bool {
        if card.cardType == .flashcard && isFlipped {
            return card.answerImageData != nil
        } else {
            return card.contentImageData != nil
        }
    }

    @ViewBuilder
    private func cardContentView(for card: CardEntity, widgetID: String) -> some View {
        let hideText = effectiveTextHidden(for: card, widgetID: widgetID)
        let isFlipped = card.cardType == .flashcard &&
            WidgetStateManager.shared.isFlipped(widgetID: widgetID, cardID: card.id)
        let hasImage = hasBackgroundImage(for: card, isFlipped: isFlipped)

        switch card.cardType {
        case .flashcard:
            if isFlipped {
                let isLargeWidget = family == .systemLarge || family == .systemExtraLarge
                let contentHeight: CGFloat = isLargeWidget ? 50 : 28

                VStack(spacing: isLargeWidget ? 4 : 2) {
                    HStack(alignment: .top, spacing: 6) {
                        if !hideText, !isEmptyText(card.content) {
                            Text(card.content)
                                .font(.caption2)
                                .foregroundColor(hasImage ? .white : .secondary)
                                .lineLimit(isLargeWidget ? 2 : 1)
                                .minimumScaleFactor(0.6)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .shadow(color: hasImage ? .black.opacity(0.8) : .clear, radius: 3, x: 0, y: 1)
                                .shadow(color: hasImage ? .black.opacity(0.5) : .clear, radius: 1, x: 0, y: 0)
                        }
                    }
                    .frame(height: contentHeight)

                    VStack(alignment: .leading, spacing: 2) {
                        if !hideText, let answer = card.answer, !isEmptyText(answer) {
                            Text(answer)
                                .font(isLargeWidget ? .title3 : .subheadline)
                                .fontWeight(hasImage ? .medium : .regular)
                                .foregroundColor(hasImage ? .white : .primary)
                                .lineLimit(isLargeWidget ? 15 : 6)
                                .minimumScaleFactor(0.5)
                                .fixedSize(horizontal: false, vertical: false)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .shadow(color: hasImage ? .black.opacity(0.8) : .clear, radius: 3, x: 0, y: 1)
                                .shadow(color: hasImage ? .black.opacity(0.5) : .clear, radius: 1, x: 0, y: 0)
                        }
                    }
                    .frame(maxHeight: .infinity, alignment: .top)
                }
                .padding(hasImage ? 8 : 0)
                .background(hasImage && !hideText ? Color.black.opacity(0.45) : nil)
                .cornerRadius(8)
            } else {
                if !hideText, !isEmptyText(card.content) {
                    Text(card.content)
                        .font(family == .systemLarge || family == .systemExtraLarge ? .title3 : .subheadline)
                        .fontWeight(hasImage ? .medium : .regular)
                        .foregroundColor(hasImage ? .white : .primary)
                        .lineLimit(family == .systemLarge || family == .systemExtraLarge ? 12 : 5)
                        .minimumScaleFactor(0.5)
                        .fixedSize(horizontal: false, vertical: false)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .shadow(color: hasImage ? .black.opacity(0.8) : .clear, radius: 3, x: 0, y: 1)
                        .shadow(color: hasImage ? .black.opacity(0.5) : .clear, radius: 1, x: 0, y: 0)
                        .padding(hasImage ? 8 : 0)
                        .background(hasImage ? Color.black.opacity(0.45) : nil)
                        .cornerRadius(8)
                }
            }
        case .todo, .note:
            if !hideText, !isEmptyText(card.content) {
                Text(card.content)
                    .font(family == .systemLarge || family == .systemExtraLarge ? .title3 : .subheadline)
                    .fontWeight(hasImage ? .medium : .regular)
                    .foregroundColor(hasImage ? .white : .primary)
                    .lineLimit(family == .systemLarge || family == .systemExtraLarge ? 12 : 5)
                    .minimumScaleFactor(0.5)
                    .fixedSize(horizontal: false, vertical: false)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .shadow(color: hasImage ? .black.opacity(0.8) : .clear, radius: 3, x: 0, y: 1)
                    .shadow(color: hasImage ? .black.opacity(0.5) : .clear, radius: 1, x: 0, y: 0)
                    .padding(hasImage ? 8 : 0)
                    .background(hasImage ? Color.black.opacity(0.45) : nil)
                    .cornerRadius(8)
            }
        }
    }
}
