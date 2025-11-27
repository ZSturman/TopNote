//
//  TagSuggestionsView.swift
//  TopNote
//
//  Created by Zachary Sturman on 11/27/25.
//

import SwiftUI

struct TagSuggestionsView: View {
    let tags: [CardTag]
    let onSelect: (CardTag) -> Void
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: true) {
            LazyVStack(alignment: .leading, spacing: 4) {
                ForEach(tags, id: \.id) { tag in
                    Button(action: {
                        onSelect(tag)
                    }) {
                        Text(tag.name)
                            .font(.footnote)
                            .padding(4)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.blue.opacity(0.1))
                            )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(4)
        }
        .frame(maxHeight: 200)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.systemBackground))
        )
        .shadow(radius: 4)
        .padding(.vertical, 2)
    }
}
