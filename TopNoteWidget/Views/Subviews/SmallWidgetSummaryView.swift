//
//  SmallWidgetSummaryView.swift
//  TopNote
//
//  Created by Zachary Sturman on 12/13/25.
//

import SwiftUI
import WidgetKit

struct SmallWidgetSummaryView: View {
    let queueCount: Int
    let topCardDate: Date
    let currentDate: Date

    let selectedCardTypes: [CardType]
    let selectedFolders: [Folder]

    var body: some View {
        VStack(spacing: 10) {
            if queueCount == 0 {
                HStack {
                    ForEach(selectedCardTypes, id: \.self) { type in
                        Image(systemName: type.systemImage)
                            .imageScale(.medium)
                            .foregroundColor(.secondary)
                            .accessibilityLabel(Text(type.rawValue))
                    }
                }

                AllCaughtUpWidgetView(
                    selectedCardTypes: selectedCardTypes,
                    selectedFolders: selectedFolders,
                    nextCardDate: nil
                )
            } else {
                HStack(spacing: 6) {
                    ForEach(selectedCardTypes, id: \.self) { type in
                        Image(systemName: type.systemImage)
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
}
