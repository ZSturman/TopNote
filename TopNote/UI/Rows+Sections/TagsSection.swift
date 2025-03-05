//
//  TagsSection.swift
//  TopNote
//
//  Created by Zachary Sturman on 3/1/25.
//

import SwiftUI
import SwiftData


struct FlowLayout: Layout {
    // You can customize spacing and alignment if desired.
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize,
                      subviews: Subviews,
                      cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var width: CGFloat = 0
        var height: CGFloat = 0
        
        var currentRowWidth: CGFloat = 0
        var currentRowHeight: CGFloat = 0
        
        for subview in subviews {
            let subviewSize = subview.sizeThatFits(.unspecified)
            
            // If this subview doesn't fit in the current row, move to the next row
            if currentRowWidth + subviewSize.width > maxWidth {
                width = max(width, currentRowWidth)
                height += currentRowHeight + spacing
                currentRowWidth = subviewSize.width
                currentRowHeight = subviewSize.height
            } else {
                currentRowWidth += subviewSize.width + spacing
                currentRowHeight = max(currentRowHeight, subviewSize.height)
            }
        }
        
        width = max(width, currentRowWidth)
        height += currentRowHeight
        
        return CGSize(width: width, height: height)
    }
    
    func placeSubviews(in bounds: CGRect,
                       proposal: ProposedViewSize,
                       subviews: Subviews,
                       cache: inout ()) {
        let maxWidth = bounds.width
        var x = bounds.minX
        var y = bounds.minY
        var currentRowHeight: CGFloat = 0
        
        for subview in subviews {
            let subviewSize = subview.sizeThatFits(.unspecified)
            
            // If it doesn't fit, wrap to next row
            if x + subviewSize.width > maxWidth {
                x = bounds.minX
                y += currentRowHeight + spacing
                currentRowHeight = 0
            }
            
            subview.place(at: CGPoint(x: x, y: y),
                          proposal: .unspecified)
            
            x += subviewSize.width + spacing
            currentRowHeight = max(currentRowHeight, subviewSize.height)
        }
    }
}

struct TagButton: View {
    let tag: Tag
    let selectionState: TagSelectionState
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            Text(tag.name)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .font(.subheadline)
                .foregroundColor(foregroundColor)
                .background(backgroundColor)
                .cornerRadius(8)
        }
    }
    
    private var backgroundColor: Color {
        switch selectionState {
        case .neutral:
            return Color.gray.opacity(0.2)
        case .selected:
            return Color.green.opacity(0.2)
        case .deselected:
            return Color.red.opacity(0.2)
        }
    }
    
    private var foregroundColor: Color {
        switch selectionState {
        case .neutral:
            return .gray
        case .selected:
            return .green
        case .deselected:
            return .red
        }
    }
}

struct TagsSection: View {
    @Environment(\.modelContext) private var modelContext
    
    var tags: [Tag]
    @Binding var tagSelectionStates: [UUID: TagSelectionState]
    
    var body: some View {
        Section(header: Text("Tags")) {
            // A scroll view so we can see wrapping if the list of tags gets longer
            ScrollView(.vertical) {
                FlowLayout(spacing: 8) {
                    ForEach(tags.sorted { $0.name < $1.name }) { tag in
                        let currentState = tagSelectionStates[tag.id] ?? .neutral
                        
                        TagButton(tag: tag,
                                  selectionState: currentState) {
                            // Cycle the state on tap
                            let newState: TagSelectionState
                            switch currentState {
                            case .neutral:
                                newState = .selected
                            case .selected:
                                newState = .deselected
                            case .deselected:
                                newState = .neutral
                            }
                            tagSelectionStates[tag.id] = newState
                        }
                        .contextMenu {
                            Button(role: .destructive) {
                                modelContext.delete(tag)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
                .padding(.vertical, 8)
            }
            .frame(maxHeight: 200) // Adjust as needed
        }
    }
}


//
//import Foundation
//import SwiftUI
//import SwiftData
//
//struct TagsSection: View {
//    @Environment(\.modelContext) private var modelContext
//    var tags: [Tag]
//    @Binding var tagSelectionStates:  [UUID: TagSelectionState]
//    
//    
//    var body: some View {
//        Section(header: Text("Tags")) {
//            ForEach(tags.sorted { $0.name < $1.name }) { tag in
//                HStack {
//                    Text(tag.name)
//                    // Show a textual indicator of the current tag state.
//                    switch tagSelectionStates[tag.id] ?? .neutral {
//                    case .neutral:
//                        Text("Neutral")
//                            .foregroundColor(.gray)
//                    case .selected:
//                        Text("Selected")
//                            .foregroundColor(.green)
//                    case .deselected:
//                        Text("Deselected")
//                            .foregroundColor(.red)
//                    }
//                }
//                .contentShape(Rectangle())
//                .onTapGesture {
//                    // Cycle the state: neutral -> selected -> deselected -> neutral.
//                    let currentState = tagSelectionStates[tag.id] ?? .neutral
//                    let newState: TagSelectionState
//                    switch currentState {
//                    case .neutral:
//                        newState = .selected
//                    case .selected:
//                        newState = .deselected
//                    case .deselected:
//                        newState = .neutral
//                    }
//                    tagSelectionStates[tag.id] = newState
//                }
//                .swipeActions(edge: .trailing) {
//                    Button(role: .destructive) {
//                        modelContext.delete(tag)
//                    } label: {
//                        Label("Delete", systemImage: "trash")
//                    }
//                    
//                }
//            }
//        }
//    }
//}
