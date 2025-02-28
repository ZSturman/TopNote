//
//  FlashCardWidget.swift
//  FlashCardWidget
//
//  Created by Zachary Sturman on 2/17/25.
//

import WidgetKit
import SwiftUI
import SwiftData
import AppIntents

struct Provider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> CardEntry {
        placeholderCardEntry()
    }
    
    func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> CardEntry {
        return sampleCardEntry()
    }
    
    
    func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<CardEntry> {
        let currentDate = Date()
        guard let container = try? ModelContainer(for: Card.self) else {
            return Timeline(entries: [], policy: .never)
        }
        let modelContext = ModelContext(container)
        let queueManager = QueueManager(context: modelContext)
        
        do {
            let (cardsInQueue, nextCardForQueue, totalNumberOfCards) = try queueManager.fetchQueueCards(currentDate: currentDate, configuration: configuration)
            
            let updateDate = nextCardForQueue?.nextTimeInQueue ?? currentDate.addingTimeInterval(60)
            
            
            if cardsInQueue.isEmpty {
                let entry = allCaughtUpCardEntry(currentDate: currentDate,
                                                 totalNumberOfCards: totalNumberOfCards,
                                                 nextCardForQueue: nextCardForQueue)
                return Timeline(entries: [entry], policy: .after(updateDate))
            }
            

            
            let entry = CardEntry(
                date: currentDate,
                card: cardsInQueue.first!,
                queueCardCount: cardsInQueue.count,
                totalNumberOfCards: totalNumberOfCards,
                nextCardForQueue: nextCardForQueue,
                nextUpdateDate: updateDate
            )
            return Timeline(entries: [entry], policy: .after(updateDate))
        } catch {
            print("Error updating queue: \(error)")
            let entry = errorCardEntry()
            return Timeline(entries: [entry], policy: .never)
        }
    }
}


struct TopNoteWidgetEntryView: View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var family

    private let customDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        // "dd" = day, "MM" = month, "HH" = 24-hour, "mm" = minutes
        formatter.dateFormat = "dd/MM HH:mm"
        return formatter
    }()

    var body: some View {
        ZStack(alignment: .topLeading) {
            Link(destination: entry.card.url) {
                if entry.queueCardCount == 0 {
                    Text("All caught up!")
                } else {
                    GeometryReader { geo in
                        VStack(alignment: .leading) {
                            HStack {
                                cardPriority(for: entry.card)
                                    .font(.caption2)
                                Spacer()
                                HStack(spacing: 0) {
                                    Spacer()
                                    Image(systemName: "square.3.layers.3d")
                                    Text("\(entry.queueCardCount)")
                                }
                            }
                            .font(.caption2)
                            .frame(height: geo.size.height * 0.01)
                            //debugTimeline()
                            
                            cardContentView(for: entry.card)
                            
                            widgetFooter()
                            
                        }
                        //.padding(8)
                    }
                }
            }
        }
    }

    
    @ViewBuilder
    private func widgetFooter() -> some View {
        if family != .systemSmall {
            if entry.card.folder != nil {
                HStack {
                    Spacer()
                    Text(entry.card.folder?.name ?? "")
                        .font(.caption)
                }
            }
        }
    }
    
    @ViewBuilder
    private func debugTimeline() -> some View {
        if family != .systemSmall {
            VStack {
                Spacer()
                // New fields displaying update times
                Text("Updated: \(customDateFormatter.string(from: entry.date))")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Text("Next: \(customDateFormatter.string(from: entry.nextUpdateDate))")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    @ViewBuilder
    private func cardPriority(for card: Card) -> some View {
        switch card.priority {
        case .none:
            Text("")
        case .low:
            Image(systemName: "staroflife.fill")
        case .med:
            HStack {
                Image(systemName: "staroflife.fill")
                Image(systemName: "staroflife.fill")
            }
        case .high:
            HStack {
                Image(systemName: "staroflife.fill")
                Image(systemName: "staroflife.fill")
                Image(systemName: "staroflife.fill")
            }
        }
    }
    
    @ViewBuilder
    private func cardContentView(for card: Card) -> some View {
        switch card.cardType {
        case .flashCard:
            FlashCardWidgetView(front: card.content, back: card.back ?? "No back side", isCardFlipped: card.hasBeenFlipped, isEssential: card.isEssential)
        case .none:
            NoCardTypeWidgetView(content: card.content, isEssential: card.isEssential)
        }
    }
}

struct TopNoteWidget: Widget {
    let kind: String = "Top Note Widget"
    
    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: ConfigurationAppIntent.self, provider: Provider()) { entry in
            TopNoteWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Top Note Widget")
        .description("Displays a card from your collection.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge, .systemExtraLarge])
    }
}

struct TopNoteWidgetEntryView_Previews: PreviewProvider {
    // Helper function to wrap a Card into a CardEntry for preview purposes.
    private static func sampleEntry(for family: WidgetFamily, with card: Card) -> CardEntry {
        return CardEntry(
            date: Date(),
            card: card,
            queueCardCount: 1,
            totalNumberOfCards: 10,
            nextCardForQueue: nil,
            nextUpdateDate: Date()
        )
    }
    
    static var previews: some View {
        Group {
            TopNoteWidgetEntryView(entry: sampleEntry(for: .systemSmall, with: getSampleFlashCard(hasBeenFlipped: false)))
                .containerBackground(.fill.tertiary, for: .widget)
                .previewContext(WidgetPreviewContext(family: .systemSmall))
                .previewDisplayName("Top Note Widget - FlashCard (Small, Not Flipped)")
            
            TopNoteWidgetEntryView(entry: sampleEntry(for: .systemSmall, with: getSampleFlashCard(hasBeenFlipped: true)))
                .containerBackground(.fill.tertiary, for: .widget)
                .previewContext(WidgetPreviewContext(family: .systemSmall))
                .previewDisplayName("Top Note Widget - FlashCard (Small, Flipped)")
            
            TopNoteWidgetEntryView(entry: sampleEntry(for: .systemMedium, with: getSampleFlashCard(hasBeenFlipped: false)))
                .containerBackground(.fill.tertiary, for: .widget)
                .previewContext(WidgetPreviewContext(family: .systemMedium))
                .previewDisplayName("Top Note Widget - Quiz (Medium)")
            
            TopNoteWidgetEntryView(entry: sampleEntry(for: .systemLarge, with: getSampleFlashCard(hasBeenFlipped: true)))
                .containerBackground(.fill.tertiary, for: .widget)
                .previewContext(WidgetPreviewContext(family: .systemMedium))
                .previewDisplayName("Top Note Widget - ToDo (Large)")
        }
    }
}
