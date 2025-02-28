//
//  ReadOnlySpacedTimeframe.swift
//  TopNote
//
//  Created by Zachary Sturman on 2/27/25.
//

import Foundation

import SwiftUI

struct ReadOnlySpacedTimeframe: View {
    
    var card: Card
    
    /// Computes the breakdown into months, days, and remaining hours.
    private var breakdown: (months: Int, days: Int, hours: Int) {
        let months = card.spacedTimeFrame / 720          // 720 hours in a month (30 days)
        let remainderAfterMonths = card.spacedTimeFrame % 720
        let days = remainderAfterMonths / 24
        let remainingHours = remainderAfterMonths % 24
        return (months, days, remainingHours)
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
        VStack {
            HStack {
                if card.archived {
                    HStack {
                        
                        Spacer()
                        Text("Removed from queue rotation")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Spacer()
                    }
                } else {
                    if !card.isEnqueue(currentDate: Date()) {
                        
                        
                        
                        
                        
                        
                        
                        
                        let timeRemaining = card.timeUntilNextInQueue(currentDate: Date())
                        let formattedTime = formatTimeInterval(timeRemaining)
                        Text("Enqueued in: \(formattedTime)")
                            .font(.caption)
                        Spacer()
                        Text("\(breakdown.months) months, \(breakdown.days) days, \(breakdown.hours) hours")
                            .font(.caption)
                        
                            .padding(.horizontal)
                        
                    }
                    
                }
                
                
                Spacer()
                Text("\(breakdown.months) months, \(breakdown.days) days, \(breakdown.hours) hours")
                    .font(.caption)
            }
            
            
            
        }
    }
}
