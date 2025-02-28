//
//  ResponsiveButtons+Icons.swift
//  TopNote
//
//  Created by Zachary Sturman on 2/27/25.
//

import Foundation
import SwiftUI

struct ResponsiveView<Content: View>: View {
    @State private var availableWidth: CGFloat = 0
    let content: (CGFloat) -> Content

    var body: some View {
        content(availableWidth)
            .background(
                GeometryReader { geometry in
                    Color.clear
                        .onAppear {
                            availableWidth = geometry.size.width
                        }
                        .onChange(of: geometry.size.width) { _, newWidth in
                            availableWidth = newWidth
                        }
                }
            )
    }
}
