//
//  ContentInput.swift
//  TopNote
//
//  Created by Zachary Sturman on 2/27/25.
//

import Foundation
import SwiftUI
import WidgetKit

struct ContentInput: View {
    var card: Card
    @State private var content: String
    let focusedField: FocusState<FormField?>.Binding
    @FocusState private var isTextEditorFocused: Bool
    
    

    init(card: Card, focusedField: FocusState<FormField?>.Binding) {
        self.card = card
        _content = State(initialValue: card.content)
        self.focusedField = focusedField
    }

    var body: some View {
        Section {
            ZStack(alignment: .topLeading) {
                if content.isEmpty {
                    Text("Enter your content here...")
                        .foregroundColor(.gray)
                        .padding(.top, 8)
                        .padding(.leading, 5)
                }
                TextEditor(text: $content)
                    .padding(4)
            }
            .frame(minHeight: 100)
            .focused(focusedField, equals: .content)
            .onChange(of: content) {
                card.content = content
                WidgetCenter.shared.reloadAllTimelines()
            }
        
        }
        
        
//        Section {
//            ZStack(alignment: .topLeading) {
//                if content.isEmpty && !isTextEditorFocused {
//                    Text("Enter your content here...")
//                        .foregroundColor(.gray)
//                        .padding(.top, 8)
//                        .padding(.leading, 5)
//                }
//
//                TextEditor(text: $content)
//                    .padding(4)
//                    .focused($isTextEditorFocused)
//                    .onChange(of: content) {
//                        card.content = content
//                    }
//                    .opacity(isTextEditorFocused ? 1 : 0) // Hide editor when not focused
//
//                if !isTextEditorFocused {
//                    Text(detectLinks(in: content))
//                        .padding(8)
//                        .frame(maxWidth: .infinity, alignment: .leading)
//                        .background(Color.clear)
//
//                }
//            }
//            .frame(minHeight: 100)
//            .focused(focusedField, equals: .content)
//
//        }
//        .onTapGesture {
//            isTextEditorFocused = true
//            focusedField.wrappedValue = .content
//        }
    }

    private func detectLinks(in text: String) -> AttributedString {
           var attributedString = AttributedString(text)
           
           let urlRegex = try! NSRegularExpression(
               pattern: #"(https?|ftp|file|mailto):\/\/[^\s/$.?#].[^\s]*|www\.[^\s/$.?#].[^\s]*|[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}(\/\S*)?"#,
               options: []
           )

           let matches = urlRegex.matches(
               in: text,
               options: [],
               range: NSRange(location: 0, length: text.utf16.count)
           )

           for match in matches {
               if let range = Range(match.range, in: text) {
                   let urlString = String(text[range])
                   
                   // Ensure the URL has a proper scheme
                   let formattedURLString = urlString.hasPrefix("http") || urlString.hasPrefix("ftp") || urlString.hasPrefix("mailto") || urlString.hasPrefix("file")
                       ? urlString
                       : "https://" + urlString
                   
                   if let url = URL(string: formattedURLString) {
                       let attrRange = attributedString.range(of: urlString)
                       if let attrRange = attrRange {
                           attributedString[attrRange].link = url
                           attributedString[attrRange].foregroundColor = .blue
                           attributedString[attrRange].underlineStyle = .single
                       }
                   }
               }
           }
           return attributedString
       }
}
