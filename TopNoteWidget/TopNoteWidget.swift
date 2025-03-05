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
            return Timeline(entries: [entry], policy:.after(Date().addingTimeInterval(60 * 5)))
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
   
    var backlogColor: Color {
        if entry.queueCardCount < 3 {
            return .primary
        } else if entry.queueCardCount < 8 {
            return .yellow
        } else if entry.queueCardCount < 15 {
            return .orange
        } else {
            return .red
        }
    }

    var body: some View {
            Link(destination: entry.card.url) {
                if entry.queueCardCount == 0 {
                    Text("All caught up!")
                } else {
                    GeometryReader { geo in
                        VStack(alignment: .leading) {
                            HStack {
                                cardFolder(for: entry.card)
                                cardTags(for: entry.card)
                                Spacer()
                                HStack(spacing: 0) {
                                    Spacer()
                                    Image(systemName: "square.3.layers.3d")
                                    Text("\(entry.queueCardCount)")
                                }
                                .foregroundColor(backlogColor)
                            }
                            
                            .font(.caption)
                            .lineLimit(1)
                            .opacity(0.7)
                            .frame(height: geo.size.height * 0.01)
                            cardContentView(for: entry.card)
                        }
                    }
                
                
                
            }

        }
    }
    
    @ViewBuilder
    private func cardTags(for card: Card) -> some View {
        if family != .systemSmall {
            HStack {
                ForEach(entry.card.tags ?? []) { tag in
                    Text(tag.name)
                        .lineLimit(1)
                }
            }
        }
    }

    
    @ViewBuilder
    private func cardFolder(for card: Card) -> some View {
        if family != .systemSmall {
            if entry.card.folder != nil {
                HStack {
                    Text("[\(entry.card.folder?.name ?? "")]")
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
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .containerBackground(.fill.tertiary, for: .widget)
                
        }
        .configurationDisplayName("Top Note Widget")
        .description("Displays a card from your collection.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
      
    }
}

struct TopNoteWidgetEntryView_Previews: PreviewProvider {
    // Helper function to wrap a Card into a CardEntry for preview purposes.
    private static func sampleEntry(for family: WidgetFamily, with card: Card) -> CardEntry {
        return CardEntry(
            date: Date(),
            card: card,
            queueCardCount: 30,
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
                .previewDisplayName("Top Note Widget - FlashCard")
    
            
            TopNoteWidgetEntryView(entry: sampleEntry(for: .systemMedium, with: getSampleNoTypeCard()) )
                .containerBackground(.fill.tertiary, for: .widget)
                .previewContext(WidgetPreviewContext(family: .systemMedium))
                .previewDisplayName("Top Note Widget -Plain")
            
        }
    }
}
