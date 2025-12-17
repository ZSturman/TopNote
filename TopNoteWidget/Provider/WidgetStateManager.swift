//
//  WidgetStateManager.swift
//  TopNote
//
//  Created by Zachary Sturman on 12/13/25.
//

import Foundation

final class WidgetStateManager {
    static let shared = WidgetStateManager()
    private let defaults = UserDefaults(suiteName: "group.com.zacharysturman.topnote")

//    private func textHiddenKey(for widgetID: String, cardID: UUID) -> String {
//        "widget_\(widgetID)_card_\(cardID.uuidString)_textHidden"
//    }

    private func flipStateKey(for widgetID: String, cardID: UUID) -> String {
        "widget_\(widgetID)_card_\(cardID.uuidString)_flipped"
    }

    private func lastCardIDKey(for widgetID: String) -> String {
        "widget_\(widgetID)_lastCardID"
    }

    private func flipTimestampKey(for widgetID: String, cardID: UUID) -> String {
        "widget_\(widgetID)_card_\(cardID.uuidString)_flipTimestamp"
    }
//
//    func isTextHidden(widgetID: String, cardID: UUID) -> Bool {
//        defaults?.bool(forKey: textHiddenKey(for: widgetID, cardID: cardID)) ?? false
//    }
//
//    func setTextHidden(_ hidden: Bool, widgetID: String, cardID: UUID) {
//        defaults?.set(hidden, forKey: textHiddenKey(for: widgetID, cardID: cardID))
//    }

    func isFlipped(widgetID: String, cardID: UUID) -> Bool {
        defaults?.bool(forKey: flipStateKey(for: widgetID, cardID: cardID)) ?? false
    }

    func setFlipped(_ flipped: Bool, widgetID: String, cardID: UUID) {
        defaults?.set(flipped, forKey: flipStateKey(for: widgetID, cardID: cardID))
        if flipped {
            defaults?.set(
                Date().timeIntervalSince1970,
                forKey: flipTimestampKey(for: widgetID, cardID: cardID)
            )
        } else {
            defaults?.removeObject(forKey: flipTimestampKey(for: widgetID, cardID: cardID))
        }
    }

    func getLastCardID(widgetID: String) -> UUID? {
        guard let uuidString = defaults?.string(forKey: lastCardIDKey(for: widgetID)) else { return nil }
        return UUID(uuidString: uuidString)
    }

    func setLastCardID(_ cardID: UUID, widgetID: String) {
        defaults?.set(cardID.uuidString, forKey: lastCardIDKey(for: widgetID))
    }

    func shouldResetFlipState(widgetID: String, cardID: UUID) -> Bool {
        guard let timestamp = defaults?.double(forKey: flipTimestampKey(for: widgetID, cardID: cardID)) else {
            return false
        }
        let flipDate = Date(timeIntervalSince1970: timestamp)
        let elapsed = Date().timeIntervalSince(flipDate)
        return elapsed > 300 // 5 minutes
    }

    func checkAndResetIfNeeded(widgetID: String, currentCardID: UUID) {
        let lastCardID = getLastCardID(widgetID: widgetID)

        if let lastCardID, lastCardID != currentCardID {
            setFlipped(false, widgetID: widgetID, cardID: lastCardID)
            //setTextHidden(false, widgetID: widgetID, cardID: currentCardID)
            setFlipped(false, widgetID: widgetID, cardID: currentCardID)
        } else if lastCardID == nil {
           // setTextHidden(false, widgetID: widgetID, cardID: currentCardID)
            setFlipped(false, widgetID: widgetID, cardID: currentCardID)
        } else if shouldResetFlipState(widgetID: widgetID, cardID: currentCardID) {
            setFlipped(false, widgetID: widgetID, cardID: currentCardID)
        }

        setLastCardID(currentCardID, widgetID: widgetID)
    }
}
