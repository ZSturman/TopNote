//
//  CardFilterMenu.swift
//  TopNote
//
//  Created by Zachary Sturman on 11/27/25.
//

import SwiftUI

struct CardFilterMenu: View {
    @Binding var selectedOptions: [CardFilterOption]

    var body: some View {
        Menu {
            Section("Type") {
                ForEach(CardFilterOption.typeFilters, id: \.self) { option in
                    let isTypeSelected = selectedOptions.contains(option)
                    let numSelectedTypes = selectedOptions.filter { CardFilterOption.typeFilters.contains($0) }.count
                    Button(action: {
                        if let idx = selectedOptions.firstIndex(of: option) {
                            selectedOptions.remove(at: idx)
                        } else {
                            selectedOptions.append(option)
                        }
                    }) {
                        Label(
                            option.localizedName,
                            systemImage: isTypeSelected ? "checkmark.circle.fill" : "circle"
                        )
                    }
                    .disabled(isTypeSelected && numSelectedTypes == 1)
                }
            }
            Section("Status") {
                ForEach(CardFilterOption.statusFilters, id: \.self) { option in
                    Button(action: {
                        if let idx = selectedOptions.firstIndex(of: option) {
                            selectedOptions.remove(at: idx)
                        } else {
                            selectedOptions.append(option)
                        }
                    }) {
                        Label(
                            option.localizedName,
                            systemImage: selectedOptions.contains(option)
                                ? "checkmark.circle.fill" : "circle"
                        )
                    }
                }
            }
            Section("Attributes") {
                ForEach(CardFilterOption.attributeFilters, id: \.self) { option in
                    Button(action: {
                        if let idx = selectedOptions.firstIndex(of: option) {
                            selectedOptions.remove(at: idx)
                        } else {
                            selectedOptions.append(option)
                        }
                    }) {
                        Label(
                            option.localizedName,
                            systemImage: selectedOptions.contains(option)
                                ? "checkmark.circle.fill" : "circle"
                        )
                    }
                }
            }
        } label: {
            Label("Filter", systemImage: "line.3.horizontal.decrease.circle")
        }
        .menuActionDismissBehavior(.disabled)
        .accessibilityIdentifier("Filter")
    }
}

