//
//  CardRowControls.swift
//  TopNote
//
//  Created by Zachary Sturman on 11/27/25.
//

import Foundation
import SwiftUI
import SwiftData

struct FolderMenu: View {
    var card: Card
    var folders: [Folder]

    @State private var showMenu = false
    var body: some View {
        Menu {
            Button("New Folder...") { showMenu = true }
            Divider()
            ForEach(folders.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }) { folder in
                Button(action: {
                    card.folder = folder
                }) {
                    HStack {
                        Text(folder.name)
                        if card.folder == folder {
                            Spacer()
                            Image(systemName: "checkmark").foregroundColor(.blue)
                        }
                    }
                }
            }
        } label: {
            HStack {
                Image(systemName: "folder")
                Text(card.folder?.name ?? "Choose folder...")
            }
            .font(.subheadline)
        }
    }
}

struct CardPoliciesMenu: View {
    var card: Card

    let flashcardRatingPolicyTip = FlashcardRatingPolicyTip()
    let firstNoteTip = FirstNoteTip_Skip()
    let firstTodoTip = FirstTodoTip_Skip()
    let firstFlashcardTip = FirstFlashcardTip_Skip()

    
    var body: some View {
        Menu {
            
            if card.cardType == .todo {
                
                
                Toggle(isOn: Binding(
                    get: { card.resetRepeatIntervalOnComplete },
                    set: { card.resetRepeatIntervalOnComplete = $0 }
                )) {
                    Label("Reset Interval On Complete", systemImage: "clock.arrow.trianglehead.counterclockwise.rotate.90")
                }
                
            }
                
            Menu {
                Toggle(isOn: Binding(
                    get: { card.skipEnabled },
                    set: { card.skipEnabled = $0 }
                )) {
                    Label("Enable Skip", systemImage: "arrow.trianglehead.counterclockwise.rotate.90")
                }
                
                if !card.skipEnabled {
                    Text("Skipping disabled")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        .padding(.top, 2)
                }
                Picker("On Skip", selection: Binding(
                    get: { card.skipPolicy },
                    set: { card.skipPolicy = $0 }
                )) {
                    ForEach(RepeatPolicy.allCases, id: \.self) { policy in
                        Text(policy.rawValue).tag(policy)
                    }
                }
                .pickerStyle(.inline)
                .font(.subheadline)
                
                
                                        VStack(alignment: .leading, spacing: 8) {
                                            ForEach(RepeatPolicy.allCases, id: \.self) { policy in
                                                if card.cardType == .note {
                                                    // For notes, reverse the wording
                                                    Text("• \(policy.rawValue): \(policy.skipDescriptionForNote)")
                                                } else {
                                                    Text("• \(policy.rawValue): \(policy.shortDescription(for: .hard))")
                                                }
                                            }
                                        }

            } label: {
                HStack(spacing: 4) {
                    Text("On Skip:")
                    Text(card.skipPolicy.rawValue)
                        .fontWeight(.semibold)
                }
            }
            .overlay {
                if card.cardType == .note {
                    Color.clear.popoverTip(firstNoteTip, arrowEdge: .top)
                } else if card.cardType == .todo {
                    Color.clear.popoverTip(firstTodoTip, arrowEdge: .top)
                } else {
                    Color.clear.popoverTip(firstFlashcardTip, arrowEdge: .top)
                }
            }
            .onAppear {
                Task {
                    switch card.cardType {
                    case .note:
                        await FirstNoteTip_Skip.createdFirstNoteEvent.donate()
                    case .todo:
                        await FirstTodoTip_Skip.createdFirstTodoEvent.donate()
                    case .flashcard:
                        await FirstFlashcardTip_Skip.createdFirstFlashcardEvent.donate()
                    }
                }
            }
            
            
            if card.cardType == .flashcard {
                Divider()
                VStack(alignment: .leading, spacing: 8) {

                    
                    Text("Ratings Repeat Policy")
                        .font(.subheadline.weight(.semibold))
                    
                    
                    .onAppear {
                        Task { await FlashcardRatingPolicyTip.openedFlashcardPoliciesEvent.donate() }
                    }
                    
                    Menu {
                        Text("Easy moves the card further out.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Divider()
                        
                        ForEach(RepeatPolicy.allCases, id: \.self) { policy in
                            Button(action: {
                                card.ratingEasyPolicy = policy
                            }) {
                                HStack {
                                    Text(policy.rawValue)
                                    if card.ratingEasyPolicy == policy {
                                        Spacer()
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                        
                        Divider()
                        
                        VStack(alignment: .leading, spacing: 4) {
                            ForEach(RepeatPolicy.allCases, id: \.self) { policy in
                                Text("• \(policy.rawValue): \(policy.shortDescription(for: .easy))")
                                    .font(.caption)
                            }
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Text("On Easy:")
                            Text(card.ratingEasyPolicy.rawValue)
                                .fontWeight(.semibold)
                        }
                        .font(.subheadline)
                    }
                    .menuActionDismissBehavior(.disabled)

                    Menu {
                        Text("Good keeps the normal schedule.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Divider()
                        
                        ForEach(RepeatPolicy.allCases, id: \.self) { policy in
                            Button(action: {
                                card.ratingMedPolicy = policy
                            }) {
                                HStack {
                                    Text(policy.rawValue)
                                    if card.ratingMedPolicy == policy {
                                        Spacer()
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                        
                        Divider()
                        
                        VStack(alignment: .leading, spacing: 4) {
                            ForEach(RepeatPolicy.allCases, id: \.self) { policy in
                                Text("• \(policy.rawValue): \(policy.shortDescription(for: .good))")
                                    .font(.caption)
                            }
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Text("On Good:")
                            Text(card.ratingMedPolicy.rawValue)
                                .fontWeight(.semibold)
                        }
                        .font(.subheadline)
                    }
                    .menuActionDismissBehavior(.disabled)

                    Menu {
                        Text("Hard brings it back sooner for review.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Divider()
                        
                        ForEach(RepeatPolicy.allCases, id: \.self) { policy in
                            Button(action: {
                                card.ratingHardPolicy = policy
                            }) {
                                HStack {
                                    Text(policy.rawValue)
                                    if card.ratingHardPolicy == policy {
                                        Spacer()
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                        
                        Divider()
                        
                        VStack(alignment: .leading, spacing: 4) {
                            ForEach(RepeatPolicy.allCases, id: \.self) { policy in
                                Text("• \(policy.rawValue): \(policy.shortDescription(for: .hard))")
                                    .font(.caption)
                            }
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Text("On Hard:")
                            Text(card.ratingHardPolicy.rawValue)
                                .fontWeight(.semibold)
                        }
                        .font(.subheadline)
                    }
                    .menuActionDismissBehavior(.disabled)
                }
            }
        } label: {
            HStack {
                Image(systemName: "shield.lefthalf.fill")
                    .foregroundColor(.primary)
                Text("Policies")
                    .foregroundColor(.primary)
  
            }
            
            .font(.subheadline)
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color.secondary.opacity(0.5))
            )
            .contentShape(Rectangle())
        }
        .menuActionDismissBehavior(.disabled)
    }
}

struct RecurringButton: View {
    var isRecurring: Bool
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: "repeat")
                    .foregroundColor(isRecurring ? .white : .secondary)
                Text("Recurring")
                    .foregroundColor(isRecurring ? .white : .primary)
            }
            .font(.subheadline)
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(
                Group {
                    if isRecurring {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.accentColor)
                    } else {
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.secondary, lineWidth: 1.4)
                    }
                }
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

struct IntervalMenu: View {
    @Binding var selected: RepeatInterval
    var isRecurring: Bool
    var currentHours: Int // Current actual interval in hours
    
    // Compute display text from actual hours
    private var displayText: String {
        // Check if current hours match a predefined interval
        if let matchingInterval = RepeatInterval.allCases.first(where: { $0.hours == currentHours }) {
            return matchingInterval.rawValue
        }
        
        // Otherwise show the actual interval value
        if currentHours < 48 {
            return "\(currentHours)h"
        } else if currentHours < 168 {
            let days = currentHours / 24
            return "\(days)d"
        } else if currentHours < 720 {
            let weeks = currentHours / 168
            return "\(weeks)w"
        } else {
            let months = currentHours / 720
            return "\(months)mo"
        }
    }
    
    var body: some View {
        Menu {
            ForEach(RepeatInterval.allCases.filter { $0.hours != nil }, id: \.self) { interval in
                Button(action: { selected = interval }) {
                    Text(interval.rawValue)
                    if selected == interval {
                        Image(systemName: "checkmark")
                    }
                }
            }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "calendar")
                    .foregroundColor(isRecurring ? .primary : .secondary)
                Text(displayText)
                    .foregroundColor(isRecurring ? .primary : .secondary)
            }
            .font(.subheadline)
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color.secondary.opacity(0.5))
            )
            .contentShape(Rectangle())
        }
    }
}

struct PriorityMenu: View {
    @Binding var selected: PriorityType
    
    private func next(after current: PriorityType) -> PriorityType {
        switch current {
        case .none: return .low
        case .low: return .med
        case .med: return .high
        case .high: return .none
        }
    }
    
    var body: some View {
        Button {
            selected = next(after: selected)
        } label: {
            HStack(spacing: 4) {
                switch selected {
                case .none:
                    Image(systemName: "flag" )
                        .foregroundColor(.primary)
                    Image(systemName: "flag" )
                        .foregroundColor(.primary)
                    Image(systemName: "flag" )
                        .foregroundColor(.primary)
                case .low:
                    Image(systemName: "flag.fill")
                        .foregroundColor(.primary)
                    Image(systemName: "flag" )
                        .foregroundColor(.primary)
                    Image(systemName: "flag" )
                        .foregroundColor(.primary)
                case .med:
                    Image(systemName: "flag.fill")
                        .foregroundColor(.primary)
                    Image(systemName: "flag.fill" )
                        .foregroundColor(.primary)
                    Image(systemName: "flag" )
                        .foregroundColor(.primary)
                case .high:
                    Image(systemName: "flag.fill")
                        .foregroundColor(.primary)
                    Image(systemName: "flag.fill" )
                        .foregroundColor(.primary)
                    Image(systemName: "flag.fill" )
                        .foregroundColor(.primary)
                }
            }
            .font(.subheadline)
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color.secondary.opacity(0.5))
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
