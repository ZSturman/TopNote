//
//  SelectedCardStatView.swift
//  TopNote
//
//  Created by Zachary Sturman on 2/27/25.
//

import Foundation
import SwiftUI

struct SelectedCardStatView: View {
    let card: Card
    var body: some View {
        VStack {
            Text("Selected Card here")
            Text(card.content)
        }
    }
}
