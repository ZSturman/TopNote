//
//  SimpleCardImport.swift
//  TopNote
//
//  Created by Zachary Sturman on 11/27/25.
//

import SwiftUI


extension CardFilterOption {
    var asCardType: CardType? {
        switch self {
        case .todo: return .todo
        case .flashcard: return .flashcard
        case .note: return .note
        default: return nil
        }
    }
}

struct SimpleCardImport: Decodable {
    var cardType: String?
    var content: String?
    var answer: String?
}

extension CardType {
    init(caseInsensitiveRawValue: String) {
        let lower = caseInsensitiveRawValue.lowercased()
        self =
            CardType.allCases.first(where: { $0.rawValue.lowercased() == lower }
            ) ?? .todo
    }
}

private struct SortOrderKey: EnvironmentKey {
    static let defaultValue: Bool = true
}

extension EnvironmentValues {
    var ascending: Bool {
        get { self[SortOrderKey.self] }
        set { self[SortOrderKey.self] = newValue }
    }
}
