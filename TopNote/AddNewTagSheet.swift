//
//  AddNewTagSheet.swift
//  TopNote
//
//  Created by Zachary Sturman on 8/6/25.
//

import Foundation
import SwiftUI
import SwiftData
import WidgetKit


struct AddNewTagSheet: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    var card: Card
    @State private var newTagName: String = ""
    @Query var tags: [CardTag]

    var filteredSortedTags: [CardTag] {
        let filtered: [CardTag]
        let trimmed = newTagName.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            filtered = tags
        } else {
            filtered = tags.filter { $0.name.range(of: trimmed, options: .caseInsensitive) != nil }
        }
        return filtered.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                TextField("New tag name", text: $newTagName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                Button("Add") {
                    let trimmed = newTagName.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !trimmed.isEmpty,
                          !tags.contains(where: { $0.name.caseInsensitiveCompare(trimmed) == .orderedSame }) else { return }
                    let newTag = CardTag(name: trimmed)
                    context.insert(newTag)
                    if card.tags == nil { card.tags = [] }
                    card.tags?.append(newTag)
                    try? context.save()
                    WidgetCenter.shared.reloadAllTimelines()
                    newTagName = ""
                }
                .disabled(newTagName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                          tags.contains(where: { $0.name.caseInsensitiveCompare(newTagName) == .orderedSame }))
            }
            .padding([.horizontal, .top])

            ScrollView(.vertical) {
                CardTagFlowLayout(spacing: 8, data: filteredSortedTags) { tag in
                    CardTagButton(
                        tag: tag,
                        selected: card.unwrappedTags.contains(where: { $0.id == tag.id })
                    ) {
                        let selected = card.unwrappedTags.contains(where: { $0.id == tag.id })
                        if selected {
                            card.tags?.removeAll(where: { $0.id == tag.id })
                        } else {
                            if card.tags == nil { card.tags = [] }
                            card.tags?.append(tag)
                        }
                        try? context.save()
                        WidgetCenter.shared.reloadAllTimelines()
                    }
                }
                .padding([.horizontal, .vertical])
            }
        }
        .navigationTitle("Tags")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Done") { dismiss() }
            }
        }
    }
}

private struct CardTagButton: View {
    let tag: CardTag
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(tag.name)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(selected ? Color.blue.opacity(0.2) : Color.clear)
                .foregroundColor(selected ? Color.blue : Color.primary)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(selected ? Color.blue : Color.gray.opacity(0.4), lineWidth: 1)
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

private struct CardTagFlowLayout<Data: RandomAccessCollection, Content: View>: View where Data.Element : Identifiable {
    let spacing: CGFloat
    let data: Data
    let content: (Data.Element) -> Content

    @State private var totalHeight: CGFloat = .zero

    var body: some View {
        GeometryReader { geometry in
            self.generateContent(in: geometry.size)
        }
        .frame(height: totalHeight)
    }

    private func generateContent(in size: CGSize) -> some View {
        var width = CGFloat.zero
        var height = CGFloat.zero

        return ZStack(alignment: .topLeading) {
            ForEach(data) { element in
                content(element)
                    .padding([.horizontal, .vertical], 4)
                    .alignmentGuide(.leading, computeValue: { d in
                        if abs(width - d.width) > size.width {
                            width = 0
                            height -= d.height + spacing
                        }
                        let result = width
                        if element.id == data.last?.id {
                            width = 0 // Last item
                        } else {
                            width -= d.width + spacing
                        }
                        return result
                    })
                    .alignmentGuide(.top, computeValue: { _ in
                        let result = height
                        if element.id == data.last?.id {
                            height = 0 // Last item
                        }
                        return result
                    })
            }
        }
        .background(viewHeightReader($totalHeight))
    }

    private func viewHeightReader(_ binding: Binding<CGFloat>) -> some View {
        GeometryReader { geo -> Color in
            DispatchQueue.main.async {
                binding.wrappedValue = geo.size.height
            }
            return Color.clear
        }
    }
}

