//
//  CardDetailView+Events.swift
//  TopNote
//
//  Created by Zachary Sturman on 11/27/25.
//

import Foundation
import SwiftUI

struct MergedEvent: Identifiable {
    enum EventType {
        case enqueue, skip, removal

        var iconName: String {
            switch self {
            case .enqueue: return "clock.arrow.circlepath"
            case .skip: return "arrow.triangle.2.circlepath"
            case .removal: return "trash"
            }
        }

        var tintColor: Color {
            switch self {
            case .enqueue: return .blue
            case .skip: return .orange
            case .removal: return .red
            }
        }

        var label: String {
            switch self {
            case .enqueue: return "Enqueued"
            case .skip: return "Skipped"
            case .removal: return "Removed"
            }
        }
    }

    let id = UUID()
    let date: Date
    let type: EventType

    var iconName: String { type.iconName }
    var tintColor: Color { type.tintColor }
    var label: String { type.label }
}
