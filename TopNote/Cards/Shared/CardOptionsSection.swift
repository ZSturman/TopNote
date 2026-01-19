//
//  CardOptionsSection.swift
//  TopNote
//
//  Created by Zachary Sturman on 12/20/25.
//

import SwiftUI

/// A reusable component for card scheduling and policy options.
/// Used in both NewCardSheet and AICardGeneratorSheet.
struct CardOptionsSection: View {
    let cardType: CardType
    
    // Schedule bindings
    @Binding var priority: PriorityType
    @Binding var isRecurring: Bool
    @Binding var repeatInterval: RepeatInterval
    
    // Policy bindings
    @Binding var skipEnabled: Bool
    @Binding var skipPolicy: RepeatPolicy
    @Binding var resetRepeatIntervalOnComplete: Bool
    
    // Rating policy bindings (flashcard only)
    @Binding var ratingEasyPolicy: RepeatPolicy
    @Binding var ratingMedPolicy: RepeatPolicy
    @Binding var ratingHardPolicy: RepeatPolicy
    
    var body: some View {
        Group {
            // MARK: - Schedule Options
            // Priority
            Picker("Priority", selection: $priority) {
                ForEach(PriorityType.allCases) { p in
                    Text(p.rawValue).tag(p)
                }
            }
            
            // Recurring toggle
            Toggle("Recurring", isOn: $isRecurring)
            
            // Interval picker
            Picker("Repeat Interval", selection: $repeatInterval) {
                ForEach(RepeatInterval.allCases.filter { $0.hours != nil }, id: \.self) { interval in
                    Text(interval.rawValue).tag(interval)
                }
            }
            
            // MARK: - Policy Options
            // Skip settings
            Toggle("Enable Skip", isOn: $skipEnabled)
            
            if skipEnabled {
                Picker("On Skip", selection: $skipPolicy) {
                    ForEach(RepeatPolicy.allCases, id: \.self) { policy in
                        Text(policy.rawValue).tag(policy)
                    }
                }
            }
            
            // Todo-specific: reset interval on complete
            if cardType == .todo {
                Toggle("Reset Interval On Complete", isOn: $resetRepeatIntervalOnComplete)
                    .disabled(!isRecurring)
            }
            
            // Flashcard-specific: rating policies
            if cardType == .flashcard {
                Picker("On Easy", selection: $ratingEasyPolicy) {
                    ForEach(RepeatPolicy.allCases, id: \.self) { policy in
                        Text(policy.rawValue).tag(policy)
                    }
                }
                
                // Note: "Good" rating maintains current interval (no policy adjustment)
                HStack {
                    Text("On Good")
                    Spacer()
                    Text("Keeps current schedule")
                        .foregroundStyle(.secondary)
                }
                
                Picker("On Hard", selection: $ratingHardPolicy) {
                    ForEach(RepeatPolicy.allCases, id: \.self) { policy in
                        Text(policy.rawValue).tag(policy)
                    }
                }
            }
        }
    }
}

// MARK: - Helper for default values based on card type

extension CardOptionsSection {
    /// Returns type-specific default values for card options
    static func defaults(for cardType: CardType) -> CardOptionDefaults {
        switch cardType {
        case .flashcard:
            return CardOptionDefaults(
                isRecurring: true,
                repeatInterval: .every2Months,
                skipEnabled: false,
                skipPolicy: .none,
                resetRepeatIntervalOnComplete: false,
                ratingEasyPolicy: .mild,
                ratingMedPolicy: .none,
                ratingHardPolicy: .aggressive
            )
        case .todo:
            return CardOptionDefaults(
                isRecurring: true,
                repeatInterval: .monthly,
                skipEnabled: true,
                skipPolicy: .aggressive,
                resetRepeatIntervalOnComplete: true,
                ratingEasyPolicy: .mild,
                ratingMedPolicy: .none,
                ratingHardPolicy: .aggressive
            )
        case .note:
            return CardOptionDefaults(
                isRecurring: true,
                repeatInterval: .every4Months,
                skipEnabled: true,
                skipPolicy: .mild,
                resetRepeatIntervalOnComplete: false,
                ratingEasyPolicy: .mild,
                ratingMedPolicy: .none,
                ratingHardPolicy: .aggressive
            )
        }
    }
}

/// Container for card option default values
struct CardOptionDefaults {
    let isRecurring: Bool
    let repeatInterval: RepeatInterval
    let skipEnabled: Bool
    let skipPolicy: RepeatPolicy
    let resetRepeatIntervalOnComplete: Bool
    let ratingEasyPolicy: RepeatPolicy
    let ratingMedPolicy: RepeatPolicy
    let ratingHardPolicy: RepeatPolicy
}
