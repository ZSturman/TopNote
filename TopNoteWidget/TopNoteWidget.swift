//
//  TopNoteWidget.swift
//  TopNote
//
//  Created by Zachary Sturman on 2/17/25.
//

import WidgetKit
import SwiftUI
import SwiftData
import AppIntents

struct CardEntity: AppEntity {
    var id: UUID
    var createdAt: Date
    var cardTypeRaw: String
    var content: String
    var answer: String?
    var isRecurring: Bool
    var skipCount: Int
    var seenCount: Int
    var repeatInterval: Int
    var nextTimeInQueue: Date
    var folder: Folder?
    var isArchived: Bool
    var answerRevealed: Bool
    var skipEnabled: Bool
    var tags: [String]?

    var cardType: CardType {
        CardType(rawValue: cardTypeRaw) ?? .note
    }

    static var defaultQuery = CardEntityQuery()

    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        TypeDisplayRepresentation(name: LocalizedStringResource("Cards", table: "AppIntents"))
    }

    var displayRepresentation: DisplayRepresentation {
        let displayText = content
        return DisplayRepresentation(stringLiteral: displayText)
    }
}

struct CardEntry: TimelineEntry {
    let date: Date            // This represents when the entry was generated ("Last updated")
    let card: CardEntity
    let queueCardCount: Int
    let totalNumberOfCards: Int
    let nextCardForQueue: CardEntity?
    let nextUpdateDate: Date  // New field to show the next update time

    let selectedCardTypes: [CardType]
    let selectedFolders: [Folder]
}


struct Provider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> CardEntry {
        placeholderCardEntry()
    }
    
    func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> CardEntry {
        sampleCardEntry()
    }
    
    
    func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<CardEntry> {
        let currentDate = Date()
        
        if configuration.showCardType.isEmpty {
            let entry = noCardTypesSelectedEntry(currentDate: currentDate,
                                                 selectedCardTypes: configuration.showCardType,
                                                 selectedFolders: configuration.showFolders)
            return Timeline(entries: [entry], policy: .never)
        }
        
        guard let container = try? ModelContainer(for: Card.self) else {
            return Timeline(entries: [], policy: .never)
        }
        let modelContext = ModelContext(container)
        let queueManager = QueueManager(context: modelContext)
        
        do {
            let (cardsInQueue, nextCardForQueue, totalNumberOfCards) = try queueManager.fetchQueueCardsAndSummary(currentDate: currentDate, configuration: configuration)
            
            // Convert all Cards to CardEntity
            let cardsInQueueEntities: [CardEntity] = cardsInQueue.map {
                CardEntity(id: $0.id,
                           createdAt: $0.createdAt,
                           cardTypeRaw: $0.cardType.rawValue,
                           content: $0.displayContent,
                           answer: $0.displayAnswer,
                           isRecurring: $0.isRecurring,
                           skipCount: $0.skipCount,
                           seenCount: $0.seenCount,
                           repeatInterval: $0.repeatInterval,
                           nextTimeInQueue: $0.nextTimeInQueue,
                           folder: $0.folder,
                           isArchived: $0.isArchived,
                           answerRevealed: $0.answerRevealed,
                           skipEnabled: $0.skipEnabled,
                           tags: $0.unwrappedTags.map(\.name))
            }
            
            let nextCardEntity: CardEntity? = nextCardForQueue.map {
                CardEntity(id: $0.id,
     
                           createdAt: $0.createdAt,
                           cardTypeRaw: $0.cardType.rawValue,
                           content: $0.displayContent,
                           answer: $0.displayAnswer,
                           isRecurring: $0.isRecurring,
                           skipCount: $0.skipCount,
                           seenCount: $0.seenCount,
                           repeatInterval: $0.repeatInterval,
                           nextTimeInQueue: $0.nextTimeInQueue,
                           folder: $0.folder,
                           isArchived: $0.isArchived,
                           answerRevealed: $0.answerRevealed,
                           skipEnabled: $0.skipEnabled,
                           tags: $0.unwrappedTags.map(\.name))
            }
            
            let updateDate = nextCardEntity?.nextTimeInQueue ?? currentDate.addingTimeInterval(60)
            
            
            if cardsInQueueEntities.isEmpty {
                let entry = allCaughtUpCardEntry(currentDate: currentDate,
                                                 totalNumberOfCards: totalNumberOfCards,
                                                 nextCardForQueue: nextCardEntity,
                                                 configuredTypes: configuration.showCardType,
                                                 selectedCardTypes: configuration.showCardType,
                                                 selectedFolders: configuration.showFolders)
                return Timeline(entries: [entry], policy: .after(updateDate))
            }
            
            
            
            let entry = CardEntry(
                date: currentDate,
                card: cardsInQueueEntities.first!,
                queueCardCount: cardsInQueueEntities.count,
                totalNumberOfCards: totalNumberOfCards,
                nextCardForQueue: nextCardEntity,
                nextUpdateDate: updateDate,
                selectedCardTypes: configuration.showCardType,
                selectedFolders: configuration.showFolders
            )
            return Timeline(entries: [entry], policy:.after(Calendar.current.date(byAdding: .minute, value: 5, to: currentDate) ?? Date()))
        } catch {
            print("Error updating queue: \(error)")
            let entry = errorCardEntry()
            return Timeline(entries: [entry], policy: .never)
        }
    }
}

func noCardTypesSelectedEntry(currentDate: Date, selectedCardTypes: [CardType], selectedFolders: [Folder]) -> CardEntry {
    let dummyCard = Card.makeDummy()
    // Create CardEntity from dummyCard
    let dummyCardEntity = CardEntity(
        id: dummyCard.id,

        createdAt: dummyCard.createdAt,
        cardTypeRaw: dummyCard.cardType.rawValue,
        content: dummyCard.content,
        answer: dummyCard.answer,
        isRecurring: dummyCard.isRecurring,
        skipCount: dummyCard.skipCount,
        seenCount: dummyCard.seenCount,
        repeatInterval: dummyCard.repeatInterval,
        nextTimeInQueue: dummyCard.nextTimeInQueue,
        folder: dummyCard.folder,
        isArchived: dummyCard.isArchived,
        answerRevealed: dummyCard.answerRevealed,
        skipEnabled: dummyCard.skipEnabled,
        tags: nil
    )
    return CardEntry(
        date: currentDate,
        card: dummyCardEntity,
        queueCardCount: 0,
        totalNumberOfCards: 0,
        nextCardForQueue: nil,
        nextUpdateDate: currentDate.addingTimeInterval(3600),
        selectedCardTypes: selectedCardTypes,
        selectedFolders: selectedFolders
    )
}

func allCaughtUpCardEntry(currentDate: Date,
                          totalNumberOfCards: Int,
                          nextCardForQueue: CardEntity?,
                          configuredTypes: [CardType],
                          selectedCardTypes: [CardType],
                          selectedFolders: [Folder]) -> CardEntry {
    let dummyCard = Card.makeDummy()
    // Convert dummyCard to CardEntity
    let dummyCardEntity = CardEntity(
        id: dummyCard.id,
  
        createdAt: dummyCard.createdAt,
        cardTypeRaw: dummyCard.cardType.rawValue,
        content: dummyCard.content,
        answer: dummyCard.answer,
        isRecurring: dummyCard.isRecurring,
        skipCount: dummyCard.skipCount,
        seenCount: dummyCard.seenCount,
        repeatInterval: dummyCard.repeatInterval,
        nextTimeInQueue: dummyCard.nextTimeInQueue,
        folder: dummyCard.folder,
        isArchived: dummyCard.isArchived,
        answerRevealed: dummyCard.answerRevealed,
        skipEnabled: dummyCard.skipEnabled,
        tags: nil
    )
    return CardEntry(
        date: currentDate,
        card: dummyCardEntity,
        queueCardCount: 0,
        totalNumberOfCards: totalNumberOfCards,
        nextCardForQueue: nextCardForQueue,
        nextUpdateDate: nextCardForQueue?.nextTimeInQueue ?? currentDate.addingTimeInterval(3600),
        selectedCardTypes: selectedCardTypes,
        selectedFolders: selectedFolders
    )
}

extension View {
    func widgetBackground(backgroundView: some View) -> some View {
        if #available(iOSApplicationExtension 17.0, *) { // or if #available(iOS 17, *)
            return containerBackground(for: .widget) {
                backgroundView
            }
        } else {
            return background(backgroundView)
        }
    }
}


// MARK: - Button spec

struct WidgetButtonSpec: Identifiable {
    let id = UUID()
    let title: String
    let systemImage: String
    let isPrimary: Bool
    let index: Int
}

struct TopNoteWidgetEntryView: View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var family
    
    var buttonsCount: Int = 4
    
    var body: some View {
        Group {
            if family == .systemSmall {
                SmallWidgetSummaryView(queueCount: entry.queueCardCount,
                                       topCardDate: entry.card.nextTimeInQueue,
                                       currentDate: entry.date,
                                       selectedCardTypes: entry.selectedCardTypes,
                                       selectedFolders: entry.selectedFolders)
            } else {
                // Use a VStack to pin buttons at the bottom and avoid overlap with card content
                VStack(spacing: 0) {
                    // Main content and header at top
                    VStack {
                        ZStack {
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
                            } else {
                                if entry.queueCardCount == 0 {
                                    VStack {
                                        AllCaughtUpWidgetView(
                                            selectedCardTypes: entry.selectedCardTypes,
                                            selectedFolders: entry.selectedFolders,
                                            nextCardDate: entry.nextCardForQueue?.nextTimeInQueue
                                        )
                                    }
                                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                                } else {
                                    VStack(spacing: 4) {
                                        headerRow
                                        
                                        cardContentView(for: entry.card)
                                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                                    }
                                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                                    .padding(.horizontal, 18)
                                    .padding(.top, 14)
                                    .padding(.bottom, 0)
                                }
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    
                    Spacer()
                    
                    // Buttons pinned at bottom with padding and no overlap 
                    if entry.queueCardCount > 0 {
                        cardButtonsView(for: entry.card)
                            .padding(.horizontal, 10)
                            .padding(.bottom, 6)
                    }
                    

                }
                .containerBackground(.clear, for: .widget)
                .widgetURL(URL(string: "topnote://card/\(entry.card.id.uuidString)"))
            }
        }
    }
    
    // MARK: Header (count badge + selected folders + tags)
    private var headerRow: some View {
        HStack(alignment: .center) {
            // Removed selectedCardTypesView to reduce clutter (icons moved to count badge)
            
            VStack(alignment: .leading, spacing: 2) {
                combinedFoldersTagsView
            }
            .font(.caption)
            .lineLimit(1)
            .truncationMode(.tail)
            
            Spacer()
            
            countBadge(count: entry.queueCardCount)
            
        }
        .font(.caption)
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
                .accessibilityLabel(Text("Tags: \(tags.joined(separator: ", "))"))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    // MARK: Updated count badge to show selected card type icons horizontally before count number
    private func countBadge(count: Int) -> some View {
        HStack(spacing: 4) {
            // Show all selected card type icons horizontally
            ForEach(entry.selectedCardTypes, id: \.self) { type in
                Image(systemName: type.iconName)
                    .font(.caption2)
                    .minimumScaleFactor(0.7)
                    .imageScale(.medium)
                    .foregroundColor(.accentColor)
                    .accessibilityLabel(Text(type.rawValue))
            }
            
            Text("\(count)")
                .font(.caption2).bold()
                .minimumScaleFactor(0.7)
                .foregroundColor(.secondary)
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
    
    // Helper for background color based on cardType tintColor with subtle opacity
    private func backgroundColor() -> Color {
        entry.card.cardType.tintColor.opacity(0.10)
    }
    
    // MARK: Card buttons view based on cardType with fixed size buttons and updated logic
    @ViewBuilder
    private func cardButtonsView(for card: CardEntity) -> some View {
        switch card.cardType {
        case .flashcard:
            FlashcardButtonGroup(
                isCardFlipped: card.answerRevealed,
                skipCount: card.skipCount,
                skipEnabled: card.skipEnabled,
                card: card)
        case .todo:
            TodoCardButtonGroup(skipEnabled: card.skipEnabled, card: card)
        case .note:
            NoteCardButtonGroup(skipEnabled: card.skipEnabled, card: card)
        }
    }
    
    // MARK: Card content view simplified to Text replacing ResizableTruncatingText usages

    private func isLongOrMultiline(_ text: String?) -> Bool {
        guard let text else { return false }
        let newlineCount = text.filter { $0 == "\n" }.count
        return newlineCount > 2 || text.count > 280
    }
    
    @ViewBuilder
    private func cardContentView(for card: CardEntity) -> some View {
        switch card.cardType {
        case .flashcard:
            VStack(spacing: 6) {
                if card.answerRevealed {
                    VStack(spacing: 4) {
                        Text(card.content)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(isLongOrMultiline(card.content) ? .leading : .center)
                         
                            .minimumScaleFactor(0.7)
                  
                        
                        Text(card.answer ?? "")
                            .font(.caption)
                            .multilineTextAlignment(isLongOrMultiline(card.answer) ? .leading : .center)
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(maxWidth: .infinity, alignment: .center)
                  
                            .minimumScaleFactor(0.7)
                        
                    }
                } else {
                    Text(card.content)
                        .font(.caption)
                        .multilineTextAlignment(isLongOrMultiline(card.content) ? .leading : .center)
                 
                        .minimumScaleFactor(0.7)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        case .todo:
            Text(card.content)
                .font(.caption)
                .multilineTextAlignment(isLongOrMultiline(card.content) ? .leading : .center)
          
                .minimumScaleFactor(0.7)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        case .note:
            Text(card.content)
                .font(.caption)
                .multilineTextAlignment(isLongOrMultiline(card.content) ? .leading : .center)
          
                .minimumScaleFactor(0.7)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
    }
    
    /// Removed cardFolderTagsView as tags are now included up top
    
}

private func allCaughtUpMessage(for types: [CardType], folders: [Folder]) -> String {
    if types.isEmpty {
        return "No card types selected."
    }
    let typeNames = types.map { $0.rawValue }.joined(separator: ", ")
    if folders.isEmpty {
        return "All caught up for \(typeNames)!"
    } else {
        let folderNames = folders.map(\.name).joined(separator: ", ")
        return "All caught up for \(typeNames) in \(folderNames)!"
    }
}

struct AllCaughtUpWidgetView: View {
    let selectedCardTypes: [CardType]
    let selectedFolders: [Folder]
    let nextCardDate: Date?
    
    var body: some View {
        VStack(spacing: 10) {
            Spacer()
            Image(systemName: "tray.empty")
                .font(.largeTitle)
                .foregroundColor(.gray)
                .accessibilityHidden(true)
            Text(allCaughtUpMessage(for: selectedCardTypes, folders: selectedFolders))
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .accessibilityLabel(Text("All caught up."))
            
            if let nextDate = nextCardDate {
                Text("Next card: \(formattedDate(nextDate))")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .accessibilityLabel(Text("Next card: \(formattedDate(nextDate))"))
            }
            Spacer()
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

struct SmallWidgetSummaryView: View {
    let queueCount: Int
    let topCardDate: Date
    let currentDate: Date
    
    let selectedCardTypes: [CardType]
    let selectedFolders: [Folder]

    var body: some View {
        VStack(spacing: 10) {
            if queueCount == 0 {
                AllCaughtUpWidgetView(selectedCardTypes: selectedCardTypes, selectedFolders: selectedFolders, nextCardDate: nil)
            } else {

                HStack(spacing: 6) {
                    ForEach(selectedCardTypes, id: \.self) { type in
                        Image(systemName: type.iconName)
                            .imageScale(.medium)
                            .foregroundColor(.accentColor)
                            .accessibilityLabel(Text(type.rawValue))
                    }
                    if !selectedFolders.isEmpty {
                        Text(selectedFolders.map(\.name).joined(separator: ", "))
                            .font(.caption)
                            .foregroundColor(.accentColor)
                            .lineLimit(1)
                            .truncationMode(.tail)
                    }
                }
                
                Image(systemName: "tray.full")
                    .font(.largeTitle)
                    .foregroundColor(.accentColor)
                Text("\(queueCount)")
                    .font(.caption).bold()
                    .monospacedDigit()
                    .accessibilityLabel(Text("\(queueCount) cards in queue"))
                Text("\(formatDuration(since: topCardDate, until: currentDate))")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

private func formatDuration(since start: Date, until end: Date) -> String {
    let seconds = Int(end.timeIntervalSince(start))
    if seconds < 60 {
        return "Just now"
    } else if seconds < 3600 {
        let minutes = seconds / 60
        return "\(minutes) min"
    } else if seconds < 86400 {
        let hours = seconds / 3600
        return "\(hours) hr"
    } else if seconds < 604800 {
        let days = seconds / 86400
        return "\(days) day\(days > 1 ? "s" : "")"
    } else {
        let weeks = seconds / 604800
        return "\(weeks) week\(weeks > 1 ? "s" : "")"
    }
}

struct TopNoteWidget: Widget {
    let kind: String = "Top Note Widget"
    
    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: ConfigurationAppIntent.self, provider: Provider()) { entry in
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


// MARK: - Button groups with fixed size buttons and updated logic

private let buttonSize: CGFloat = 36

/// Button group for Note cards:
/// Show only Next if !skipEnabled, else show Next and Skip.
/// Both buttons have the same fixed size.
internal struct NoteCardButtonGroup: View {
    let skipEnabled: Bool
    let card: CardEntity
    
    var body: some View {
        HStack {
            Button(intent: NextCardIntent(card: card)) {
                Image(systemName: "checkmark.rectangle.stack")
                    .font(.callout)
                    .foregroundColor(.blue)
            }
            .frame(width: buttonSize, height: buttonSize)
            .buttonStyle(.plain)
            Spacer()
            
            RecurringMessage(card: card)
            Spacer()
            if skipEnabled {
  
                Button(intent: SkipCardIntent(card: card)) {
                    Image(systemName: "arrow.trianglehead.counterclockwise.rotate.90")
                        .font(.callout)
                        .foregroundColor(.orange)
                }
                .frame(width: buttonSize, height: buttonSize)
                .buttonStyle(.plain)
            }
        }
        .padding(6)
    }
}


/// Button group for Todo cards:
/// Always show Complete and (Next if !skipEnabled, else Skip).
/// Both buttons same size.
internal struct TodoCardButtonGroup: View {
    let skipEnabled: Bool
    let card: CardEntity
    
    var body: some View {
        HStack {
            Button(intent: CompleteTodoIntent(card: card)) {
                Image(systemName: "checkmark.circle")
                    .font(.callout)
                    .foregroundColor(.green)
            }
            .frame(width: buttonSize, height: buttonSize)
            .buttonStyle(.plain)
            
            Spacer()
            
            RecurringMessage(card: card)
            Spacer()
            
            Button(intent: SkipCardIntent(card: card)) {
                Image(systemName:  "arrow.trianglehead.counterclockwise.rotate.90")
                    .font(.callout)
                    .foregroundColor(.orange)
            }
            .frame(width: buttonSize, height: buttonSize)
            .buttonStyle(.plain)
        }
        .padding(6)
    }
}

internal struct RecurringMessage: View {
    let card: CardEntity
    
    var body: some View {
        Group {
            if !card.isRecurring {
                switch card.cardType {
                case .todo:
                    Text("this card will be archived upon complete")
                        .font(.caption2)
                        .minimumScaleFactor(0.7)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.bottom, 4)
                case .flashcard:
                    if card.answerRevealed {
                        Text("this card will be archived when rated")
                            .font(.caption2)
                            .minimumScaleFactor(0.7)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.bottom, 4)
                    } else {
                        Text("this card will be archived when flipped and rated")
                            .font(.caption2)
                            .minimumScaleFactor(0.7)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.bottom, 4)
                    }
                case .note:
                    Text("this card will be archived when Next is tapped")
                        .font(.caption2)
                        .minimumScaleFactor(0.7)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.bottom, 4)
                }
            }
        }
    }
}

/// Button group for Flashcard cards:
/// If not flipped: Flip and (Skip if skipEnabled else Next).
/// If flipped: show all three rating buttons: Easy, Good, Hard.
/// On systemSmall, flipped state buttons shown horizontally with equal square buttons.
/// On other sizes, flipped buttons shown in horizontal row with equal square buttons.
/// (Note: Original code had 3 rating buttons on small, no skip/next on flipped small)
internal struct FlashcardButtonGroup: View {
    let isCardFlipped: Bool
    let skipCount: Int
    let skipEnabled: Bool
    let card: CardEntity
    
    var body: some View {
        if isCardFlipped {
            
                HStack(spacing: 12) {
                    ratingButton(ratingType: .easy, card: card)
                    ratingButton(ratingType: .good, card: card)
                    ratingButton(ratingType: .hard, card: card)
                    Spacer()
                    RecurringMessage(card: card)
                    Spacer()
                    skipOrNextButton()
                }
                .padding(6)
            
        } else {
            // Not flipped: Flip and Skip/Next buttons side by side with fixed size, skip/next at trailing
            HStack(spacing: 12) {
                Button(intent: ShowFlashcardAnswer(card: card)) {
                    Image(systemName: "rectangle.2.swap")
                        .font(.callout)
                        .foregroundColor(.purple)
                }
                .frame(width: buttonSize, height: buttonSize)
                .buttonStyle(.plain)
                
                Spacer()
                
                RecurringMessage(card: card)
                Spacer()
                
                if skipEnabled {
                    Button(intent: SkipCardIntent(card: card)) {
                        Image(systemName: "arrow.trianglehead.counterclockwise.rotate.90")
                            .font(.callout)
                            .foregroundColor(.orange)
                    }
                    .frame(width: buttonSize, height: buttonSize)
                    .buttonStyle(.plain)
                } else {
                    Button(intent: NextCardIntent(card: card)) {
                        Image(systemName: "checkmark.rectangle.stack")
                            .font(.callout)
                            .foregroundColor(.blue)
                    }
                    .frame(width: buttonSize, height: buttonSize)
                    .buttonStyle(.plain)
                }
            }
            .padding(6)
        }
    }
    
    private func ratingButton(ratingType: RatingType, card: CardEntity) -> some View {
        // Rating buttons for Easy, Good, Hard
        // Each button has a fixed size and uses an intent to submit the rating
        // Uses a consistent button style and background for all buttons
        Button(intent: SubmitFlashcardRatingTypeIntent(selectedRating: RatingType.allCases.firstIndex(of: ratingType) ?? 0, card: card)) {
            Image(systemName: ratingType.systemImage)
                .font(.callout)
                .foregroundColor(color(for: ratingType))
        }
        .frame(width: buttonSize, height: buttonSize)
        .buttonStyle(.plain)
    }
    
    private func color(for ratingType: RatingType) -> Color {
        switch ratingType {
        case .easy:
            return .green
        case .good:
            return .blue
        case .hard:
            return .red
        }
    }
    
    private func skipOrNextButton() -> some View {
        if skipEnabled {
            Button(intent: SkipCardIntent(card: card)) {
                Image(systemName: "forward.frame")
                    .font(.callout)
                    .foregroundColor(.orange)
            }
            .frame(width: buttonSize, height: buttonSize)
            .buttonStyle(.plain)
        } else {
            Button(intent: NextCardIntent(card: card)) {
                Image(systemName: "checkmark.rectangle.stack")
                    .font(.callout)
                    .foregroundColor(.blue)
            }
            .frame(width: buttonSize, height: buttonSize)
            .buttonStyle(.plain)
        }
    }
}

extension Card {
    static func makeDummy() -> Card {
        Card(
            createdAt: Date(),
            cardType: .note,
            priorityTypeRaw: .none,
            content: "",
            isRecurring: false,
            skipCount: 0,
            seenCount: 0,
            repeatInterval: 0,
            //isDynamic: false,
            nextTimeInQueue: Date(),
            folder: nil,
            tags: [],
            answer: nil,
            rating: [],
            isArchived: false,
            //answerRevealed: false,
            skipPolicy: .none,
            ratingEasyPolicy: .none,
            ratingMedPolicy: .none,
            ratingHardPolicy: .none
        )
    }
    var isDummy: Bool {
        content.isEmpty && !isRecurring && skipCount == 0 && seenCount == 0 && tags?.isEmpty != false
    }
}




struct NoteCardWidgetView: View {
    let content: String
    let skipEnabled: Bool
    @Environment(\.widgetFamily) var widgetFamily
    
    init(content: String, skipEnabled: Bool) {
        self.content = content
        self.skipEnabled = skipEnabled
    }
    
    private func isLongOrMultiline(_ text: String?) -> Bool {
        guard let text else { return false }
        let newlineCount = text.filter { $0 == "\n" }.count
        return newlineCount > 2 || text.count > 280
    }
    
    var body: some View {
        VStack(spacing: 8) {
            HStack(alignment: .top, spacing: 8) {
                Text(content)
                    .font(.body)
                    .multilineTextAlignment(isLongOrMultiline(content) ? .leading : .center)
                   
                    .minimumScaleFactor(0.7)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Spacer()
            }
        }
        .padding(6)
    }
}

struct TodoCardWidgetView: View {
    let content: String
    @Environment(\.widgetFamily) var widgetFamily
    
    init(content: String) {
        self.content = content
    }
    
    private func isLongOrMultiline(_ text: String?) -> Bool {
        guard let text else { return false }
        let newlineCount = text.filter { $0 == "\n" }.count
        return newlineCount > 2 || text.count > 280
    }
    
    var body: some View {
        VStack(spacing: 8) {
            HStack(alignment: .top, spacing: 8) {
                Text(content)
                    .font(.body)
                    .multilineTextAlignment(isLongOrMultiline(content) ? .leading : .center)
                   
                    .minimumScaleFactor(0.7)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Spacer()
            }
        }
        .padding(6)
    }
}

