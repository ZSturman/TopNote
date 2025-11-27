//
//  FlexibleView.swift
//  TopNote
//
//  Created by Zachary Sturman on 11/27/25.
//

import SwiftUI

struct FlexibleView<Data: Collection, Content: View>: View where Data.Element: Hashable {
    let data: Data
    let spacing: CGFloat
    let alignment: HorizontalAlignment
    let content: (Data.Element) -> Content

    @State private var totalHeight: CGFloat = .zero

    var body: some View {
        GeometryReader { geometry in
            generateContent(in: geometry)
        }
        .frame(height: totalHeight)
    }

    private func generateContent(in geometry: GeometryProxy) -> some View {
        var positions: [CGSize] = Array(repeating: .zero, count: data.count)
        let items = Array(data)
        return ZStack(alignment: Alignment(horizontal: alignment, vertical: .top)) {
            ForEach(items.indices, id: \.self) { idx in
                content(items[idx])
                    .padding([.horizontal, .vertical], 4)
                    .background(
                        GeometryReader { geo in
                            Color.clear.preference(key: SizePreferenceKey.self, value: [idx: geo.size])
                        }
                    )
                    .alignmentGuide(.leading, computeValue: { _ in positions[safe: idx]?.width ?? 0 })
                    .alignmentGuide(.top, computeValue: { _ in positions[safe: idx]?.height ?? 0 })
            }
        }
        .onPreferenceChange(SizePreferenceKey.self) { sizes in
            var width: CGFloat = 0
            var lastRowHeight: CGFloat = 0
            var yOffset: CGFloat = 0
            for idx in items.indices {
                let size = sizes[idx] ?? CGSize(width: 0, height: 0)
                if width + size.width > geometry.size.width {
                    width = 0
                    yOffset += lastRowHeight + spacing
                    lastRowHeight = 0
                }
                positions[idx] = CGSize(width: width, height: yOffset)
                width += size.width + spacing
                lastRowHeight = max(lastRowHeight, size.height)
            }
            totalHeight = yOffset + lastRowHeight
        }
    }
}

struct SizePreferenceKey: PreferenceKey {
    static var defaultValue: [Int: CGSize] = [:]
    static func reduce(value: inout [Int: CGSize], nextValue: () -> [Int: CGSize]) {
        value.merge(nextValue(), uniquingKeysWith: { $1 })
    }
}

struct HeightPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = .zero
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

