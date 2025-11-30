//
//  CardDetailView+Sections.swift
//  TopNote
//
//  Created by Zachary Sturman on 11/27/25.
//

import Foundation
import SwiftUI

extension CardDetailView {
    struct CardDetailContentSection: View {
        var card: Card
        
        var body: some View {
            VStack(alignment: .leading, spacing: 6) {
                Text("Content")
                    .font(.headline)
                TextEditor(text: Binding(
                    get: { card.content },
                    set: { card.content = $0 }
                ))
                .frame(minHeight: 120)
                .padding(8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.secondary.opacity(0.3))
                )
                .accessibilityIdentifier("DetailContentEditor")
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    struct CardDetailAnswerSection: View {
        var card: Card
        
        var body: some View {
            if card.cardType == .flashcard {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Answer")
                        .font(.headline)
                    
                    TextEditor(text: Binding(
                        get: { card.answer ?? "" },
                        set: { card.answer = $0 }
                    ))
                    .frame(minHeight: 100)
                    .padding(8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.secondary.opacity(0.3))
                    )
                    .accessibilityIdentifier("DetailAnswerEditor")
                }
                .frame(maxWidth: .infinity, alignment: .leading)
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
            DisclosureGroup(isExpanded: $isExpanded) {
                VStack(alignment: .leading, spacing: 12) {
                    Menu {
                        Button("New Folder...") { showMoveFullScreen = true }
                        Divider()
                        ScrollView {
                            ForEach(folders.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }) { folder in
                                Button(action: {
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
                        })) {
                            ForEach(CardType.allCases, id: \.self) { type in
                                Label(type.rawValue.capitalized, systemImage: type.systemImage)
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
                    .font(.subheadline.bold())
                    .textCase(.uppercase)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        
        @ViewBuilder
        func folderMenuLabel() -> some View {
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
        
        @ViewBuilder
        func readOnlyTagsView() -> some View {
            HStack(spacing: 6) {
                ForEach(Array(card.tags ?? []), id: \.self) { tag in
                    Text("#\(tag.name)")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule().fill(Color.secondary.opacity(0.2))
                        )
                }
            }
        }
        
        
        @ViewBuilder
        func tagMenuLabel() -> some View {
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
    }
    
    // Similarly:
    struct CardDetailTimingSection: View {
        var card: Card
        @Binding var isExpanded: Bool
        
        var body: some View {
            DisclosureGroup(isExpanded: $isExpanded) {
                VStack(alignment: .leading, spacing: 12) {
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
                    
                    HStack {
                        Text("Base Schedule:")
                            .font(.body)
                        Spacer()
                        Picker("Base Schedule", selection: Binding(get: { RepeatInterval(hours: card.initialRepeatInterval) }, set: {
                            card.initialRepeatInterval = $0.hours ?? 24
                            card.repeatInterval = $0.hours ?? 24
                        })) {
                            ForEach(RepeatInterval.allCases.filter { $0.hours != nil }, id: \.self) { interval in
                                Text(interval.rawValue).tag(interval)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(maxWidth: 150)
                        .accessibilityLabel("Base Schedule Picker")
                    }
                    
                    // Show current interval if it differs from base
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
                            .padding(.vertical, 4)
                            .padding(.horizontal, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color.orange.opacity(0.1))
                            )
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
                .padding(4)
                
            } label: {
                Label("Timing", systemImage: "clock")
                    .font(.subheadline).bold()
                    .textCase(.uppercase)
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    struct CardDetailPoliciesSection: View {
        var card: Card
        @Binding var isExpanded: Bool
        
        var body: some View {
            DisclosureGroup(isExpanded: $isExpanded) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Skip Policy")
                        .font(.subheadline)
                        .bold()
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
                        VStack(alignment: .leading, spacing: 12) {
                            Text("On Easy Rating")
                                .font(.subheadline)
                                .bold()
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
                                .bold()
                            Picker("On Good Rating", selection: Binding(get: { card.ratingMedPolicy }, set: {
                                card.ratingMedPolicy = $0
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
                .padding(.vertical, 6)
            } label: {
                Label("Policies", systemImage: "slider.horizontal.3")
                    .font(.subheadline).bold()
                    .textCase(.uppercase)
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
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
                    .font(.subheadline).bold()
                    .textCase(.uppercase)
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        
    }
    
    struct CardDetailBottomActions: View {
        var card: Card
        @Binding var showDeleteConfirm: Bool
        
        var body: some View {
            VStack(spacing: 12) {
                Button(action: {
                    card.isArchived.toggle()
                }) {
                    Text(card.isArchived ? "Unarchive Card" : "Archive Card")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.secondary.opacity(0.2))
                        .foregroundColor(.primary)
                        .cornerRadius(8)
                }
                .accessibilityIdentifier(card.isArchived ? "UnarchiveButton" : "ArchiveButton")
                .accessibilityLabel(card.isArchived ? "Unarchive card" : "Archive card")
                
                Button(role: .destructive) {
                    showDeleteConfirm = true
                } label: {
                    Text("Delete Card")
                        .frame(maxWidth: .infinity)
                        .padding()
                }
                .accessibilityIdentifier("DeleteCardButton")
                .accessibilityLabel("Delete card")
            }
        }
    }
}
