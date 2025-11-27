//
//  CardDetailsView+Helpers.swift
//  TopNote
//
//  Created by Zachary Sturman on 11/27/25.
//

import Foundation
import SwiftUI

extension CardDetailView {



    func exportCurrentCard() {
        do {
            let jsonData = try Card.exportCardsToJSON([card])
            let fileManager = FileManager.default
            if let dir = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first {
                let fileURL = dir.appendingPathComponent("exported_card.json")
                try jsonData.write(to: fileURL)
                exportedFileURL = fileURL
                showShareSheet = true
            }
        } catch {
            print("Export failed: \(error)")
        }
    }


    func deleteCard() {
        context.delete(card)
        try? context.save()
        dismiss()
    }

    var toolbarContent: some ToolbarContent {
        Group {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") { dismiss() }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button { exportCurrentCard() } label: {
                    Label("Export", systemImage: "square.and.arrow.up")
                }
                .accessibilityLabel("Export this card")
            }
        }
    }
}
