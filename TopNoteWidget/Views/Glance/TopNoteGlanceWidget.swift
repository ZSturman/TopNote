//
//  TopNoteGlanceWidget.swift
//  TopNoteWidget
//
//  Lock Screen and StandBy: how many cards are ready, and the next one.
//

import WidgetKit
import SwiftUI
import SwiftData
import AppIntents

struct GlanceEntry: TimelineEntry {
    let date: Date
    let count: Int
    let nextTitle: String?
    let nextType: CardType?
    let nextDue: Date?
}

struct GlanceProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> GlanceEntry {
        GlanceEntry(date: Date(), count: 3, nextTitle: "What is the capital of Australia?", nextType: .flashcard, nextDue: nil)
    }

    func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> GlanceEntry {
        context.isPreview ? placeholder(in: context) : await entry(for: configuration)
    }

    func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<GlanceEntry> {
        let entry = await entry(for: configuration)
        let refresh = entry.count > 0 ? Date().addingTimeInterval(15 * 60) : (entry.nextDue ?? Date().addingTimeInterval(3600))
        return Timeline(entries: [entry], policy: .after(refresh))
    }

    @MainActor
    private func entry(for configuration: ConfigurationAppIntent) -> GlanceEntry {
        let now = Date()
        let context = ModelContext(sharedModelContainer)
        let types = Set(configuration.showCardType)
        let folderIDs = Set(configuration.showFolders.map(\.id))
        let includesNoFolder = configuration.showFolders.contains(where: \.isNoFolderSentinel)
        let cards = ((try? context.fetch(FetchDescriptor<Card>(predicate: #Predicate { $0.deletedAt == nil && $0.isArchived == false }))) ?? [])
            .filter { card in
                guard types.isEmpty || types.contains(card.cardType) else { return false }
                guard !folderIDs.isEmpty else { return true }
                if let folder = card.folder { return folderIDs.contains(folder.id) }
                return includesNoFolder
            }
        let ready = cards.filter { $0.nextTimeInQueue <= now }
            .sorted { ($0.priority.sortValue, $0.nextTimeInQueue) < ($1.priority.sortValue, $1.nextTimeInQueue) }
        let upcoming = cards.filter { $0.nextTimeInQueue > now }.min { $0.nextTimeInQueue < $1.nextTimeInQueue }
        let next = ready.first
        return GlanceEntry(
            date: now,
            count: ready.count,
            nextTitle: next.map { $0.content.split(whereSeparator: \.isNewline).first.map(String.init) ?? $0.content },
            nextType: next?.cardType,
            nextDue: upcoming?.nextTimeInQueue
        )
    }
}

struct GlanceView: View {
    let entry: GlanceEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        switch family {
        case .accessoryCircular:
            ZStack {
                AccessoryWidgetBackground()
                VStack(spacing: 0) {
                    Text("\(entry.count)")
                        .font(.title2.weight(.bold))
                        .monospacedDigit()
                    Image(systemName: "rectangle.stack.fill")
                        .font(.caption2)
                }
            }
            .accessibilityLabel("\(entry.count) cards ready in Top Note")
        case .accessoryInline:
            if entry.count > 0 {
                Label("\(entry.count) ready · \(entry.nextTitle ?? "")", systemImage: "rectangle.stack.fill")
            } else {
                Label("All caught up", systemImage: "checkmark.seal")
            }
        default:
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Image(systemName: entry.nextType?.systemImage ?? "checkmark.seal")
                    Text(entry.count > 0 ? "TOP NOTE · \(entry.count) READY" : "TOP NOTE")
                        .font(.caption2.weight(.bold))
                }
                .widgetAccentable()
                if let title = entry.nextTitle {
                    Text(title)
                        .font(.headline)
                        .lineLimit(2)
                } else {
                    Text("All caught up")
                        .font(.headline)
                    if let due = entry.nextDue {
                        Text("Next \(due, style: .relative)")
                            .font(.caption)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

struct TopNoteGlanceWidget: Widget {
    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: TopNoteShared.WidgetKind.glance, intent: ConfigurationAppIntent.self, provider: GlanceProvider()) { entry in
            GlanceView(entry: entry)
                .containerBackground(.clear, for: .widget)
                .widgetURL(TopNoteRoute.upNext(nil).url)
        }
        .configurationDisplayName("Ready Now")
        .description("How many cards are ready, and the next one.")
        .supportedFamilies([.accessoryRectangular, .accessoryCircular, .accessoryInline, .systemSmall])
    }
}
