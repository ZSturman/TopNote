//
//  CardDetailView.swift
//  TopNote
//
//  Created by Zachary Sturman on 8/6/25.
//

import Foundation
import SwiftUI
import SwiftData

struct CardDetailView: View {
    var card: Card
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    // These actions must be handled by the parent view to ensure only one sheet is shown at a time.
    var moveAction: () -> Void
    var tagAction: () -> Void

    @Query private var folders: [Folder]
    @Query private var tags: [CardTag]

    @State private var showDeleteConfirm: Bool = false
    @State private var showShareSheet = false
    @State private var exportedFileURL: URL?

    // DisclosureGroups expanded state
    @State private var showOrganize = true
    @State private var showTiming = false
    @State private var showPolicies = false
    @State private var showMetadata = false
    @State private var showLogs = false
    @State private var showCardTypePicker = false

    // Added States for DisclosureGroups inside logs for sublogs
    @State private var showRatings = false
    @State private var showCompletes = false
    @State private var showMergedLogs = false

    // Added states for full screen covers for move and tag sheets
    @State private var showMoveFullScreen = false
    @State private var showTagFullScreen = false
    
    @ViewBuilder fileprivate func readOnlyTagsView() -> some View {
        HStack(spacing: 6) {
            ForEach(Array(card.tags ?? []), id: \.self) { tag in
                Text("#\(tag.name)")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color.secondary.opacity(0.2))
                    )
            }
        }
    }
    
    @ViewBuilder fileprivate func folderMenuLabel() -> some View {
        GroupBox {
            HStack(spacing: 6) {
                Image(systemName: "folder")
                Text(card.folder?.name ?? "No Folder")
                    .bold()
                    .font(.body)
                Spacer()
                Image(systemName: "chevron.down")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
            .contentShape(Rectangle())
        }
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(Color.accentColor.opacity(0.6), lineWidth: 1)
        )
        .padding(.vertical, 2)
    }
    
    @ViewBuilder fileprivate func tagMenuLabel() -> some View {
        GroupBox {
            HStack(spacing: 6) {
                Image(systemName: "tag")
                Text("Tags")
                    .bold()
                    .font(.body)
                Spacer()
                Image(systemName: "chevron.down")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
            .contentShape(Rectangle())
        }
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(Color.accentColor.opacity(0.6), lineWidth: 1)
        )
        .padding(.vertical, 2)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Content Editor
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Content")
                            .font(.headline)
                            .accessibilityAddTraits(.isHeader)

                        TextEditor(text: Binding(get: { card.content }, set: {
                            card.content = $0
                            try? context.save()
                        }))
                        .frame(minHeight: 120)
                        .padding(8)
                        .background(RoundedRectangle(cornerRadius: 8).stroke(Color.secondary.opacity(0.3)))
                        .accessibilityLabel("Card Content Editor")
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    // Answer Editor (always visible for flashcard)
                    if card.cardType == .flashcard {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Answer")
                                .font(.headline)
                                .accessibilityAddTraits(.isHeader)

                            TextEditor(text: Binding(get: { card.answer ?? "" }, set: {
                                card.answer = $0
                                try? context.save()
                            }))
                            .frame(minHeight: 100)
                            .padding(8)
                            .background(RoundedRectangle(cornerRadius: 8).stroke(Color.secondary.opacity(0.3)))
                            .accessibilityLabel("Card Answer Editor")
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    // Organize Section
                    DisclosureGroup(isExpanded: $showOrganize) {
                        VStack(alignment: .leading, spacing: 12) {
                            
                            Menu {
                                // This button now presents full screen cover locally instead of using parent action
                                Button("New Folder...") { showMoveFullScreen = true }
                                Divider()
                                ScrollView {
                                    ForEach(folders.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }) { folder in
                                        Button(action: {
                                            // Move the card to the selected folder
                                            card.folder = folder
                                          
                                        }) {
                                            HStack {
                                                Text(folder.name)
                                                if card.folder == folder {
                                                    Spacer()
                                                    Image(systemName: "checkmark")
                                                        .foregroundColor(.blue)
                                                }
                                            }
                                        }
                                    }
                                    
                                    .frame(maxHeight: 200)
                                }
                            } label: {
                                folderMenuLabel()
                            }
                          

                            Divider()
                                .padding(.vertical, 4)
                            
                            readOnlyTagsView()

                            
                            
                            Menu {
                                // This button now presents full screen cover locally instead of using parent action
                                Button("Add Tag...") { showTagFullScreen = true }
                                Divider()
                                ScrollView {
                                    ForEach(tags.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }) { tag in
                                        Button(action: {
                                            if card.unwrappedTags.contains(where: { $0.id == tag.id }) {
                                                card.tags?.removeAll(where: { $0.id == tag.id })
                                            } else {
                                                if card.tags == nil { card.tags = [] }
                                                card.tags?.append(tag)
                                            }
                                           
                                        }) {
                                            HStack {
                                                Text(tag.name)
                                                if card.unwrappedTags.contains(where: { $0.id == tag.id }) {
                                                    Spacer()
                                                    Image(systemName: "checkmark")
                                                        .foregroundColor(.blue)
                                                }
                                            }
                                        }
                                    }
                                    .frame(maxHeight: 200)
                                }
                            } label: {
                                tagMenuLabel()
                            }
                            .menuActionDismissBehavior(.disabled)
                      

                            

                            Divider()
                                .padding(.vertical, 4)
                            
                            HStack {
                                Text("Card Type:")
                                    .font(.body)
                                Spacer()
                                Picker("Card Type", selection: Binding(get: { card.cardType }, set: {
                                    card.cardType = $0
                                    try? context.save()
                                })) {
                                    ForEach(CardType.allCases, id: \.self) { type in
                                        Label(type.rawValue.capitalized, systemImage: type.iconName)
                                            .tag(type)
                                    }
                                }
                                .pickerStyle(.menu)
                                .accessibilityLabel("Card Type Picker")
                                .frame(maxWidth: .infinity)
                            }

                            // Priority Picker
                            HStack {
                                Text("Priority:")
                                    .font(.body)
                                Spacer()
                                Picker("Priority", selection: Binding(get: { card.priority }, set: {
                                    card.priority = $0
                                    try? context.save()
                                })) {
                                    ForEach(PriorityType.allCases, id: \.self) { priority in
                                        Text(priority.rawValue)
                                            .tag(priority)
                                    }
                                }
                                .pickerStyle(.segmented)
                                .accessibilityLabel("Priority Picker")
                                .frame(maxWidth: .infinity)
                            }

                        }
                        .padding(.vertical, 6)
                    } label: {
                        Label("Organize", systemImage: "rectangle.3.group")
                            .font(.subheadline).bold()
                            .textCase(.uppercase)
                            .foregroundColor(.primary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    // Timing Section
                    DisclosureGroup(isExpanded: $showTiming) {
                        VStack(alignment: .leading, spacing: 12) {
                            Toggle("Recurring", isOn: Binding(get: { card.isRecurring }, set: {
                                card.isRecurring = $0
                                try? context.save()
                            }))
                            .accessibilityHint("Toggle whether card repeats")

                            HStack {
                                Text("Repeat Interval:")
                                    .font(.body)
                                Spacer()
                                Picker("Repeat Interval", selection: Binding(get: { RepeatInterval(hours: card.repeatInterval) }, set: {
                                    card.repeatInterval = $0.hours ?? 24
                                    try? context.save()
                                })) {
                                    ForEach(RepeatInterval.allCases.filter { $0.hours != nil }, id: \.self) { interval in
                                        Text(interval.rawValue).tag(interval)
                                    }
                                }
                                .pickerStyle(.menu)
                                .frame(maxWidth: 150)
                                .accessibilityLabel("Repeat Interval Picker")
                            }

                            if card.cardType == .todo {
                                Toggle("Reset Interval on Complete", isOn: Binding(get: { card.resetRepeatIntervalOnComplete }, set: {
                                    card.resetRepeatIntervalOnComplete = $0
                                    try? context.save()
                                }))
                                .accessibilityLabel("Reset Repeat Interval on Complete")
                            }

                            Toggle("Enable Skip", isOn: Binding(get: { card.skipEnabled }, set: {
                                card.skipEnabled = $0
                                try? context.save()
                            }))
                            .accessibilityHint("Toggle whether card is skipped")
                        }
                        .padding(4)
                
                    } label: {
                        Label("Timing", systemImage: "clock")
                            .font(.subheadline).bold()
                            .textCase(.uppercase)
                            .foregroundColor(.primary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    // Policies Section
                    DisclosureGroup(isExpanded: $showPolicies) {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Skip Policy")
                                .font(.subheadline)
                                .bold()
                            Picker("Skip Policy", selection: Binding(get: { card.skipPolicy }, set: {
                                card.skipPolicy = $0
                                try? context.save()
                            })) {
                                ForEach(RepeatPolicy.allCases, id: \.self) { policy in
                                    Text(policy.rawValue).tag(policy)
                                }
                            }
                            .pickerStyle(.segmented)
                            .accessibilityLabel("Skip Policy Picker")

                            if card.cardType == .flashcard {
                                Text("On Easy Rating")
                                    .font(.subheadline)
                                    .bold()
                                Picker("On Easy Rating", selection: Binding(get: { card.ratingEasyPolicy }, set: {
                                    card.ratingEasyPolicy = $0
                                    try? context.save()
                                })) {
                                    ForEach(RepeatPolicy.allCases, id: \.self) { policy in
                                        Text(policy.rawValue).tag(policy)
                                    }
                                }
                                .pickerStyle(.segmented)
                                .accessibilityLabel("On Easy Rating Picker")

                                Text("On Good Rating")
                                    .font(.subheadline)
                                    .bold()
                                Picker("On Good Rating", selection: Binding(get: { card.ratingMedPolicy }, set: {
                                    card.ratingMedPolicy = $0
                                    try? context.save()
                                })) {
                                    ForEach(RepeatPolicy.allCases, id: \.self) { policy in
                                        Text(policy.rawValue).tag(policy)
                                    }
                                }
                                .pickerStyle(.segmented)
                                .accessibilityLabel("On Good Rating Picker")

                                Text("On Hard Rating")
                                    .font(.subheadline)
                                    .bold()
                                Picker("On Hard Rating", selection: Binding(get: { card.ratingHardPolicy }, set: {
                                    card.ratingHardPolicy = $0
                                    try? context.save()
                                })) {
                                    ForEach(RepeatPolicy.allCases, id: \.self) { policy in
                                        Text(policy.rawValue).tag(policy)
                                    }
                                }
                                .pickerStyle(.segmented)
                                .accessibilityLabel("On Hard Rating Picker")
                            }
                        }
                        .padding(.vertical, 6)
                    } label: {
                        Label("Policies", systemImage: "slider.horizontal.3")
                            .font(.subheadline).bold()
                            .textCase(.uppercase)
                            .foregroundColor(.primary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    // Metadata Section
                    DisclosureGroup(isExpanded: $showMetadata) {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Created At:")
                                    .bold()
                                Spacer()
                                Text(formattedDate(card.createdAt))
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 6)
                    } label: {
                        Label("Metadata", systemImage: "info.circle")
                            .font(.subheadline).bold()
                            .textCase(.uppercase)
                            .foregroundColor(.primary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    // Logs & History Section
                    DisclosureGroup(isExpanded: $showLogs) {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Seen:")
                                    .bold()
                                Spacer()
                                Text("\(card.seenCount)")
                                    .accessibilityLabel("\(card.seenCount) times seen")
                            }
                            HStack {
                                Text("Skipped:")
                                    .bold()
                                Spacer()
                                Text("\(card.skipCount)")
                                    .accessibilityLabel("\(card.skipCount) times skipped")
                            }

                            // Rating Log - only for flashcard
                            if card.cardType == .flashcard {
                                DisclosureGroup(isExpanded: $showRatings) {
                                    if card.ratingEvents.isEmpty {
                                        Text("No rating history available")
                                            .foregroundColor(.secondary)
                                            .accessibilityLabel("No rating history available")
                                    } else {
                                        ForEach(Array(card.ratingEvents.sorted(by: { $0.date > $1.date })), id: \.date) { event in
                                            HStack(spacing: 8) {
                                                Image(systemName: event.rating.systemImage)
                                                    .foregroundColor(event.rating.tintColor)
                                                    .accessibilityHidden(true)
                                                Text(event.rating.rawValue.capitalized)
                                                    .font(.subheadline)
                                                    .foregroundColor(.primary)
                                                Spacer()
                                                Text(formattedDate(event.date))
                                                    .font(.footnote)
                                                    .foregroundColor(.secondary)
                                            }
                                            .accessibilityElement(children: .combine)
                                            .accessibilityLabel("\(event.rating.rawValue.capitalized) rating on \(formattedDate(event.date))")
                                        }
                                    }
                                } label: {
                                    Label("Rating Log", systemImage: "star.bubble.fill")
                                        .font(.subheadline).bold()
                                        .textCase(.uppercase)
                                        .foregroundColor(.primary)
                                }
                            }

                            // Completes Log - only for todo
                            if card.cardType == .todo {
                                DisclosureGroup(isExpanded: $showCompletes) {
                                    if card.completes.isEmpty {
                                        Text("No completes recorded")
                                            .foregroundColor(.secondary)
                                    } else {
                                        ForEach(Array(card.completes.sorted(by: { $0 > $1 })).prefix(showCompletes ? card.completes.count : 5), id: \.self) { date in
                                            Text(formattedDate(date))
                                                .font(.footnote)
                                                .foregroundColor(.primary)
                                        }
                                    }
                                } label: {
                                    Label("Completes Log", systemImage: "checkmark.circle")
                                        .font(.subheadline).bold()
                                        .textCase(.uppercase)
                                        .foregroundColor(.primary)
                                }
                            }

                            // Merged Enqueues, Skips, Removals Log
                            DisclosureGroup(isExpanded: $showMergedLogs) {
                                let mergedEvents = mergedEnqueueSkipRemoveEvents()
                                if mergedEvents.isEmpty {
                                    Text("No enqueue, skip or removal events recorded")
                                        .foregroundColor(.secondary)
                                } else {
                                    ForEach(mergedEvents) { event in
                                        HStack(spacing: 8) {
                                            Image(systemName: event.iconName)
                                                .foregroundColor(event.tintColor)
                                                .accessibilityHidden(true)
                                            Text(event.label)
                                                .font(.subheadline)
                                                .foregroundColor(.primary)
                                            Spacer()
                                            Text(formattedDate(event.date))
                                                .font(.footnote)
                                                .foregroundColor(.secondary)
                                        }
                                        .accessibilityElement(children: .combine)
                                        .accessibilityLabel("\(event.label) on \(formattedDate(event.date))")
                                    }
                                }
                            } label: {
                                Label("Enqueue/Skip/Removal Log", systemImage: "list.bullet.rectangle")
                                    .font(.subheadline).bold()
                                    .textCase(.uppercase)
                                    .foregroundColor(.primary)
                            }
                        }
                        .padding(.vertical, 6)
                    } label: {
                        Label("Logs & History", systemImage: "book.closed")
                            .font(.subheadline).bold()
                            .textCase(.uppercase)
                            .foregroundColor(.primary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    Spacer()

                    // Bottom Buttons: Archive/Unarchive & Delete
                    VStack(spacing: 12) {
                        Button(action: {
                            card.isArchived.toggle()
                            try? context.save()
                        }) {
                            Text(card.isArchived ? "Unarchive Card" : "Archive Card")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.secondary.opacity(0.2))
                                .foregroundColor(.primary)
                                .cornerRadius(8)
                        }
                        .accessibilityLabel(card.isArchived ? "Unarchive card" : "Archive card")

                        Button(role: .destructive) {
                            confirmDelete()
                        } label: {
                            Text("Delete Card")
                                .frame(maxWidth: .infinity)
                                .padding()
                        }
                        .accessibilityLabel("Delete card")
                    }
                }
                .padding()
            }
            .navigationTitle("Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .accessibilityLabel("Done editing card")
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        exportCurrentCard()
                    } label: {
                        Label("Export", systemImage: "square.and.arrow.up")
                    }
                    .accessibilityLabel("Export this card")
                }
            }
            .confirmationDialog("Are you sure you want to delete this card?", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
                Button("Delete", role: .destructive) {
                    deleteCard()
                }
                Button("Cancel", role: .cancel) {}
            }
            // Full screen covers for move and tag sheets to allow stacked modal presentation
            .fullScreenCover(isPresented: $showMoveFullScreen) {
                NavigationStack {
                    UpdateCardFolderView(card: card)
                }
            }
            .fullScreenCover(isPresented: $showTagFullScreen) {
                NavigationStack {
                    AddNewTagSheet(card: card)
                }
            }
            .sheet(isPresented: $showShareSheet) {
                if let exportedFileURL {
                    ShareSheet(activityItems: [exportedFileURL])
                }
            }
        }
    }

    private func mergedEnqueueSkipRemoveEvents() -> [MergedEvent] {
        // Prepare labeled events with date, icon, and label, sorted by date descending
        var events: [MergedEvent] = []

        // Enqueues
        for date in card.enqueues {
            events.append(MergedEvent(date: date, type: .enqueue))
        }
        // Skips
        for date in card.skips {
            events.append(MergedEvent(date: date, type: .skip))
        }
        // Removals
        for date in card.removals {
            events.append(MergedEvent(date: date, type: .removal))
        }

        return events.sorted(by: { $0.date > $1.date })
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    private func confirmDelete() {
        showDeleteConfirm = true
    }

    private func deleteCard() {
        context.delete(card)
        try? context.save()
        dismiss()
    }
    
    private func exportCurrentCard() {
        do {
            let jsonData = try Card.exportCardsToJSON([card])
            let fileManager = FileManager.default
            if let dir = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first {
                let fileURL = dir.appendingPathComponent("exported_card.json")
                try jsonData.write(to: fileURL)
                exportedFileURL = fileURL
                showShareSheet = true
            }
        } catch {
            print("Export failed: \(error)")
        }
    }
}

// MARK: - Supporting Views and Extensions

fileprivate struct FlexibleTagView: View {
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

/// FlexibleView is a helper to layout views in flexible rows (wrap lines).
/// Source: many similar implementations exist online.
fileprivate struct FlexibleView<Data: Collection, Content: View>: View where Data.Element: Hashable {
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

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

fileprivate struct SizePreferenceKey: PreferenceKey {
    static var defaultValue: [Int: CGSize] = [:]
    static func reduce(value: inout [Int: CGSize], nextValue: () -> [Int: CGSize]) {
        value.merge(nextValue(), uniquingKeysWith: { $1 })
    }
}

fileprivate struct HeightPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = .zero
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

// MARK: - Merged Event Model

fileprivate struct MergedEvent: Identifiable {
    enum EventType {
        case enqueue, skip, removal

        var iconName: String {
            switch self {
            case .enqueue: return "clock.arrow.circlepath"
            case .skip: return "arrow.triangle.2.circlepath"
            case .removal: return "trash"
            }
        }

        var tintColor: Color {
            switch self {
            case .enqueue: return .blue
            case .skip: return .orange
            case .removal: return .red
            }
        }

        var label: String {
            switch self {
            case .enqueue: return "Enqueued"
            case .skip: return "Skipped"
            case .removal: return "Removed"
            }
        }
    }

    let id = UUID()
    let date: Date
    let type: EventType

    var iconName: String { type.iconName }
    var tintColor: Color { type.tintColor }
    var label: String { type.label }
}

