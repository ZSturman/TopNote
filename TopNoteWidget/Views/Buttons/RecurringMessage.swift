//
//  RecurringMessage.swift
//  TopNote
//
//  Created by Zachary Sturman on 12/13/25.
//

import SwiftUI

struct RecurringMessage: View {
    let card: CardEntity

    var body: some View {
        Group {
            if !card.isRecurring {
                switch card.cardType {
                case .todo:
                    Text("this card will be archived upon complete")
                        .font(.caption2)
                        .minimumScaleFactor(0.7)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.bottom, 4)

                case .flashcard:
                    if card.answerRevealed {
                        Text("this card will be archived when rated")
                            .font(.caption2)
                            .minimumScaleFactor(0.7)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.bottom, 4)
                    } else {
                        Text("this card will be archived when flipped and rated")
                            .font(.caption2)
                            .minimumScaleFactor(0.7)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.bottom, 4)
                    }

                case .note:
                    Text("this card will be archived when Next is tapped")
                        .font(.caption2)
                        .minimumScaleFactor(0.7)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.bottom, 4)
                }
            }
        }
    }
}
