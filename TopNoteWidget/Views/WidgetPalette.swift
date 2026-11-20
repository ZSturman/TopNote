//
//  WidgetPalette.swift
//  TopNoteWidget
//
//  The widget's version of each card kind's look, matching the app.
//

import SwiftUI
import UIKit

enum WidgetPalette {
    static let paper = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.17, green: 0.15, blue: 0.12, alpha: 1)
            : UIColor(red: 0.99, green: 0.96, blue: 0.89, alpha: 1)
    })

    static let ink = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.96, green: 0.92, blue: 0.84, alpha: 1)
            : UIColor(red: 0.20, green: 0.16, blue: 0.10, alpha: 1)
    })

    static func background(for type: CardType) -> some ShapeStyle {
        switch type {
        case .note: AnyShapeStyle(paper)
        case .flashcard, .todo: AnyShapeStyle(type.tintColor.opacity(0.10))
        }
    }

    static func font(for type: CardType, large: Bool) -> Font {
        switch type {
        case .note: .system(large ? .title3 : .subheadline, design: .serif)
        case .flashcard: .system(large ? .title3 : .subheadline, design: .rounded, weight: .semibold)
        case .todo: (large ? Font.title3 : .subheadline).weight(.semibold)
        }
    }
}

/// A labeled capsule button for widget actions.
struct WidgetCapsule: View {
    let title: String
    var systemImage: String? = nil
    let tint: Color
    var prominent = true

    var body: some View {
        HStack(spacing: 4) {
            if let systemImage { Image(systemName: systemImage) }
            Text(title).lineLimit(1).minimumScaleFactor(0.7)
        }
        .font(.caption.weight(.semibold))
        .frame(maxWidth: .infinity, minHeight: 30)
        .padding(.horizontal, 6)
        .foregroundStyle(prominent ? Color.white : tint)
        .background(prominent ? AnyShapeStyle(tint) : AnyShapeStyle(tint.opacity(0.15)), in: Capsule())
    }
}
