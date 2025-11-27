//
//  CardListView+ImportExport.swift
//  TopNote
//
//  Created by Zachary Sturman on 11/27/25.
//

import Foundation
import SwiftUI
import SwiftData

extension CardListView {
    func exportCardsAsJSON(_ cards: [Card]) {
        do {
            let jsonData = try Card.exportCardsToJSON(cards)
            let fileManager = FileManager.default
            if let dir = fileManager.urls(
                for: .documentDirectory,
                in: .userDomainMask
            ).first {
                let fileURL = dir.appendingPathComponent("exported_cards.json")
                try jsonData.write(to: fileURL)
                print("Exported to \(fileURL)")
                exportedFileURL = fileURL
                showShareSheet = true
            }
        } catch {
            print("Export failed: \(error)")
        }
    }
    func exportCardsAsCSV(_ cards: [Card]) {
        do {
            let csvString = try Card.exportCardsToCSV(cards)
            let fileManager = FileManager.default
            if let dir = fileManager.urls(
                for: .documentDirectory,
                in: .userDomainMask
            ).first {
                let fileURL = dir.appendingPathComponent("exported_cards.csv")
                try csvString.write(to: fileURL, atomically: true, encoding: .utf8)
                print("Exported to \(fileURL)")
                exportedFileURL = fileURL
                showShareSheet = true
            }
        } catch {
            print("Export failed: \(error)")
        }
    }
    
    func handleJSONImport(_ result: Result<URL, Error>) {
        print("Importer: Entered fileImporter closure")
        if case .success(let url) = result {
            print("Importer: Attempting to read file at URL:", url)
            do {
                let data = try Data(contentsOf: url)
                print("Importer: Loaded data from", url)
                do {
                    print("Importer: Attempting JSON parse...")
                    let jsonObj =
                        try JSONSerialization.jsonObject(with: data)
                        as? [[String: Any]]
                    print("Importer: Parsed JSON object:", jsonObj as Any)
                    if let dictArray = jsonObj {
                        print(
                            "Importer: Looping through array of card dictionaries (count:",
                            dictArray.count,
                            ")"
                        )
                        for dict in dictArray {
                            print(
                                "Importer: Attempting to make card from dict:",
                                dict
                            )
                            if let card = CardImport.makeCard(from: dict, context: context) {
                                print(
                                    "Importer: Successfully created Card:",
                                    card
                                )
                                context.insert(card)
                            } else {
                                print(
                                    "Importer: Failed to create Card from dict:",
                                    dict
                                )
                            }
                        }
                        print("Importer: Import complete.")
                        showImportSuccessAlert = true
                    }
                } catch {
                    importErrorMessage =
                        "Failed to parse JSON: \(error.localizedDescription)"
                    print("Importer: Import failed with error:", error)
                    #if DEBUG
                        print("Import failed with error: \(error)")
                    #endif
                }
            } catch {
                importErrorMessage =
                    "Failed to load data from file: \(error.localizedDescription)"
                print("Importer: Failed to load data from \(url):", error)
            }
        } else {
            print("Importer: fileImporter result was not success:", result)
        }
    }
    
    func handleCSVImport(_ result: Result<URL, Error>) {
        if case .success(let url) = result {
            do {
                let csvString = try String(contentsOf: url, encoding: .utf8)
                let cards = try CardImport.parseCSV(csvString, context: context)
                for card in cards {
                    context.insert(card)
                }
                showImportSuccessAlert = true
            } catch {
                importErrorMessage = "Failed to import CSV: \(error.localizedDescription)"
            }
        }
    }
}

extension View {
    func importAlerts(
        showImportSuccessAlert: Binding<Bool>,
        importErrorMessage: Binding<String?>
    ) -> some View {
        self
            .alert("Import Successful!", isPresented: showImportSuccessAlert) {
                Button("OK", role: .cancel) {}
            }
            .alert(
                "Import Failed",
                isPresented: .constant(importErrorMessage.wrappedValue != nil)
            ) {
                Button("OK", role: .cancel) { importErrorMessage.wrappedValue = nil }
            } message: {
                Text(importErrorMessage.wrappedValue ?? "Unknown error")
            }
    }
}
