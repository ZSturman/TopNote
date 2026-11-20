//
//  TopNoteControls.swift
//  TopNoteWidget
//
//  Control Center, Lock Screen and Action button controls.
//

import WidgetKit
import SwiftUI
import AppIntents

struct CaptureControl: ControlWidget {
    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: "com.zacharysturman.topnote.capture") {
            ControlWidgetButton(action: OpenCaptureIntent()) {
                Label("New Card", systemImage: "plus.rectangle.on.rectangle")
            }
        }
        .displayName("New Top Note Card")
        .description("Capture a note, flashcard or to-do.")
    }
}

struct UpNextControl: ControlWidget {
    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: "com.zacharysturman.topnote.upnext") {
            ControlWidgetButton(action: OpenUpNextIntent()) {
                Label("Up Next", systemImage: "rectangle.stack.fill")
            }
        }
        .displayName("Top Note Up Next")
        .description("Open the card that matters right now.")
    }
}
