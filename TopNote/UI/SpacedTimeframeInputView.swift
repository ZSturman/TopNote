import SwiftUI
import WidgetKit

struct SpacedTimeframeInputView: View {
    var card: Card
    var onFinished: () -> Void
    
    
    @State private var timeValue: Int
    
    init(card: Card, onFinished: @escaping () -> Void) {
        self.card = card
        self.onFinished = onFinished
        _timeValue = State(initialValue: card.spacedTimeFrame)
    }
    
    @State private var isEditingTime: Bool = false
    @State private var isDays: Bool = false
    

    
    /// Computes the breakdown into months, days, and remaining hours.
    private var breakdown: (months: Int, days: Int, hours: Int) {
        let months = card.spacedTimeFrame / 720          // 720 hours in a month (30 days)
        let remainderAfterMonths = card.spacedTimeFrame % 720
        let days = remainderAfterMonths / 24
        let remainingHours = remainderAfterMonths % 24
        return (months, days, remainingHours)
    }
    
    /// Formatter for integer input.
    private var numberFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .none
        return formatter
    }
    
    private func formatTimeInterval(_ interval: TimeInterval) -> String {
        let secondsInMinute: Double = 60
        let secondsInHour: Double = 3600
        let secondsInDay: Double = 86400
        
        if interval >= secondsInDay {
            return String(format: "%.1f days", interval / secondsInDay)
        } else if interval >= secondsInHour {
            return String(format: "%.1f hours", interval / secondsInHour)
        } else {
            return String(format: "%.1f minutes", interval / secondsInMinute)
        }
    }
    
    var body: some View {
        
        if card.archived {
            Text("To put card back in rotation be sure to remove it from 'Archive'")
        }
        // Segmented control to switch between hours and days
        Picker("Unit", selection: $isDays) {
            Text("Hours").tag(false)
            Text("Days").tag(true)
        }
        .pickerStyle(SegmentedPickerStyle())
        .padding(.vertical, 5)
        
        Text("\(breakdown.months) months, \(breakdown.days) days, \(breakdown.hours) hours")
            .font(.caption)
            .foregroundColor(.gray)
            .padding(.horizontal)
        
        // Determine the range based on unit
        let range = isDays ? Array(1...365) : Array(1...8760)
        Picker("Time Value", selection: $timeValue) {
            ForEach(range, id: \.self) { value in
                Text("\(value)")
            }
        }
        .labelsHidden()
        .pickerStyle(WheelPickerStyle())
        .frame(height: 100)
        
        // Button to finish editing
        Button("Done") {
            // Convert timeValue to hours if unit is days
            let updatedTimeValue = isDays ? timeValue * 24 : timeValue
            if updatedTimeValue != card.spacedTimeFrame {
                Task {
                    do {
                        try await card.manuallyUpdateSpacedTimeFrame(newValue: updatedTimeValue)
                        WidgetCenter.shared.reloadAllTimelines()
                    } catch {
                        print("Error updating spaced time frame: \(error)")
                    }
                }
            }
            onFinished()
        }
        .padding(.top, 5)
        
        
    }
}
