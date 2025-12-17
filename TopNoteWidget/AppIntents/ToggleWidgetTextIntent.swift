////
////  ToggleWidgetTextIntent.swift
////  TopNote
////
////  Created by Zachary Sturman on 12/13/25.
////
//
//import WidgetKit
//import AppIntents
//
//struct ToggleWidgetTextIntent: AppIntent {
//    static var title: LocalizedStringResource = "Toggle Widget Text"
//
//    @Parameter(title: "Card")
//    var card: CardEntity
//
//    @Parameter(title: "Widget ID")
//    var widgetID: String
//
//    init(card: CardEntity, widgetID: String) {
//        self.card = card
//        self.widgetID = widgetID
//    }
//
//    init() {}
//
//    func perform() async throws -> some IntentResult {
//        let currentState = WidgetStateManager.shared.isTextHidden(widgetID: widgetID, cardID: card.id)
//        WidgetStateManager.shared.setTextHidden(!currentState, widgetID: widgetID, cardID: card.id)
//
//        WidgetCenter.shared.reloadAllTimelines()
//        return .result()
//    }
//}
