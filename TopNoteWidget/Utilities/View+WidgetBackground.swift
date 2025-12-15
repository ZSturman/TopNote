//
//  View+WidgetBackground.swift
//  TopNote
//
//  Created by Zachary Sturman on 12/13/25.
//

import SwiftUI
import WidgetKit

extension View {
    func widgetBackground(backgroundView: some View) -> some View {
        if #available(iOSApplicationExtension 17.0, *) {
            return containerBackground(for: .widget) {
                backgroundView
            }
        } else {
            return background(backgroundView)
        }
    }
}
