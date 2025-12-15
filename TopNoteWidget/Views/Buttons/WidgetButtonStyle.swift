//
//  WidgetButtonStyle.swift
//  TopNote
//
//  Created by Zachary Sturman on 12/13/25.
//

import SwiftUI

struct WidgetButtonSpec: Identifiable {
    let id = UUID()
    let title: String
    let systemImage: String
    let isPrimary: Bool
    let index: Int
}

struct WidgetButtonStyle: ButtonStyle {
    let color: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.85 : 1.0)
            .opacity(configuration.isPressed ? 0.7 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

let buttonSize: CGFloat = 32
