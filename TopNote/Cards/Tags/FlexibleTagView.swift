//
//  FlexibleTagView.swift
//  TopNote
//
//  Created by Zachary Sturman on 11/27/25.
//

import SwiftUI

struct FlexibleTagView: View {
    let tags: [CardTag]

    var body: some View {
        // Wrap tags in flexible layout
        FlexibleView(data: tags, spacing: 8, alignment: .leading) { tag in
            Text(tag.name)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.blue.opacity(0.2))
                .foregroundColor(.blue)
                .clipShape(Capsule())
                .accessibilityLabel("Tag: \(tag.name)")
        }
    }
}
