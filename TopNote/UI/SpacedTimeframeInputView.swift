import SwiftUI
import WidgetKit

struct SpacedTimeframeInputView: View {
    let card: Card
    var onFinished: () -> Void

    // Keep a copy of the original hours to allow canceling
    @State private var originalHours: Int = 0
    
    // Local state for the breakdown values
    @State private var selectedMonths: Int = 0
    @State private var selectedDays: Int = 0
    @State private var selectedHours: Int = 0
    
    @State private var newMonthsValue: Int?
    @State private var newDaysValue: Int?
    @State private var newHoursValue: Int?
    
    // A flag to ensure we initialize only once.
    @State private var didInitialize: Bool = false
    
    init(card: Card, onFinished: @escaping () -> Void) {
        self.card = card
        self.onFinished = onFinished
    }
    
    /// Convert a total number of hours into months, days, and hours.
    /// (Assuming 1 month = 720 hours and 1 day = 24 hours)
    private static func breakdownHours(_ totalHours: Int) -> (months: Int, days: Int, hours: Int) {
        let months = totalHours / 720
        let remainderAfterMonths = totalHours % 720
        let days = remainderAfterMonths / 24
        let hours = remainderAfterMonths % 24
        return (months, days, hours)
    }
    
    /// Convert months, days, and hours back into total hours.
    private func convertBackToHours(months: Int, days: Int, hours: Int) -> Int {
        (months * 720) + (days * 24) + hours
    }
    
    /// The total hours computed from the picker values.
    private var newTotalHours: Int {

        convertBackToHours(months: newMonthsValue ?? selectedMonths, days: newDaysValue ?? selectedDays, hours: newHoursValue ?? selectedHours)
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Select Timeframe")
                .font(.headline)
                .foregroundColor(.white)
            
            HStack(spacing: 0) {
                // Picker for months: 0...12
                Picker("Months", selection: $selectedMonths) {
                    ForEach(0...12, id: \.self) { month in
                        Text("\(month)").tag(month)
                    }
                }
                .pickerStyle(WheelPickerStyle())
                .frame(width: 100, height: 150)
                .clipped()
                .onChange(of: selectedMonths) { oldValue, newValue in
                    newMonthsValue = newValue
                }
                
                // Picker for days: 0...30
                Picker("Days", selection: $selectedDays) {
                    ForEach(0...30, id: \.self) { day in
                        Text("\(day)").tag(day)
                    }
                }
                .pickerStyle(WheelPickerStyle())
                .frame(width: 100, height: 150)
                .clipped()
                .onChange(of: selectedDays) { oldValue, newValue in
                    newDaysValue = newValue
                    print("Days changed from \(oldValue) to \(newValue)")
                }
                
                // Picker for hours: 0...23
                Picker("Hours", selection: $selectedHours) {
                    ForEach(0...23, id: \.self) { hour in
                        Text("\(hour)").tag(hour)
                    }
                }
                .pickerStyle(WheelPickerStyle())
                .frame(width: 100, height: 150)
                .clipped()
                .onChange(of: selectedHours) { oldValue, newValue in
                    newHoursValue = newValue
                    
                }
            }
            
            HStack {
                // Cancel button resets the local state to the original breakdown.
                Button(action: {
                    let breakdown = Self.breakdownHours(originalHours)
                    selectedMonths = breakdown.months
                    selectedDays = breakdown.days
                    selectedHours = breakdown.hours
                    onFinished()
                }) {
                    Text("Cancel")
                        .foregroundColor(.red)
                }
                .padding(.leading, 20)
                
                Spacer()
                
                // Done button converts the local state back into hours.
                Button(action: {
                    let updatedHours = newTotalHours
                    print("Updated Hours: \(updatedHours)")
                    
                    if updatedHours != card.spacedTimeFrame {
                        Task {
                            do {
                                print("New Hours: \(updatedHours)")
                                try await card.manuallyUpdateSpacedTimeFrame(newValue: updatedHours)
                                WidgetCenter.shared.reloadAllTimelines()
                                onFinished()
                            } catch {
                                print("Error updating spacedTimeFrame: \(error)")
                                onFinished()
                            }
                        }
                    } else {
                        print("newTotalHours: \(newTotalHours)")
                        print("updatedHours: \(updatedHours)")
                        print("they already match")
                        onFinished()
                    }
                }) {
                    Text("Done")
                        .foregroundColor(.green)
                }
                .padding(.trailing, 20)
            }
            .padding(.top, 10)
        }
        .onAppear {
            // Initialize only once so that any user changes remain intact.
            if !didInitialize {
                let breakdown = Self.breakdownHours(card.spacedTimeFrame)
                selectedMonths = breakdown.months
                selectedDays   = breakdown.days
                selectedHours  = breakdown.hours
                originalHours  = card.spacedTimeFrame
                didInitialize = true
                print("Months: \(selectedMonths)")
                print("Days: \(selectedDays)")
                print("SelectedHours: \(selectedHours)")
                print("Original Hours: \(originalHours)")
            }
        }
    }
}
