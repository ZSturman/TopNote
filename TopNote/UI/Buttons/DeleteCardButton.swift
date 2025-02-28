//
//  DeleteCardButton.swift
//  TopNote
//
//  Created by Zachary Sturman on 2/24/25.
//

import Foundation
import SwiftUI
import SwiftData

struct DeleteCardButton: View {
    @Environment(\.modelContext) private var modelContext
    var card: Card
    
    var body: some View {
        Button(action: {
            modelContext.delete(card)
        }, label: {
            VStack {
                Image(systemName: "trash")
                //Text("Delete")
            }
        })
        .help("Delete")
    }
}
