//
//  TodoCardWidgetView.swift
//  TopNote
//
//  Created by Zachary Sturman on 12/13/25.
//

import SwiftUI
import WidgetKit

struct TodoCardWidgetView: View {
    let content: String
    @Environment(\.widgetFamily) private var widgetFamily

    init(content: String) {
        self.content = content
    }

    private func isLongOrMultiline(_ text: String?) -> Bool {
        guard let text else { return false }
        let newlineCount = text.filter { $0 == "\n" }.count
        return newlineCount > 2 || text.count > 280
    }

    var body: some View {
        VStack(spacing: 8) {
            HStack(alignment: .top, spacing: 8) {
                Spacer()
                Text(content)
                    .font(.body)
                    .multilineTextAlignment(isLongOrMultiline(content) ? .leading : .center)
                    .minimumScaleFactor(0.7)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Spacer()
            }
        }
        .padding(6)
    }
}
