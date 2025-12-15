//
//  AllCaughtUpWidgetView.swift
//  TopNote
//
//  Created by Zachary Sturman on 12/13/25.
//

import SwiftUI

struct AllCaughtUpWidgetView: View {
    let selectedCardTypes: [CardType]
    let selectedFolders: [Folder]
    let nextCardDate: Date?

    var body: some View {
        VStack(spacing: 10) {
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

    private func allCaughtUpMessage(for types: [CardType], folders: [Folder]) -> String {
        if types.isEmpty {
            return "No card types selected."
        }
        let typeNames = types.map { "\($0.rawValue)s" }.joined(separator: ", ")
        if folders.isEmpty {
            return "All caught up for \(typeNames)!"
        } else {
            let folderNames = folders.map(\.name).joined(separator: ", ")
            return "All caught up for \(typeNames) in \(folderNames)!"
        }
    }
}
