//
//  AddNiceToSeeCard.swift
//  TopNote
//
//  Created by Zachary Sturman on 2/18/25.
//

import Foundation
import SwiftUI

struct NoCardTypeForm: View {
    @Environment(\.modelContext) private var modelContext
    
    var card: Card

    var body: some View {
        Form {
            Section(header: Text("Content")) {
                TextField("Enter content", text: Binding(
                    get: { card.content },
                    set: { newValue in
                        card.content = newValue
                        try? modelContext.save()
                    }
                ))
            }
        }
    }
}
