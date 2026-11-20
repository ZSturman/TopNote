//
//  Theme.swift
//  TopNote
//
//  The look of each kind of card. Notes are paper and serif type so they read like something
//  you wrote; flashcards are crisp question cards; to-dos are checklists.
//

import SwiftUI
import UIKit

enum Theme {
    /// Warm paper for notes.
    static let paper = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.17, green: 0.15, blue: 0.12, alpha: 1)
            : UIColor(red: 0.99, green: 0.96, blue: 0.89, alpha: 1)
    })

    /// Faint ruled lines on note paper.
    static let paperRule = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 1, green: 0.85, blue: 0.55, alpha: 0.07)
            : UIColor(red: 0.75, green: 0.55, blue: 0.20, alpha: 0.12)
    })

    static let ink = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.96, green: 0.92, blue: 0.84, alpha: 1)
            : UIColor(red: 0.20, green: 0.16, blue: 0.10, alpha: 1)
    })

    static let cardSurface = Color(uiColor: .secondarySystemGroupedBackground)
    static let screen = Color(uiColor: .systemGroupedBackground)

    static let noteFont = Font.system(.title3, design: .serif)
    static let questionFont = Font.system(.title2, design: .rounded, weight: .semibold)
}

extension CardType {
    /// What this kind of card is for, in a few words.
    var purpose: String {
        switch self {
        case .note: "Ideas, quotes and thoughts that come back to you"
        case .flashcard: "Questions you want to remember, spaced out as you learn"
        case .todo: "Tasks that show up when they're due, synced with Reminders"
        }
    }

    var pluralName: String {
        switch self {
        case .note: "Notes"
        case .flashcard: "Flashcards"
        case .todo: "To-dos"
        }
    }

    var capturePrompt: String {
        switch self {
        case .note: "What do you want to remember?"
        case .flashcard: "Question"
        case .todo: "What needs doing?"
        }
    }

    /// A filled symbol for prominent places.
    var filledSymbol: String {
        switch self {
        case .note: "text.quote"
        case .flashcard: "rectangle.on.rectangle.angled.fill"
        case .todo: "checkmark.circle.fill"
        }
    }
}

extension RatingType {
    /// What a rating means, in the reader's own words.
    var meaning: String {
        switch self {
        case .hard: "Didn't know it"
        case .good: "Knew it"
        case .easy: "Knew it instantly"
        }
    }
}

/// A small capsule label, used for card kinds and strength.
struct Pill: View {
    let text: String
    var systemImage: String? = nil
    var tint: Color = .secondary

    var body: some View {
        HStack(spacing: 4) {
            if let systemImage { Image(systemName: systemImage) }
            Text(text).lineLimit(1)
        }
        .font(.caption.weight(.semibold))
        .padding(.horizontal, 9)
        .padding(.vertical, 4)
        .foregroundStyle(tint)
        .background(tint.opacity(0.13), in: Capsule())
    }
}

/// Three bars that fill as a flashcard gets stronger.
struct StrengthMeter: View {
    let strength: CardStrength

    var body: some View {
        HStack(spacing: 6) {
            HStack(spacing: 2) {
                ForEach(1...3, id: \.self) { index in
                    Capsule()
                        .fill(index <= strength.bars ? CardType.flashcard.tintColor : Color.secondary.opacity(0.25))
                        .frame(width: 10, height: 4)
                }
            }
            Text(strength.title)
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .fixedSize()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Strength: \(strength.title)")
    }
}

/// The fanned cards from the app icon: a note, a to-do and a flashcard.
struct CardFanMark: View {
    var fanned = true
    var size: CGFloat = 120

    var body: some View {
        ZStack {
            card(Color(red: 0.36, green: 0.78, blue: 0.42), rotation: fanned ? 14 : 0, offset: CGSize(width: fanned ? size * 0.16 : 0, height: fanned ? -size * 0.14 : 0))
            card(Color(red: 0.98, green: 0.78, blue: 0.25), rotation: fanned ? -9 : 0, offset: CGSize(width: fanned ? -size * 0.10 : 0, height: fanned ? -size * 0.08 : 0))
            card(CardType.flashcard.tintColor, rotation: 0, offset: CGSize(width: 0, height: fanned ? size * 0.06 : 0), lines: true)
        }
        .frame(width: size * 1.3, height: size)
        .accessibilityHidden(true)
    }

    private func card(_ color: Color, rotation: Double, offset: CGSize, lines: Bool = false) -> some View {
        RoundedRectangle(cornerRadius: size * 0.08, style: .continuous)
            .fill(.white)
            .overlay(alignment: .top) {
                UnevenRoundedRectangle(topLeadingRadius: size * 0.08, topTrailingRadius: size * 0.08, style: .continuous)
                    .fill(color)
                    .frame(height: size * 0.2)
            }
            .overlay(alignment: .topLeading) {
                if lines {
                    VStack(alignment: .leading, spacing: size * 0.055) {
                        Capsule().fill(color.opacity(0.85)).frame(width: size * 0.62, height: size * 0.04)
                        Capsule().fill(color.opacity(0.85)).frame(width: size * 0.62, height: size * 0.04)
                        Capsule().fill(color.opacity(0.85)).frame(width: size * 0.3, height: size * 0.04)
                    }
                    .padding(.top, size * 0.27)
                    .padding(.leading, size * 0.08)
                }
            }
            .frame(width: size * 0.82, height: size * 0.55)
            .shadow(color: .black.opacity(0.18), radius: size * 0.05, y: size * 0.03)
            .rotationEffect(.degrees(rotation))
            .offset(offset)
    }
}
