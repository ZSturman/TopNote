//
//  TopNoteWidget.swift
//  TopNoteWidget
//

import WidgetKit
import SwiftUI
import AppIntents

struct TopNoteWidget: Widget {
    let kind: String = TopNoteShared.WidgetKind.card

    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: ConfigurationAppIntent.self,
            provider: Provider()
        ) { entry in
            TopNoteWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Up Next")
        .description("Your next note, flashcard or to-do. Flip, rate, check off or skip it right here.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge, .systemExtraLarge])
        .contentMarginsDisabled()
    }
}
