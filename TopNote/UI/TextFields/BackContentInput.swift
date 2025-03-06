//
//  BackContentInput.swift
//  TopNote
//
//  Created by Zachary Sturman on 2/27/25.
//

import Foundation
import SwiftUI
import WidgetKit

struct BackContentInput: View {
    var card: Card
    @State private var backContent: String

    // Accept the parent's focus state binding directly
    let focusedField: FocusState<FormField?>.Binding

    init(card: Card, focusedField: FocusState<FormField?>.Binding) {
        self.card = card
        _backContent = State(initialValue: card.back ?? "")
        self.focusedField = focusedField
    }
    
    var body: some View {
        Section {
            ZStack(alignment: .topLeading) {
                if backContent.isEmpty {
                    Text("Enter your content here...")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .padding(.top, 8)
                        .padding(.leading, 5)
                }
                TextEditor(text: $backContent)
                    .font(.subheadline)
                    .padding(4)
            }
            .frame(minHeight: 100)
            .focused(focusedField, equals: .content)
            .onChange(of: backContent) {
                card.back = backContent
                WidgetCenter.shared.reloadAllTimelines()
            }
        
        }
    }
}
