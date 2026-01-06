//
//  CardDetailView+Sections.swift
//  TopNote
//
//  Created by Zachary Sturman on 11/27/25.
//

import Foundation
import SwiftUI
import PhotosUI

extension CardDetailView {
    struct CardDetailContentSection: View {
        var card: Card
        // MARK: - IMAGE DISABLED
        // @State private var selectedContentPhoto: PhotosPickerItem?
        @State private var showImageSourceMenu = false
        
        var body: some View {
            Section(header: Text("Content")) {
                TextEditor(text: Binding(
                    get: { card.content },
                    set: { card.content = $0 }
                ))
                .frame(minHeight: 120)
                .accessibilityIdentifier("DetailContentEditor")
            }
        }
    }
    
    struct CardDetailAnswerSection: View {
        var card: Card
        // MARK: - IMAGE DISABLED
        // @State private var selectedAnswerPhoto: PhotosPickerItem?
        
        var body: some View {
            if card.cardType == .flashcard {
                Section(header: Text("Answer")) {
                    TextEditor(text: Binding(
                        get: { card.answer ?? "" },
                        set: { card.answer = $0 }
                    ))
                    .frame(minHeight: 100)
                    .accessibilityIdentifier("DetailAnswerEditor")
                }
            }
        }
    }
    
    struct CardDetailOrganizeSection: View {
        var card: Card
        var folders: [Folder]
        var tags: [CardTag]
        
        @Binding var isExpanded: Bool
        @Binding var showMoveFullScreen: Bool
        @Binding var showTagFullScreen: Bool
        
        var body: some View {
            Section(header: Text("Organize")) {
                // Folder picker
                Menu {
                    Button("New Folder...") { showMoveFullScreen = true }
                    Divider()
                    Button(action: {
                        card.folder = nil
                    }) {
                        HStack {
                            Text("No Folder")
                            if card.folder == nil {
                                Spacer()
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                    ForEach(folders.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }) { folder in
                        Button(action: {
                            card.folder = folder
                        }) {
                            HStack {
                                Text(folder.name)
                                if card.folder == folder {
                                    Spacer()
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    HStack {
                        Text("Folder")
                            .foregroundStyle(.primary)
                        Spacer()
                        Text(card.folder?.name ?? "No Folder")
                            .foregroundStyle(.secondary)
                    }
                }
                
                // Tags display and picker
                VStack(alignment: .leading, spacing: 8) {
                    if !card.unwrappedTags.isEmpty {
                        FlowLayout(spacing: 6) {
                            ForEach(card.unwrappedTags.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }) { tag in
                                Text(tag.name)
                                    .font(.caption)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 4)
                                    .background(Color.blue.opacity(0.15))
                                    .foregroundColor(.blue)
                                    .cornerRadius(8)
                                    .onTapGesture {
                                        card.tags?.removeAll(where: { $0.id == tag.id })
                                    }
                            }
                        }
                    }
                    
                    Menu {
                        Button("Add Tag...") { showTagFullScreen = true }
                        Divider()
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
                                    }
                                }
                            }
                        }
                    } label: {
                        HStack {
                            Text("Tags")
                                .foregroundStyle(.primary)
                            Spacer()
                            Image(systemName: "plus.circle.fill")
                                .foregroundStyle(.blue)
                        }
                    }
                }
                
                // Priority picker
                Picker("Priority", selection: Binding(
                    get: { card.priority },
                    set: { card.priority = $0 }
                )) {
                    ForEach(PriorityType.allCases, id: \.self) { priority in
                        HStack {
                            Image(systemName: priority.iconName)
                            Text(priority.displayName)
                        }
                        .tag(priority)
                    }
                }
            }
        }
    }
    
    struct CardDetailTimingSection: View {
        var card: Card
        @Binding var isExpanded: Bool
        
        var body: some View {
            Section(header: Text("Timing")) {
                Toggle("Recurring", isOn: Binding(get: { card.isRecurring }, set: {
                    let wasRecurring = card.isRecurring
                    card.isRecurring = $0
                    if wasRecurring && !$0 {
                        Task {
                            await RecurringOffTip.toggledRecurringOffEvent.donate()
                        }
                    }
                }))
                .accessibilityIdentifier("RecurringToggle")
                .accessibilityHint("Toggle whether card repeats")
                
                Picker("Base Schedule", selection: Binding(get: { RepeatInterval(hours: card.initialRepeatInterval) }, set: {
                    card.initialRepeatInterval = $0.hours ?? 24
                    card.repeatInterval = $0.hours ?? 24
                })) {
                    ForEach(RepeatInterval.allCases.filter { $0.hours != nil }, id: \.self) { interval in
                        Text(interval.rawValue).tag(interval)
                    }
                }
                .accessibilityLabel("Base Schedule Picker")
                
                if card.isRecurring {
                    let scheduleDetails = card.displayedScheduleDetails
                    if scheduleDetails.isAdjusted {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("Current Interval:")
                                    .font(.body)
                                Spacer()
                                Text(scheduleDetails.current)
                                    .font(.body)
                                    .foregroundColor(.orange)
                            }
                            Text("Adjusted by spaced repetition")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                if card.cardType == .todo {
                    Toggle("Reset Interval on Complete", isOn: Binding(get: { card.resetRepeatIntervalOnComplete }, set: {
                        card.resetRepeatIntervalOnComplete = $0
                    }))
                    .accessibilityLabel("Reset Repeat Interval on Complete")
                }
                
                Toggle("Enable Skip", isOn: Binding(get: { card.skipEnabled }, set: {
                    card.skipEnabled = $0
                }))
                .accessibilityHint("Toggle whether card is skipped")
            }
        }
    }
    
    struct CardDetailPoliciesSection: View {
        var card: Card
        @Binding var isExpanded: Bool
        
        var body: some View {
            Section(header: Text("Policies")) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Skip Policy")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Picker("Skip Policy", selection: Binding(get: { card.skipPolicy }, set: {
                        card.skipPolicy = $0
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
                            .foregroundColor(.secondary)
                            .padding(.top, 8)
                        Picker("On Easy Rating", selection: Binding(get: { card.ratingEasyPolicy }, set: {
                            card.ratingEasyPolicy = $0
                        })) {
                            ForEach(RepeatPolicy.allCases, id: \.self) { policy in
                                Text(policy.rawValue).tag(policy)
                            }
                        }
                        .pickerStyle(.segmented)
                        .accessibilityLabel("On Easy Rating Picker")
                        
                        Text("On Good Rating")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding(.top, 8)
                        Text("Maintains current schedule")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("On Hard Rating")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding(.top, 8)
                        Picker("On Hard Rating", selection: Binding(get: { card.ratingHardPolicy }, set: {
                            card.ratingHardPolicy = $0
                        })) {
                            ForEach(RepeatPolicy.allCases, id: \.self) { policy in
                                Text(policy.rawValue).tag(policy)
                            }
                        }
                        .pickerStyle(.segmented)
                        .accessibilityLabel("On Hard Rating Picker")
                    }
                }
            }
        }
    }
    
    
    struct CardDetailHistorySection: View {
        var card: Card
        @Binding var isExpanded: Bool
        
        func formattedDate(_ date: Date) -> String {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .short
            return formatter.string(from: date)
        }
        
        func mergedEnqueueSkipRemoveEvents() -> [MergedEvent] {
            var events: [MergedEvent] = []
            for date in card.enqueues { events.append(.init(date: date, type: .enqueue)) }
            for date in card.skips   { events.append(.init(date: date, type: .skip)) }
            for date in card.removals{ events.append(.init(date: date, type: .removal)) }
            return events.sorted { $0.date > $1.date }
        }
        
        var body: some View {
            DisclosureGroup(isExpanded: $isExpanded) {
                VStack(alignment: .leading, spacing: 12) {
                    // Created At
                    HStack {
                        Text("Created At:")
                            .bold()
                        Spacer()
                        Text(formattedDate(card.createdAt))
                            .foregroundColor(.secondary)
                    }
                    
                    Divider()
                    
                    // Seen Count
                    HStack {
                        Text("Seen:")
                            .bold()
                        Spacer()
                        Text("\(card.seenCount)")
                            .foregroundColor(.secondary)
                            .accessibilityLabel("\(card.seenCount) times seen")
                    }
                    
                    // Skipped Count
                    HStack {
                        Text("Skipped:")
                            .bold()
                        Spacer()
                        Text("\(card.skipCount)")
                            .foregroundColor(.secondary)
                            .accessibilityLabel("\(card.skipCount) times skipped")
                    }
                    
                    // Enqueues/Skips/Removals
                    let mergedEvents = mergedEnqueueSkipRemoveEvents()
                    if !mergedEvents.isEmpty {
                        Divider()
                        
                        Text("Activity Log")
                            .font(.subheadline)
                            .bold()
                            .padding(.top, 4)
                        
                        ForEach(mergedEvents) { event in
                            HStack(spacing: 8) {
                                Image(systemName: event.iconName)
                                    .foregroundColor(event.tintColor)
                                    .accessibilityHidden(true)
                                Text(event.label)
                                    .font(.caption)
                                Spacer()
                                Text(formattedDate(event.date))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 2)
                            .accessibilityElement(children: .combine)
                            .accessibilityLabel("\(event.label) on \(formattedDate(event.date))")
                        }
                    }
                    
                    // Completes Log - only for todo
                    if card.cardType == .todo && !card.completes.isEmpty {
                        Divider()
                        
                        Text("Completes Log")
                            .font(.subheadline)
                            .bold()
                            .padding(.top, 4)
                        
                        ForEach(Array(card.completes.sorted(by: { $0 > $1 })), id: \.self) { date in
                            HStack {
                                Image(systemName: "checkmark.circle")
                                    .foregroundColor(.green)
                                Text("Completed")
                                    .font(.caption)
                                Spacer()
                                Text(formattedDate(date))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 2)
                        }
                    }
                    
                    // Rating Log - only for flashcard
                    if card.cardType == .flashcard && !card.ratingEvents.isEmpty {
                        Divider()
                        
                        Text("Rating Log")
                            .font(.subheadline)
                            .bold()
                            .padding(.top, 4)
                        
                        ForEach(Array(card.ratingEvents.sorted(by: { $0.date > $1.date })), id: \.date) { event in
                            HStack(spacing: 8) {
                                Image(systemName: event.rating.systemImage)
                                    .foregroundColor(event.rating.tintColor)
                                    .accessibilityHidden(true)
                                Text(event.rating.rawValue.capitalized)
                                    .font(.caption)
                                Spacer()
                                Text(formattedDate(event.date))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 2)
                            .accessibilityElement(children: .combine)
                            .accessibilityLabel("\(event.rating.rawValue.capitalized) rating on \(formattedDate(event.date))")
                        }
                    }
                }
                .padding(.vertical, 6)
            } label: {
                Label("History", systemImage: "clock.arrow.circlepath")
            }
        }
        
    }
    
    struct CardDetailBottomActions: View {
        var card: Card
        @Binding var showDeleteConfirm: Bool
        
        var body: some View {
            Button(action: {
                card.isArchived.toggle()
            }) {
                HStack {
                    Spacer()
                    Text(card.isArchived ? "Unarchive Card" : "Archive Card")
                        .foregroundColor(card.isArchived ? .blue : .secondary)
                    Spacer()
                }
            }
            .accessibilityIdentifier(card.isArchived ? "UnarchiveButton" : "ArchiveButton")
            .accessibilityLabel(card.isArchived ? "Unarchive card" : "Archive card")
            
            Button(role: .destructive) {
                showDeleteConfirm = true
            } label: {
                HStack {
                    Spacer()
                    Text("Delete Card")
                    Spacer()
                }
            }
            .accessibilityIdentifier("DeleteCardButton")
            .accessibilityLabel("Delete card")
        }
    }
}
