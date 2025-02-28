//
//  SkipTableView.swift
//  TopNote
//
//  Created by Zachary Sturman on 2/25/25.
//
import SwiftUI
struct SkipTableView: View {
    let skipCount: Int
    
    var body: some View {
        List {
            Section(header: Text("Skips").font(.headline)) {
                HStack {
                    Text("Skip Count")
                    Spacer()
                    Text("\(skipCount)")
                }
            }
        }
        .listStyle(InsetGroupedListStyle())
    }
}

struct SkipTableView_Previews: PreviewProvider {
    static var previews: some View {
        SkipTableView(skipCount: 3)
            .previewLayout(.sizeThatFits)
    }
}
