//
//  NextButton.swift
//  TopNote
//
//  Created by Zachary Sturman on 1/7/26.
//

import SwiftUI

struct NextButtonUI: View {
    
    var body: some View {
        ZStack {
            Circle()
                .fill(Color.blue.opacity(0.85))
                .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
            Image(systemName: "checkmark.rectangle.stack")
                .font(.caption)
                .foregroundColor(.white)
        }
    }
}

struct SkipButtonUI: View {
    
    var body: some View {
        ZStack {
            Circle()
                .fill(Color.orange.opacity(0.85))
                .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
            Image(systemName: "arrow.trianglehead.counterclockwise.rotate.90")
                .font(.caption)
                .foregroundColor(.white)
        }
    }
}
