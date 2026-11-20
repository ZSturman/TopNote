//
//  SmallWidgetSummaryView.swift
//  TopNoteWidget
//
//  The small widget shows the next card itself; tap it to handle it in the app.
//

import SwiftUI
import WidgetKit

struct SmallWidgetSummaryView: View {
    let entry: CardEntry

    var body: some View {
        let card = entry.card
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: card.cardType.systemImage)
                    .foregroundStyle(card.cardType.tintColor)
                Spacer()
                Text("\(entry.queueCardCount)")
                    .font(.caption.weight(.bold))
                    .monospacedDigit()
                    .padding(.horizontal, 7)
                    .padding(.vertical, 2)
                    .background(card.cardType.tintColor.opacity(0.18), in: Capsule())
                    .accessibilityLabel("\(entry.queueCardCount) ready")
            }
            .font(.subheadline)
            Text(card.content)
                .font(WidgetPalette.font(for: card.cardType, large: false))
                .foregroundStyle(card.cardType == .note ? WidgetPalette.ink : .primary)
                .lineLimit(5)
                .minimumScaleFactor(0.7)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            Text(card.cardType == .flashcard ? "Tap to answer" : card.cardType == .todo ? "Tap to check off" : "Tap to read")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(14)
    }
}
