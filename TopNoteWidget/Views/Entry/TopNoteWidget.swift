//
//  TopNoteWidget.swift
//  TopNote
//
//  Created by Zachary Sturman on 12/13/25.
//

import WidgetKit
import SwiftUI
import AppIntents

struct TopNoteWidget: Widget {
    let kind: String = "Top Note Widget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: ConfigurationAppIntent.self,
            provider: Provider()
        ) { entry in
            TopNoteWidgetEntryView(entry: entry)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Top Note Widget")
        .description("Displays a card from your collection.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge, .systemExtraLarge])
        .contentMarginsDisabled()
    }
}


////
////  TopNoteWidget.swift
////  TopNote
////
////  Created by Zachary Sturman on 2/17/25.
////
//
//import WidgetKit
//import SwiftUI
//import SwiftData
//import AppIntents
//import UIKit
//
//struct CardEntity: AppEntity {
//    var id: UUID
//    var createdAt: Date
//    var cardTypeRaw: String
//    var content: String
//    var answer: String?
//    var isRecurring: Bool
//    var skipCount: Int
//    var seenCount: Int
//    var repeatInterval: Int
//    var nextTimeInQueue: Date
//    var folder: Folder?
//    var isArchived: Bool
//    var answerRevealed: Bool
//    var skipEnabled: Bool
//    var tags: [String]?
//    var widgetTextHidden: Bool
//    // Image data for widget display (compressed thumbnails)
//    var contentImageData: Data?
//    var answerImageData: Data?
//
//    var cardType: CardType {
//        CardType(rawValue: cardTypeRaw) ?? .note
//    }
//
//    static var defaultQuery = CardEntityQuery()
//
//    static var typeDisplayRepresentation: TypeDisplayRepresentation {
//        TypeDisplayRepresentation(name: LocalizedStringResource("Cards", table: "AppIntents"))
//    }
//
//    var displayRepresentation: DisplayRepresentation {
//        let displayText = content
//        return DisplayRepresentation(stringLiteral: displayText)
//    }
//}
//
//struct CardEntry: TimelineEntry {
//    let date: Date            // This represents when the entry was generated ("Last updated")
//    let card: CardEntity
//    let queueCardCount: Int
//    let totalNumberOfCards: Int
//    let nextCardForQueue: CardEntity?
//    let nextUpdateDate: Date  // New field to show the next update time
//
//    let selectedCardTypes: [CardType]
//    let selectedFolders: [Folder]
//
//    // Widget-instance state tracking
//    let widgetIdentifier: String
//}
//
//// MARK: - Widget State Manager
//class WidgetStateManager {
//    static let shared = WidgetStateManager()
//    private let defaults = UserDefaults(suiteName: "group.com.zacharysturman.TopNote")
//
//    private func textHiddenKey(for widgetID: String, cardID: UUID) -> String {
//        "widget_\(widgetID)_card_\(cardID.uuidString)_textHidden"
//    }
//
//    private func flipStateKey(for widgetID: String, cardID: UUID) -> String {
//        "widget_\(widgetID)_card_\(cardID.uuidString)_flipped"
//    }
//
//    private func lastCardIDKey(for widgetID: String) -> String {
//        "widget_\(widgetID)_lastCardID"
//    }
//
//    private func flipTimestampKey(for widgetID: String, cardID: UUID) -> String {
//        "widget_\(widgetID)_card_\(cardID.uuidString)_flipTimestamp"
//    }
//
//    func isTextHidden(widgetID: String, cardID: UUID) -> Bool {
//        defaults?.bool(forKey: textHiddenKey(for: widgetID, cardID: cardID)) ?? false
//    }
//
//    func setTextHidden(_ hidden: Bool, widgetID: String, cardID: UUID) {
//        defaults?.set(hidden, forKey: textHiddenKey(for: widgetID, cardID: cardID))
//    }
//
//    func isFlipped(widgetID: String, cardID: UUID) -> Bool {
//        defaults?.bool(forKey: flipStateKey(for: widgetID, cardID: cardID)) ?? false
//    }
//
//    func setFlipped(_ flipped: Bool, widgetID: String, cardID: UUID) {
//        defaults?.set(flipped, forKey: flipStateKey(for: widgetID, cardID: cardID))
//        if flipped {
//            // Record the time when flipped
//            defaults?.set(Date().timeIntervalSince1970, forKey: flipTimestampKey(for: widgetID, cardID: cardID))
//        } else {
//            // Clear timestamp when unflipped
//            defaults?.removeObject(forKey: flipTimestampKey(for: widgetID, cardID: cardID))
//        }
//    }
//
//    func getLastCardID(widgetID: String) -> UUID? {
//        guard let uuidString = defaults?.string(forKey: lastCardIDKey(for: widgetID)) else { return nil }
//        return UUID(uuidString: uuidString)
//    }
//
//    func setLastCardID(_ cardID: UUID, widgetID: String) {
//        defaults?.set(cardID.uuidString, forKey: lastCardIDKey(for: widgetID))
//    }
//
//    func shouldResetFlipState(widgetID: String, cardID: UUID) -> Bool {
//        // Check if card has been flipped for more than 5 minutes
//        guard let timestamp = defaults?.double(forKey: flipTimestampKey(for: widgetID, cardID: cardID)) else {
//            return false
//        }
//        let flipDate = Date(timeIntervalSince1970: timestamp)
//        let elapsed = Date().timeIntervalSince(flipDate)
//        // Reset if flipped for more than 5 minutes (300 seconds)
//        return elapsed > 300
//    }
//
//    func checkAndResetIfNeeded(widgetID: String, currentCardID: UUID) {
//        // Check if the card has changed
//        let lastCardID = getLastCardID(widgetID: widgetID)
//
//        if let lastCardID = lastCardID, lastCardID != currentCardID {
//            // Card changed, reset the flip state of the old card
//            setFlipped(false, widgetID: widgetID, cardID: lastCardID)
//            // Also reset text hidden state for new card (text should be visible by default)
//            setTextHidden(false, widgetID: widgetID, cardID: currentCardID)
//            setFlipped(false, widgetID: widgetID, cardID: currentCardID)
//        } else if lastCardID == nil {
//            // First time seeing this widget, initialize states
//            setTextHidden(false, widgetID: widgetID, cardID: currentCardID)
//            setFlipped(false, widgetID: widgetID, cardID: currentCardID)
//        } else if shouldResetFlipState(widgetID: widgetID, cardID: currentCardID) {
//            // Same card but flipped for too long, reset it
//            setFlipped(false, widgetID: widgetID, cardID: currentCardID)
//        }
//
//        // Update the last card ID
//        setLastCardID(currentCardID, widgetID: widgetID)
//    }
//}
//
//
//struct Provider: AppIntentTimelineProvider {
//    func placeholder(in context: Context) -> CardEntry {
//        placeholderCardEntry(widgetIdentifier: "placeholder")
//    }
//
//    func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> CardEntry {
//        sampleCardEntry(widgetIdentifier: "snapshot")
//    }
//
//
//    func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<CardEntry> {
//        let currentDate = Date()
//
//        // Generate a unique identifier for this widget instance based on context
//        // Use a combination of display size and a hash to create a stable identifier per widget instance
//        let widgetIdentifier = "\(context.family.rawValue)_\(abs(context.displaySize.width.hashValue ^ context.displaySize.height.hashValue))"
//
//        let widgetImageMaxSize: CGFloat = {
//            switch context.family {
//            case .systemSmall:
//                return 300
//            case .systemMedium:
//                return 600
//            case .systemLarge:
//                return 900
//            case .systemExtraLarge:
//                return 1100
//            case .accessoryCircular, .accessoryRectangular, .accessoryInline, .accessoryCorner:
//                return 300
//            @unknown default:
//                return 600
//            }
//        }()
//
//        if configuration.showCardType.isEmpty {
//            let entry = noCardTypesSelectedEntry(currentDate: currentDate,
//                                                 selectedCardTypes: configuration.showCardType,
//                                                 selectedFolders: configuration.showFolders,
//                                                 widgetIdentifier: widgetIdentifier)
//            return Timeline(entries: [entry], policy: .never)
//        }
//
//        guard let container = try? ModelContainer(for: Card.self) else {
//            return Timeline(entries: [], policy: .never)
//        }
//        let modelContext = ModelContext(container)
//        let queueManager = QueueManager(context: modelContext)
//
//        do {
//            let (cardsInQueue, nextCardForQueue, totalNumberOfCards) = try queueManager.fetchQueueCardsAndSummary(currentDate: currentDate, configuration: configuration)
//
//            // Convert all Cards to CardEntity
//            let cardsInQueueEntities: [CardEntity] = cardsInQueue.map { card in
//                // Optimize images for widget display (thumbnail + compression)
//                let contentImageForWidget: Data? = {
//                    guard let imageData = card.contentImageData,
//                          let image = UIImage(data: imageData) else { return nil }
//                        let thumbnail = image.widgetThumbnail(maxSize: widgetImageMaxSize)
//                        return thumbnail.jpegData(compressionQuality: 0.75)
//                }()
//                let answerImageForWidget: Data? = {
//                    guard let imageData = card.answerImageData,
//                          let image = UIImage(data: imageData) else { return nil }
//                        let thumbnail = image.widgetThumbnail(maxSize: widgetImageMaxSize)
//                        return thumbnail.jpegData(compressionQuality: 0.75)
//                }()
//
//                return CardEntity(id: card.id,
//                           createdAt: card.createdAt,
//                           cardTypeRaw: card.cardType.rawValue,
//                           content: card.displayContent,
//                           answer: card.displayAnswer,
//                           isRecurring: card.isRecurring,
//                           skipCount: card.skipCount,
//                           seenCount: card.seenCount,
//                           repeatInterval: card.repeatInterval,
//                           nextTimeInQueue: card.nextTimeInQueue,
//                           folder: card.folder,
//                           isArchived: card.isArchived,
//                           answerRevealed: card.answerRevealed,
//                           skipEnabled: card.skipEnabled,
//                           tags: card.unwrappedTags.map(\.name),
//                           widgetTextHidden: card.widgetTextHidden,
//                           contentImageData: contentImageForWidget,
//                           answerImageData: answerImageForWidget)
//            }
//
//            let nextCardEntity: CardEntity? = nextCardForQueue.map { card in
//                // Optimize images for widget display (thumbnail + compression)
//                let contentImageForWidget: Data? = {
//                    guard let imageData = card.contentImageData,
//                          let image = UIImage(data: imageData) else { return nil }
//                        let thumbnail = image.widgetThumbnail(maxSize: widgetImageMaxSize)
//                        return thumbnail.jpegData(compressionQuality: 0.75)
//                }()
//                let answerImageForWidget: Data? = {
//                    guard let imageData = card.answerImageData,
//                          let image = UIImage(data: imageData) else { return nil }
//                        let thumbnail = image.widgetThumbnail(maxSize: widgetImageMaxSize)
//                        return thumbnail.jpegData(compressionQuality: 0.75)
//                }()
//
//                return CardEntity(id: card.id,
//
//                           createdAt: card.createdAt,
//                           cardTypeRaw: card.cardType.rawValue,
//                           content: card.displayContent,
//                           answer: card.displayAnswer,
//                           isRecurring: card.isRecurring,
//                           skipCount: card.skipCount,
//                           seenCount: card.seenCount,
//                           repeatInterval: card.repeatInterval,
//                           nextTimeInQueue: card.nextTimeInQueue,
//                           folder: card.folder,
//                           isArchived: card.isArchived,
//                           answerRevealed: card.answerRevealed,
//                           skipEnabled: card.skipEnabled,
//                           tags: card.unwrappedTags.map(\.name),
//                           widgetTextHidden: card.widgetTextHidden,
//                           contentImageData: contentImageForWidget,
//                           answerImageData: answerImageForWidget)
//            }
//
//            let updateDate = nextCardEntity?.nextTimeInQueue ?? currentDate.addingTimeInterval(60)
//
//
//            if cardsInQueueEntities.isEmpty {
//                let entry = allCaughtUpCardEntry(currentDate: currentDate,
//                                                 totalNumberOfCards: totalNumberOfCards,
//                                                 nextCardForQueue: nextCardEntity,
//                                                 configuredTypes: configuration.showCardType,
//                                                 selectedCardTypes: configuration.showCardType,
//                                                 selectedFolders: configuration.showFolders,
//                                                 widgetIdentifier: widgetIdentifier)
//                return Timeline(entries: [entry], policy: .after(updateDate))
//            }
//
//            // Check and reset widget state if needed for the top card
//            let topCard = cardsInQueueEntities.first!
//            WidgetStateManager.shared.checkAndResetIfNeeded(widgetID: widgetIdentifier, currentCardID: topCard.id)
//
//            let entry = CardEntry(
//                date: currentDate,
//                card: topCard,
//                queueCardCount: cardsInQueueEntities.count,
//                totalNumberOfCards: totalNumberOfCards,
//                nextCardForQueue: nextCardEntity,
//                nextUpdateDate: updateDate,
//                selectedCardTypes: configuration.showCardType,
//                selectedFolders: configuration.showFolders,
//                widgetIdentifier: widgetIdentifier
//            )
//            return Timeline(entries: [entry], policy:.after(Calendar.current.date(byAdding: .minute, value: 5, to: currentDate) ?? Date()))
//        } catch {
//            print("Error updating queue: \(error)")
//            let entry = errorCardEntry(widgetIdentifier: widgetIdentifier)
//            return Timeline(entries: [entry], policy: .never)
//        }
//    }
//}
//
//func noCardTypesSelectedEntry(currentDate: Date, selectedCardTypes: [CardType], selectedFolders: [Folder], widgetIdentifier: String) -> CardEntry {
//    let dummyCard = Card.makeDummy()
//    // Create CardEntity from dummyCard
//    let dummyCardEntity = CardEntity(
//        id: dummyCard.id,
//
//        createdAt: dummyCard.createdAt,
//        cardTypeRaw: dummyCard.cardType.rawValue,
//        content: dummyCard.content,
//        answer: dummyCard.answer,
//        isRecurring: dummyCard.isRecurring,
//        skipCount: dummyCard.skipCount,
//        seenCount: dummyCard.seenCount,
//        repeatInterval: dummyCard.repeatInterval,
//        nextTimeInQueue: dummyCard.nextTimeInQueue,
//        folder: dummyCard.folder,
//        isArchived: dummyCard.isArchived,
//        answerRevealed: dummyCard.answerRevealed,
//        skipEnabled: dummyCard.skipEnabled,
//        tags: nil,
//        widgetTextHidden: dummyCard.widgetTextHidden,
//        contentImageData: nil,
//        answerImageData: nil
//    )
//    return CardEntry(
//        date: currentDate,
//        card: dummyCardEntity,
//        queueCardCount: 0,
//        totalNumberOfCards: 0,
//        nextCardForQueue: nil,
//        nextUpdateDate: currentDate.addingTimeInterval(3600),
//        selectedCardTypes: selectedCardTypes,
//        selectedFolders: selectedFolders,
//        widgetIdentifier: widgetIdentifier
//    )
//}
//
//func allCaughtUpCardEntry(currentDate: Date,
//                          totalNumberOfCards: Int,
//                          nextCardForQueue: CardEntity?,
//                          configuredTypes: [CardType],
//                          selectedCardTypes: [CardType],
//                          selectedFolders: [Folder],
//                          widgetIdentifier: String) -> CardEntry {
//    let dummyCard = Card.makeDummy()
//    // Convert dummyCard to CardEntity
//    let dummyCardEntity = CardEntity(
//        id: dummyCard.id,
//
//        createdAt: dummyCard.createdAt,
//        cardTypeRaw: dummyCard.cardType.rawValue,
//        content: dummyCard.content,
//        answer: dummyCard.answer,
//        isRecurring: dummyCard.isRecurring,
//        skipCount: dummyCard.skipCount,
//        seenCount: dummyCard.seenCount,
//        repeatInterval: dummyCard.repeatInterval,
//        nextTimeInQueue: dummyCard.nextTimeInQueue,
//        folder: dummyCard.folder,
//        isArchived: dummyCard.isArchived,
//        answerRevealed: dummyCard.answerRevealed,
//        skipEnabled: dummyCard.skipEnabled,
//        tags: nil,
//        widgetTextHidden: dummyCard.widgetTextHidden,
//        contentImageData: nil,
//        answerImageData: nil
//    )
//    return CardEntry(
//        date: currentDate,
//        card: dummyCardEntity,
//        queueCardCount: 0,
//        totalNumberOfCards: totalNumberOfCards,
//        nextCardForQueue: nextCardForQueue,
//        nextUpdateDate: nextCardForQueue?.nextTimeInQueue ?? currentDate.addingTimeInterval(3600),
//        selectedCardTypes: selectedCardTypes,
//        selectedFolders: selectedFolders,
//        widgetIdentifier: widgetIdentifier
//    )
//}
//
//extension View {
//    func widgetBackground(backgroundView: some View) -> some View {
//        if #available(iOSApplicationExtension 17.0, *) { // or if #available(iOS 17, *)
//            return containerBackground(for: .widget) {
//                backgroundView
//            }
//        } else {
//            return background(backgroundView)
//        }
//    }
//}
//
//
//// MARK: - Button spec
//
//struct WidgetButtonSpec: Identifiable {
//    let id = UUID()
//    let title: String
//    let systemImage: String
//    let isPrimary: Bool
//    let index: Int
//}
//
//// MARK: - Widget Button Style
//
//struct WidgetButtonStyle: ButtonStyle {
//    let color: Color
//
//    func makeBody(configuration: Configuration) -> some View {
//        configuration.label
//            .scaleEffect(configuration.isPressed ? 0.85 : 1.0)
//            .opacity(configuration.isPressed ? 0.7 : 1.0)
//            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
//    }
//}
//
//struct TopNoteWidgetEntryView: View {
//    var entry: Provider.Entry
//    @Environment(\.widgetFamily) var family
//
//    var buttonsCount: Int = 4
//
//    var body: some View {
//        Group {
//            if family == .systemSmall {
//                SmallWidgetSummaryView(queueCount: entry.queueCardCount,
//                                       topCardDate: entry.card.nextTimeInQueue,
//                                       currentDate: entry.date,
//                                       selectedCardTypes: entry.selectedCardTypes,
//                                       selectedFolders: entry.selectedFolders)
//            } else {
//                // Use a VStack to pin buttons at the bottom and avoid overlap with card content
//                GeometryReader { geometry in
//                    ZStack {
//                        widgetBackgroundView(for: entry.card, widgetID: entry.widgetIdentifier)
//                            .frame(width: geometry.size.width, height: geometry.size.height)
//                            .clipped()
//
//                        let hideText = effectiveTextHidden(for: entry.card, widgetID: entry.widgetIdentifier)
//
//                        VStack(spacing: 6) {
//                            if isNoCardTypesSelected {
//                                VStack {
//                                    Image(systemName: "slider.horizontal.3")
//                                        .font(.largeTitle)
//                                        .foregroundColor(.gray)
//                                    Text("No card types selected.")
//                                        .font(.caption)
//                                        .multilineTextAlignment(.center)
//                                        .padding(.top, 4)
//                                    Text("Tap and edit this widget to choose what to display!")
//                                        .font(.caption)
//                                        .foregroundColor(.secondary)
//                                        .multilineTextAlignment(.center)
//                                        .padding(.top, 2)
//                                }
//                                .frame(maxWidth: .infinity, maxHeight: .infinity)
//                            } else if entry.queueCardCount == 0 {
//                                VStack {
//                                    HStack {
//                                        ForEach(entry.selectedCardTypes, id: \.self) { type in
//                                            Image(systemName: type.systemImage)
//                                                .imageScale(.medium)
//                                                .foregroundColor(.secondary)
//                                                .accessibilityLabel(Text(type.rawValue))
//                                        }
//                                    }
//                                    AllCaughtUpWidgetView(
//                                        selectedCardTypes: entry.selectedCardTypes,
//                                        selectedFolders: entry.selectedFolders,
//                                        nextCardDate: entry.nextCardForQueue?.nextTimeInQueue
//                                    )
//                                }
//                                .padding()
//                                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
//                            } else {
//                                // Header at top: keep its layout footprint to avoid background/content "jumping"
//                                ZStack(alignment: .top) {
//                                    // Header background with gradient that adapts to light/dark mode
//                                    LinearGradient(
//                                        colors: [
//                                            Color(uiColor: .systemBackground).opacity(0.85),
//                                            Color(uiColor: .systemBackground).opacity(0.5),
//                                            Color.clear
//                                        ],
//                                        startPoint: .top,
//                                        endPoint: .bottom
//                                    )
//                                    .frame(height: 50)
//                                    .frame(maxWidth: .infinity)
//
//                                    headerRow
//                                        .opacity(hideText ? 0 : 1)
//                                        .accessibilityHidden(hideText)
//                                        .padding(.horizontal, 14)
//                                        .padding(.top, 10)
//                                }
//                                .frame(height: 28, alignment: .top)
//
//                                // Content area (stable sizing; don't vary padding/height based on hideText)
//                                cardContentView(for: entry.card, widgetID: entry.widgetIdentifier)
//                                    .frame(maxWidth: .infinity, alignment: .topLeading)
//                                    .padding(.horizontal, 14)
//                                    .padding(.top, 2)
//                                    .animation(.easeInOut(duration: 0.3), value: entry.card.answerRevealed)
//
//                                // Spacer to push buttons to bottom
//                                Spacer(minLength: 0)
//
//                                // Buttons pinned at bottom
//                                cardButtonsView(for: entry.card, widgetID: entry.widgetIdentifier)
//                                    .padding(.horizontal, 10)
//                                    .padding(.bottom, 6)
//                            }
//                        }
//                        .frame(maxWidth: .infinity, maxHeight: .infinity)
//                    }
//                }
//                .containerBackground(.clear, for: .widget)
//                .widgetURL(URL(string: "topnote://card/\(entry.card.id.uuidString)"))
//            }
//        }
//        .onAppear {
//            // Mark that at least one TopNote widget is present
//            let shared = UserDefaults(suiteName: "group.com.zacharysturman.TopNote")
//            shared?.set(true, forKey: "hasWidget")
//        }
//    }
//
//    // MARK: Header (count badge + selected folders + tags)
//    private var headerRow: some View {
//        HStack(alignment: .center) {
//            // Removed selectedCardTypesView to reduce clutter (icons moved to count badge)
//
//            VStack(alignment: .leading, spacing: 2) {
//                combinedFoldersTagsView
//            }
//            .font(.caption)
//            .lineLimit(1)
//            .truncationMode(.tail)
//
//            Spacer()
//
//            countBadge(count: entry.queueCardCount)
//
//        }
//        .font(.caption2)
//    }
//
//
//    private var combinedFoldersTagsView: some View {
//        let tags = entry.card.tags
//        let folder = entry.card.folder
//        let hasImage = hasBackgroundImage(for: entry.card)
//
//        return HStack(spacing: 8) {
//            if let folder {
//                HStack(spacing: 2) {
//                    Image(systemName: "folder")
//                        .imageScale(.small)
//                    Text(folder.name)
//                        .font(.caption2)
//                        .minimumScaleFactor(0.7)
//                        .lineLimit(1)
//                        .truncationMode(.tail)
//                }
//                .foregroundColor(hasImage ? .white : .secondary)
//                .shadow(color: hasImage ? .black.opacity(0.7) : .clear, radius: 2, x: 0, y: 1)
//                .padding(.horizontal, 8)
//                .padding(.vertical, 4)
//                .background(hasImage ? Color.black.opacity(0.3) : Color.clear)
//                .clipShape(Capsule())
//                .accessibilityLabel(Text(folder.name))
//            }
//
//            if let tags, !tags.isEmpty {
//                HStack(spacing: 2) {
//                    Image(systemName: "tag")
//                        .imageScale(.small)
//                    Text(tags.joined(separator: ", "))
//                        .font(.caption2)
//                        .minimumScaleFactor(0.7)
//                        .lineLimit(1)
//                        .truncationMode(.tail)
//                }
//                .foregroundColor(hasImage ? .white : .secondary)
//                .shadow(color: hasImage ? .black.opacity(0.7) : .clear, radius: 2, x: 0, y: 1)
//                .padding(.horizontal, 8)
//                .padding(.vertical, 4)
//                .background(hasImage ? Color.black.opacity(0.3) : Color.clear)
//                .clipShape(Capsule())
//                .accessibilityLabel(Text("Tags: \(tags.joined(separator: ", "))"))
//            }
//        }
//        .frame(maxWidth: .infinity, alignment: .leading)
//    }
//
//    // MARK: Updated count badge to show selected card type icons horizontally before count number
//    private func countBadge(count: Int) -> some View {
//        let hasImage = hasBackgroundImage(for: entry.card)
//
//        return HStack(spacing: 4) {
//            // Show all selected card type icons horizontally
//            ForEach(entry.selectedCardTypes, id: \.self) { type in
//                Image(systemName: type.systemImage)
//                    .font(.caption2)
//                    .minimumScaleFactor(0.7)
//                    .imageScale(.medium)
//                    .foregroundColor(hasImage ? .white : .accentColor)
//                    .shadow(color: hasImage ? .black.opacity(0.7) : .clear, radius: 2, x: 0, y: 1)
//                    .accessibilityLabel(Text(type.rawValue))
//            }
//
//            Text("\(count)")
//                .font(.caption2).bold()
//                .minimumScaleFactor(0.7)
//                .foregroundColor(hasImage ? .white : .secondary)
//                .shadow(color: hasImage ? .black.opacity(0.7) : .clear, radius: 2, x: 0, y: 1)
//                .monospacedDigit()
//        }
//        .padding(.horizontal, 8)
//        .padding(.vertical, 4)
//        .background(
//            hasImage ? Color.black.opacity(0.3) : Color.clear
//        )
//        .clipShape(Capsule())
//        .accessibilityElement(children: .combine)
//        .accessibilityLabel(Text("Items: \(count)"))
//    }
//
//    private var isNoCardTypesSelected: Bool {
//        entry.selectedCardTypes.isEmpty
//    }
//
//    // Helper for background color based on cardType tintColor with subtle opacity
//    private func backgroundColor() -> Color {
//        entry.card.cardType.tintColor.opacity(0.10)
//    }
//
//    private func isEmptyText(_ text: String?) -> Bool {
//        (text ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
//    }
//
//    private func shouldShowTextToggle(for card: CardEntity) -> Bool {
//        switch card.cardType {
//        case .flashcard:
//            if card.answerRevealed {
//                let hasAnswerImage = card.answerImageData != nil
//                let hasAnyText = !isEmptyText(card.content) || !isEmptyText(card.answer)
//                return hasAnswerImage && hasAnyText
//            } else {
//                let hasContentImage = card.contentImageData != nil
//                let hasContentText = !isEmptyText(card.content)
//                return hasContentImage && hasContentText
//            }
//        case .todo, .note:
//            let hasContentImage = card.contentImageData != nil
//            let hasContentText = !isEmptyText(card.content)
//            return hasContentImage && hasContentText
//        }
//    }
//
//    private func effectiveTextHidden(for card: CardEntity, widgetID: String) -> Bool {
//        if shouldShowTextToggle(for: card) {
//            return WidgetStateManager.shared.isTextHidden(widgetID: widgetID, cardID: card.id)
//        }
//        return false
//    }
//
//    @ViewBuilder
//    private func widgetBackgroundView(for card: CardEntity, widgetID: String) -> some View {
//        let isFlipped = card.cardType == .flashcard && WidgetStateManager.shared.isFlipped(widgetID: widgetID, cardID: card.id)
//        if card.cardType == .flashcard, isFlipped {
//            if let data = card.answerImageData, let uiImage = UIImage(data: data) {
//                Image(uiImage: uiImage)
//                    .resizable()
//                    .scaledToFill()
//            } else {
//                backgroundColor()
//            }
//        } else {
//            if let data = card.contentImageData, let uiImage = UIImage(data: data) {
//                Image(uiImage: uiImage)
//                    .resizable()
//                    .scaledToFill()
//            } else {
//                backgroundColor()
//            }
//        }
//    }
//
//    // MARK: Card buttons view based on cardType with fixed size buttons and updated logic
//    @ViewBuilder
//    private func cardButtonsView(for card: CardEntity, widgetID: String) -> some View {
//        let showTextToggle = shouldShowTextToggle(for: card)
//        let isFlipped = card.cardType == .flashcard && WidgetStateManager.shared.isFlipped(widgetID: widgetID, cardID: card.id)
//        switch card.cardType {
//        case .flashcard:
//            FlashcardButtonGroup(
//                isCardFlipped: isFlipped,
//                skipCount: card.skipCount,
//                skipEnabled: card.skipEnabled,
//                card: card,
//                widgetID: widgetID,
//                showTextToggle: showTextToggle)
//        case .todo:
//            TodoCardButtonGroup(skipEnabled: card.skipEnabled, card: card, widgetID: widgetID, showTextToggle: showTextToggle)
//        case .note:
//            NoteCardButtonGroup(skipEnabled: card.skipEnabled, card: card, widgetID: widgetID, showTextToggle: showTextToggle)
//        }
//    }
//
//    // MARK: Card content view simplified to Text replacing ResizableTruncatingText usages
//
//    private func isLongOrMultiline(_ text: String?) -> Bool {
//        guard let text else { return false }
//        let newlineCount = text.filter { $0 == "\n" }.count
//        return newlineCount > 2 || text.count > 280
//    }
//
//    // Helper to determine if there's a background image for text shadow purposes
//    private func hasBackgroundImage(for card: CardEntity, isFlipped: Bool = false) -> Bool {
//        if card.cardType == .flashcard && isFlipped {
//            return card.answerImageData != nil
//        } else {
//            return card.contentImageData != nil
//        }
//    }
//
//    @ViewBuilder
//    private func cardContentView(for card: CardEntity, widgetID: String) -> some View {
//        let hideText = effectiveTextHidden(for: card, widgetID: widgetID)
//        let isFlipped = card.cardType == .flashcard && WidgetStateManager.shared.isFlipped(widgetID: widgetID, cardID: card.id)
//        let hasImage = hasBackgroundImage(for: card, isFlipped: isFlipped)
//
//        switch card.cardType {
//        case .flashcard:
//            if isFlipped {
//                // Flipped flashcard:
//                // - Content at top (truncated), answer below (shown as much as possible).
//                // - Answer image is the widget background.
//                let isLargeWidget = family == .systemLarge || family == .systemExtraLarge
//                let contentHeight: CGFloat = isLargeWidget ? 50 : 28
//
//                VStack(spacing: isLargeWidget ? 4 : 2) {
//                    // Content (question) - small, at top, truncated is OK
//                    HStack(alignment: .top, spacing: 6) {
//                        if !hideText, !isEmptyText(card.content) {
//                            Text(card.content)
//                                .font(.caption2)
//                                .foregroundColor(hasImage ? .white : .secondary)
//                                .lineLimit(isLargeWidget ? 2 : 1)
//                                .minimumScaleFactor(0.6)
//                                .frame(maxWidth: .infinity, alignment: .leading)
//                                .shadow(color: hasImage ? .black.opacity(0.8) : .clear, radius: 3, x: 0, y: 1)
//                                .shadow(color: hasImage ? .black.opacity(0.5) : .clear, radius: 1, x: 0, y: 0)
//                        }
//                    }
//                    .frame(height: contentHeight)
//
//                    // Answer - shown as much as possible, minimize truncation
//                    VStack(alignment: .leading, spacing: 2) {
//                        if !hideText, let answer = card.answer, !isEmptyText(answer) {
//                            Text(answer)
//                                .font(isLargeWidget ? .body : .subheadline)
//                                .fontWeight(hasImage ? .medium : .regular)
//                                .foregroundColor(hasImage ? .white : .primary)
//                                .lineLimit(isLargeWidget ? 10 : 6)
//                                .minimumScaleFactor(0.5)
//                                .fixedSize(horizontal: false, vertical: false)
//                                .frame(maxWidth: .infinity, alignment: .leading)
//                                .shadow(color: hasImage ? .black.opacity(0.8) : .clear, radius: 3, x: 0, y: 1)
//                                .shadow(color: hasImage ? .black.opacity(0.5) : .clear, radius: 1, x: 0, y: 0)
//                        }
//                    }
//                    .frame(maxHeight: .infinity, alignment: .top)
//                }
//                .padding(hasImage ? 8 : 0)
//                .background(
//                    hasImage && !hideText ? Color.black.opacity(0.45) : nil
//                )
//                .cornerRadius(8)
//            } else {
//                // Not flipped: content image becomes the widget background when present.
//                // Show content text as much as possible
//                if !hideText, !isEmptyText(card.content) {
//                    Text(card.content)
//                        .font(family == .systemLarge || family == .systemExtraLarge ? .body : .subheadline)
//                        .fontWeight(hasImage ? .medium : .regular)
//                        .foregroundColor(hasImage ? .white : .primary)
//                        .lineLimit(family == .systemLarge || family == .systemExtraLarge ? 8 : 5)
//                        .minimumScaleFactor(0.5)
//                        .fixedSize(horizontal: false, vertical: false)
//                        .frame(maxWidth: .infinity, alignment: .leading)
//                        .shadow(color: hasImage ? .black.opacity(0.8) : .clear, radius: 3, x: 0, y: 1)
//                        .shadow(color: hasImage ? .black.opacity(0.5) : .clear, radius: 1, x: 0, y: 0)
//                        .padding(hasImage ? 8 : 0)
//                        .background(
//                            hasImage ? Color.black.opacity(0.45) : nil
//                        )
//                        .cornerRadius(8)
//                }
//            }
//        case .todo:
//            if !hideText, !isEmptyText(card.content) {
//                Text(card.content)
//                    .font(family == .systemLarge || family == .systemExtraLarge ? .body : .subheadline)
//                    .fontWeight(hasImage ? .medium : .regular)
//                    .foregroundColor(hasImage ? .white : .primary)
//                    .lineLimit(family == .systemLarge || family == .systemExtraLarge ? 8 : 5)
//                    .minimumScaleFactor(0.5)
//                    .fixedSize(horizontal: false, vertical: false)
//                    .frame(maxWidth: .infinity, alignment: .leading)
//                    .shadow(color: hasImage ? .black.opacity(0.8) : .clear, radius: 3, x: 0, y: 1)
//                    .shadow(color: hasImage ? .black.opacity(0.5) : .clear, radius: 1, x: 0, y: 0)
//                    .padding(hasImage ? 8 : 0)
//                    .background(
//                        hasImage ? Color.black.opacity(0.45) : nil
//                    )
//                    .cornerRadius(8)
//            }
//        case .note:
//            if !hideText, !isEmptyText(card.content) {
//                Text(card.content)
//                    .font(family == .systemLarge || family == .systemExtraLarge ? .body : .subheadline)
//                    .fontWeight(hasImage ? .medium : .regular)
//                    .foregroundColor(hasImage ? .white : .primary)
//                    .lineLimit(family == .systemLarge || family == .systemExtraLarge ? 8 : 5)
//                    .minimumScaleFactor(0.5)
//                    .fixedSize(horizontal: false, vertical: false)
//                    .frame(maxWidth: .infinity, alignment: .leading)
//                    .shadow(color: hasImage ? .black.opacity(0.8) : .clear, radius: 3, x: 0, y: 1)
//                    .shadow(color: hasImage ? .black.opacity(0.5) : .clear, radius: 1, x: 0, y: 0)
//                    .padding(hasImage ? 8 : 0)
//                    .background(
//                        hasImage ? Color.black.opacity(0.45) : nil
//                    )
//                    .cornerRadius(8)
//            }
//        }
//    }
//
//    /// Removed cardFolderTagsView as tags are now included up top
//
//}
//
//private func allCaughtUpMessage(for types: [CardType], folders: [Folder]) -> String {
//    if types.isEmpty {
//        return "No card types selected."
//    }
//    let typeNames = types.map { "\($0.rawValue)s" }.joined(separator: ", ")
//    if folders.isEmpty {
//        return "All caught up for \(typeNames)!"
//    } else {
//        let folderNames = folders.map(\.name).joined(separator: ", ")
//        return "All caught up for \(typeNames) in \(folderNames)!"
//    }
//}
//
//struct AllCaughtUpWidgetView: View {
//    let selectedCardTypes: [CardType]
//    let selectedFolders: [Folder]
//    let nextCardDate: Date?
//
//    var body: some View {
//        VStack(spacing: 10) {
//            Text(allCaughtUpMessage(for: selectedCardTypes, folders: selectedFolders))
//                .font(.caption)
//                .foregroundColor(.secondary)
//                .multilineTextAlignment(.center)
//                .accessibilityLabel(Text("All caught up."))
//
//            if let nextDate = nextCardDate {
//                Text("Next card: \(formattedDate(nextDate))")
//                    .font(.caption2)
//                    .foregroundColor(.secondary)
//                    .multilineTextAlignment(.center)
//                    .accessibilityLabel(Text("Next card: \(formattedDate(nextDate))"))
//            }
//            Spacer()
//        }
//        .padding(.horizontal, 18)
//        .padding(.vertical, 14)
//        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
//    }
//
//    private func formattedDate(_ date: Date) -> String {
//        let formatter = RelativeDateTimeFormatter()
//        formatter.unitsStyle = .abbreviated
//        return formatter.localizedString(for: date, relativeTo: Date())
//    }
//}
//
//struct SmallWidgetSummaryView: View {
//    let queueCount: Int
//    let topCardDate: Date
//    let currentDate: Date
//
//    let selectedCardTypes: [CardType]
//    let selectedFolders: [Folder]
//
//    var body: some View {
//        VStack(spacing: 10) {
//            if queueCount == 0 {
//                HStack {
//                    ForEach(selectedCardTypes, id: \.self) { type in
//                        Image(systemName: type.systemImage)
//                            .imageScale(.medium)
//                            .foregroundColor(.secondary)
//                            .accessibilityLabel(Text(type.rawValue))
//                    }
//                }
//
//                AllCaughtUpWidgetView(selectedCardTypes: selectedCardTypes, selectedFolders: selectedFolders, nextCardDate: nil)
//            } else {
//
//                HStack(spacing: 6) {
//                    ForEach(selectedCardTypes, id: \.self) { type in
//                        Image(systemName: type.systemImage)
//                            .imageScale(.medium)
//                            .foregroundColor(.accentColor)
//                            .accessibilityLabel(Text(type.rawValue))
//                    }
//                    if !selectedFolders.isEmpty {
//                        Text(selectedFolders.map(\.name).joined(separator: ", "))
//                            .font(.caption)
//                            .foregroundColor(.accentColor)
//                            .lineLimit(1)
//                            .truncationMode(.tail)
//                    }
//                }
//
//                Image(systemName: "tray.full")
//                    .font(.largeTitle)
//                    .foregroundColor(.accentColor)
//                Text("\(queueCount)")
//                    .font(.caption).bold()
//                    .monospacedDigit()
//                    .accessibilityLabel(Text("\(queueCount) cards in queue"))
//                Text("\(formatDuration(since: topCardDate, until: currentDate))")
//                    .font(.caption)
//                    .foregroundColor(.secondary)
//                    .multilineTextAlignment(.center)
//            }
//        }
//        .frame(maxWidth: .infinity, maxHeight: .infinity)
//        .padding()
//    }
//}
//
//private func formatDuration(since start: Date, until end: Date) -> String {
//    let seconds = Int(end.timeIntervalSince(start))
//    if seconds < 60 {
//        return "Just now"
//    } else if seconds < 3600 {
//        let minutes = seconds / 60
//        return "\(minutes) min"
//    } else if seconds < 86400 {
//        let hours = seconds / 3600
//        return "\(hours) hr"
//    } else if seconds < 604800 {
//        let days = seconds / 86400
//        return "\(days) day\(days > 1 ? "s" : "")"
//    } else {
//        let weeks = seconds / 604800
//        return "\(weeks) week\(weeks > 1 ? "s" : "")"
//    }
//}
//
//struct TopNoteWidget: Widget {
//    let kind: String = "Top Note Widget"
//
//    var body: some WidgetConfiguration {
//        AppIntentConfiguration(kind: kind, intent: ConfigurationAppIntent.self, provider: Provider()) { entry in
//            TopNoteWidgetEntryView(entry: entry)
//                .frame(maxWidth: .infinity, maxHeight: .infinity)
//                .containerBackground(.fill.tertiary, for: .widget)
//        }
//        .configurationDisplayName("Top Note Widget")
//        .description("Displays a card from your collection.")
//        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge, .systemExtraLarge])
//        .contentMarginsDisabled()
//    }
//}
//
//
//// MARK: - Button groups with fixed size buttons and updated logic
//
//private let buttonSize: CGFloat = 32
//
///// Button group for Note cards:
///// Show only Next if !skipEnabled, else show Next and Skip.
///// Both buttons have the same fixed size.
///// Show/hide text button appears to the left of skip/next when there's an image.
//internal struct NoteCardButtonGroup: View {
//    let skipEnabled: Bool
//    let card: CardEntity
//    let widgetID: String
//    let showTextToggle: Bool
//
//    init(skipEnabled: Bool, card: CardEntity, widgetID: String, showTextToggle: Bool = false) {
//        self.skipEnabled = skipEnabled
//        self.card = card
//        self.widgetID = widgetID
//        self.showTextToggle = showTextToggle
//    }
//
//    var body: some View {
//        let isTextHidden = WidgetStateManager.shared.isTextHidden(widgetID: widgetID, cardID: card.id)
//        HStack {
//            Button(intent: NextCardIntent(card: card)) {
//                ZStack {
//                    Circle()
//                        .fill(Color.blue.opacity(0.85))
//                        .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
//                    Image(systemName: "checkmark.rectangle.stack")
//                        .font(.caption)
//                        .foregroundColor(.white)
//                }
//            }
//            .frame(width: buttonSize, height: buttonSize)
//            .buttonStyle(WidgetButtonStyle(color: .blue))
//            Spacer()
//
//            RecurringMessage(card: card)
//            Spacer()
//
//            // Show/hide text button to the left of skip button
//            if showTextToggle {
//                Button(intent: ToggleWidgetTextIntent(card: card, widgetID: widgetID)) {
//                    ZStack {
//                        Circle()
//                            .fill(Color.gray.opacity(0.85))
//                            .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
//                        Image(systemName: isTextHidden ? "text.badge.plus" : "text.badge.minus")
//                            .font(.caption)
//                            .foregroundColor(.white)
//                    }
//                }
//                .frame(width: buttonSize, height: buttonSize)
//                .buttonStyle(WidgetButtonStyle(color: .gray))
//                .accessibilityLabel(Text(isTextHidden ? "Show text" : "Hide text"))
//            }
//
//            if skipEnabled {
//                Button(intent: SkipCardIntent(card: card)) {
//                    ZStack {
//                        Circle()
//                            .fill(Color.orange.opacity(0.85))
//                            .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
//                        Image(systemName: "arrow.trianglehead.counterclockwise.rotate.90")
//                            .font(.caption)
//                            .foregroundColor(.white)
//                    }
//                }
//                .frame(width: buttonSize, height: buttonSize)
//                .buttonStyle(WidgetButtonStyle(color: .orange))
//            }
//        }
//        .padding(6)
//        .background(
//            RoundedRectangle(cornerRadius: 12)
//                .fill(Color(uiColor: .systemBackground).opacity(0.75))
//                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: -2)
//        )
//    }
//}
//
//
///// Button group for Todo cards:
///// Always show Complete and (Next if !skipEnabled, else Skip).
///// Both buttons same size.
///// Show/hide text button appears to the left of skip button when there's an image.
//internal struct TodoCardButtonGroup: View {
//    let skipEnabled: Bool
//    let card: CardEntity
//    let widgetID: String
//    let showTextToggle: Bool
//
//    init(skipEnabled: Bool, card: CardEntity, widgetID: String, showTextToggle: Bool = false) {
//        self.skipEnabled = skipEnabled
//        self.card = card
//        self.widgetID = widgetID
//        self.showTextToggle = showTextToggle
//    }
//
//    var body: some View {
//        let isTextHidden = WidgetStateManager.shared.isTextHidden(widgetID: widgetID, cardID: card.id)
//        HStack {
//            Button(intent: CompleteTodoIntent(card: card)) {
//                ZStack {
//                    Circle()
//                        .fill(Color.green.opacity(0.85))
//                        .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
//                    Image(systemName: "checkmark.circle")
//                        .font(.caption)
//                        .foregroundColor(.white)
//                }
//            }
//            .frame(width: buttonSize, height: buttonSize)
//            .buttonStyle(WidgetButtonStyle(color: .green))
//
//            Spacer()
//
//            RecurringMessage(card: card)
//            Spacer()
//
//            // Show/hide text button to the left of skip button
//            if showTextToggle {
//                Button(intent: ToggleWidgetTextIntent(card: card, widgetID: widgetID)) {
//                    ZStack {
//                        Circle()
//                            .fill(Color.gray.opacity(0.85))
//                            .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
//                        Image(systemName: isTextHidden ? "text.badge.plus" : "text.badge.minus")
//                            .font(.caption)
//                            .foregroundColor(.white)
//                    }
//                }
//                .frame(width: buttonSize, height: buttonSize)
//                .buttonStyle(WidgetButtonStyle(color: .gray))
//                .accessibilityLabel(Text(isTextHidden ? "Show text" : "Hide text"))
//            }
//
//            Button(intent: SkipCardIntent(card: card)) {
//                ZStack {
//                    Circle()
//                        .fill(Color.orange.opacity(0.85))
//                        .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
//                    Image(systemName: "arrow.trianglehead.counterclockwise.rotate.90")
//                        .font(.caption)
//                        .foregroundColor(.white)
//                }
//            }
//            .frame(width: buttonSize, height: buttonSize)
//            .buttonStyle(WidgetButtonStyle(color: .orange))
//        }
//        .padding(6)
//        .background(
//            RoundedRectangle(cornerRadius: 12)
//                .fill(Color(uiColor: .systemBackground).opacity(0.75))
//                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: -2)
//        )
//    }
//}
//
//internal struct RecurringMessage: View {
//    let card: CardEntity
//
//    var body: some View {
//        Group {
//            if !card.isRecurring {
//                switch card.cardType {
//                case .todo:
//                    Text("this card will be archived upon complete")
//                        .font(.caption2)
//                        .minimumScaleFactor(0.7)
//                        .foregroundColor(.secondary)
//                        .frame(maxWidth: .infinity, alignment: .center)
//                        .padding(.bottom, 4)
//                case .flashcard:
//                    if card.answerRevealed {
//                        Text("this card will be archived when rated")
//                            .font(.caption2)
//                            .minimumScaleFactor(0.7)
//                            .foregroundColor(.secondary)
//                            .frame(maxWidth: .infinity, alignment: .center)
//                            .padding(.bottom, 4)
//                    } else {
//                        Text("this card will be archived when flipped and rated")
//                            .font(.caption2)
//                            .minimumScaleFactor(0.7)
//                            .foregroundColor(.secondary)
//                            .frame(maxWidth: .infinity, alignment: .center)
//                            .padding(.bottom, 4)
//                    }
//                case .note:
//                    Text("this card will be archived when Next is tapped")
//                        .font(.caption2)
//                        .minimumScaleFactor(0.7)
//                        .foregroundColor(.secondary)
//                        .frame(maxWidth: .infinity, alignment: .center)
//                        .padding(.bottom, 4)
//                }
//            }
//        }
//    }
//}
//
///// Button group for Flashcard cards:
///// If not flipped: Flip and (Skip if skipEnabled else Next).
///// If flipped: show all three rating buttons: Easy, Good, Hard.
///// On systemSmall, flipped state buttons shown horizontally with equal square buttons.
///// On other sizes, flipped buttons shown in horizontal row with equal square buttons.
///// Show/hide text button appears to the left of skip/next when there's an image.
//internal struct FlashcardButtonGroup: View {
//    let isCardFlipped: Bool
//    let skipCount: Int
//    let skipEnabled: Bool
//    let card: CardEntity
//    let widgetID: String
//    let showTextToggle: Bool
//
//    init(isCardFlipped: Bool, skipCount: Int, skipEnabled: Bool, card: CardEntity, widgetID: String, showTextToggle: Bool = false) {
//        self.isCardFlipped = isCardFlipped
//        self.skipCount = skipCount
//        self.skipEnabled = skipEnabled
//        self.card = card
//        self.widgetID = widgetID
//        self.showTextToggle = showTextToggle
//    }
//
//    var body: some View {
//        let isTextHidden = WidgetStateManager.shared.isTextHidden(widgetID: widgetID, cardID: card.id)
//        if isCardFlipped {
//            HStack(spacing: 12) {
//                ratingButton(ratingType: .easy, card: card)
//                ratingButton(ratingType: .good, card: card)
//                ratingButton(ratingType: .hard, card: card)
//                Spacer()
//                RecurringMessage(card: card)
//                Spacer()
//
//                // Show/hide text button to the left of skip/next button
//                if showTextToggle {
//                    Button(intent: ToggleWidgetTextIntent(card: card, widgetID: widgetID)) {
//                        ZStack {
//                            Circle()
//                                .fill(Color.gray.opacity(0.85))
//                                .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
//
//                            // Base character icon
//                            Image(systemName: "textformat.characters")
//                                .font(.caption)
//                                .foregroundColor(.white)
//
//                            // Slash overlay (only when hidden)
//                            if !isTextHidden {
//                                Capsule()
//                                    .fill(Color.white)
//                                    .frame(width: 22, height: 2)
//                                    .rotationEffect(.degrees(33))
//                                    .shadow(color: .gray.opacity(0.1), radius: 3, x: 0, y: 1)
//
//                            }
//                        }
//                    }
//                    .frame(width: buttonSize, height: buttonSize)
//                    .buttonStyle(WidgetButtonStyle(color: .gray))
//                    .accessibilityLabel(Text(isTextHidden ? "Show text" : "Hide text"))
//                }
//
//                skipOrNextButton()
//            }
//            .padding(6)
//            .transition(.opacity.combined(with: .scale))
//
//        } else {
//            // Not flipped: Flip and Skip/Next buttons side by side with fixed size, skip/next at trailing
//            HStack(spacing: 12) {
//                Button(intent: ShowFlashcardAnswer(card: card, widgetID: widgetID)) {
//                    ZStack {
//                        Circle()
//                            .fill(Color.purple.opacity(0.85))
//                            .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
//                        Image(systemName: "rectangle.2.swap")
//                            .font(.caption)
//                            .foregroundColor(.white)
//                    }
//                }
//                .frame(width: buttonSize, height: buttonSize)
//                .buttonStyle(WidgetButtonStyle(color: .purple))
//
//                Spacer()
//
//                RecurringMessage(card: card)
//                Spacer()
//
//                // Show/hide text button to the left of skip/next button
//                if showTextToggle {
//                    Button(intent: ToggleWidgetTextIntent(card: card, widgetID: widgetID)) {
//                        ZStack {
//                            Circle()
//                                .fill(Color.gray.opacity(0.85))
//                                .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
//
//                            // Base character icon
//                            Image(systemName: "textformat.characters")
//                                .font(.caption)
//                                .foregroundColor(.white)
//
//                            // Slash overlay (only when hidden)
//                            if !isTextHidden {
//                                Capsule()
//                                    .fill(Color.white)
//                                    .frame(width: 22, height: 2)
//                                    .rotationEffect(.degrees(33))
//                                    .shadow(color: .gray.opacity(0.1), radius: 3, x: 0, y: 1)
//
//                            }
//                        }
//                    }
//                    .frame(width: buttonSize, height: buttonSize)
//                    .buttonStyle(WidgetButtonStyle(color: .gray))
//                    .accessibilityLabel(Text(isTextHidden ? "Show text" : "Hide text"))
//                }
//
//                if skipEnabled {
//                    Button(intent: SkipCardIntent(card: card)) {
//                        ZStack {
//                            Circle()
//                                .fill(Color.orange.opacity(0.85))
//                                .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
//                            Image(systemName: "arrow.trianglehead.counterclockwise.rotate.90")
//                                .font(.caption)
//                                .foregroundColor(.white)
//                        }
//                    }
//                    .frame(width: buttonSize, height: buttonSize)
//                    .buttonStyle(WidgetButtonStyle(color: .orange))
//                } else {
//                    Button(intent: NextCardIntent(card: card)) {
//                        ZStack {
//                            Circle()
//                                .fill(Color.blue.opacity(0.85))
//                                .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
//                            Image(systemName: "checkmark.rectangle.stack")
//                                .font(.caption)
//                                .foregroundColor(.white)
//                        }
//                    }
//                    .frame(width: buttonSize, height: buttonSize)
//                    .buttonStyle(WidgetButtonStyle(color: .blue))
//                }
//            }
//            .padding(6)
//            .transition(.opacity.combined(with: .scale))
//        }
//    }
//
//    private func ratingButton(ratingType: RatingType, card: CardEntity) -> some View {
//        // Rating buttons for Easy, Good, Hard
//        // Each button has a fixed size and uses an intent to submit the rating
//        // Uses a consistent button style and background for all buttons
//        Button(intent: SubmitFlashcardRatingTypeIntent(selectedRating: RatingType.allCases.firstIndex(of: ratingType) ?? 0, card: card)) {
//            ZStack {
//                Circle()
//                    .fill(color(for: ratingType).opacity(0.85))
//                    .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
//                Image(systemName: ratingType.systemImage)
//                    .font(.caption)
//                    .foregroundColor(.white)
//            }
//        }
//        .frame(width: buttonSize, height: buttonSize)
//        .buttonStyle(WidgetButtonStyle(color: color(for: ratingType)))
//    }
//
//    private func color(for ratingType: RatingType) -> Color {
//        switch ratingType {
//        case .easy:
//            return .green
//        case .good:
//            return .blue
//        case .hard:
//            return .red
//        }
//    }
//
//    private func skipOrNextButton() -> some View {
//        if skipEnabled {
//            Button(intent: SkipCardIntent(card: card)) {
//                ZStack {
//                    Circle()
//                        .fill(Color.orange.opacity(0.85))
//                        .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
//                    Image(systemName: "forward.frame")
//                        .font(.caption)
//                        .foregroundColor(.white)
//                }
//            }
//            .frame(width: buttonSize, height: buttonSize)
//            .buttonStyle(WidgetButtonStyle(color: .orange))
//        } else {
//            Button(intent: NextCardIntent(card: card)) {
//                ZStack {
//                    Circle()
//                        .fill(Color.blue.opacity(0.85))
//                        .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
//                    Image(systemName: "checkmark.rectangle.stack")
//                        .font(.caption)
//                        .foregroundColor(.white)
//                }
//            }
//            .frame(width: buttonSize, height: buttonSize)
//            .buttonStyle(WidgetButtonStyle(color: .blue))
//        }
//    }
//}
//
//extension Card {
//    static func makeDummy() -> Card {
//        Card(
//            createdAt: Date(),
//            cardType: .note,
//            priorityTypeRaw: .none,
//            content: "",
//            isRecurring: false,
//            skipCount: 0,
//            seenCount: 0,
//            repeatInterval: 0,
//            //isDynamic: false,
//            nextTimeInQueue: Date(),
//            folder: nil,
//            tags: [],
//            answer: nil,
//            rating: [],
//            isArchived: false,
//            //answerRevealed: false,
//            skipPolicy: .none,
//            ratingEasyPolicy: .none,
//            ratingMedPolicy: .none,
//            ratingHardPolicy: .none
//        )
//    }
//    var isDummy: Bool {
//        content.isEmpty && !isRecurring && skipCount == 0 && seenCount == 0 && tags?.isEmpty != false
//    }
//}
//
//
//
//
//struct NoteCardWidgetView: View {
//    let content: String
//    let skipEnabled: Bool
//    @Environment(\.widgetFamily) var widgetFamily
//
//    init(content: String, skipEnabled: Bool) {
//        self.content = content
//        self.skipEnabled = skipEnabled
//    }
//
//    private func isLongOrMultiline(_ text: String?) -> Bool {
//        guard let text else { return false }
//        let newlineCount = text.filter { $0 == "\n" }.count
//        return newlineCount > 2 || text.count > 280
//    }
//
//    var body: some View {
//        VStack(spacing: 8) {
//            HStack(alignment: .top, spacing: 8) {
//                Spacer()
//                Text(content)
//                    .font(.body)
//                    .multilineTextAlignment(isLongOrMultiline(content) ? .leading : .center)
//
//                    .minimumScaleFactor(0.7)
//                    .frame(maxWidth: .infinity, alignment: .leading)
//                Spacer()
//            }
//        }
//        .padding(6)
//    }
//}
//
//struct TodoCardWidgetView: View {
//    let content: String
//    @Environment(\.widgetFamily) var widgetFamily
//
//    init(content: String) {
//        self.content = content
//    }
//
//    private func isLongOrMultiline(_ text: String?) -> Bool {
//        guard let text else { return false }
//        let newlineCount = text.filter { $0 == "\n" }.count
//        return newlineCount > 2 || text.count > 280
//    }
//
//    var body: some View {
//        VStack(spacing: 8) {
//            HStack(alignment: .top, spacing: 8) {
//                Spacer()
//                Text(content)
//                    .font(.body)
//                    .multilineTextAlignment(isLongOrMultiline(content) ? .leading : .center)
//
//                    .minimumScaleFactor(0.7)
//                    .frame(maxWidth: .infinity, alignment: .leading)
//                Spacer()
//            }
//        }
//        .padding(6)
//    }
//}
//
//
//extension UIImage {
//    func widgetThumbnail(maxSize: CGFloat) -> UIImage {
//        let size = self.size
//        let ratio = max(size.width, size.height) / maxSize
//
//        if ratio <= 1 {
//            return self
//        }
//
//        let newSize = CGSize(width: size.width / ratio, height: size.height / ratio)
//
//        let renderer = UIGraphicsImageRenderer(size: newSize)
//        return renderer.image { _ in
//            self.draw(in: CGRect(origin: .zero, size: newSize))
//        }
//    }
//}
