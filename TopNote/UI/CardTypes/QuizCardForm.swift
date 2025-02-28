//import SwiftUI
//
//struct QuizCardForm: View {
//    @Environment(\.modelContext) private var modelContext
//
//    var card: Card
//
//    // Local state for the option text fields.
//    @State private var tempOptions: [String] = ["", ""]
//    // Saved state for the index of the correct answer.
//    @State private var correctAnswer: Int = 0
//
//    var body: some View {
//        VStack {
//            Section(header: Text("Multiple Choice")) {
//                TextField("Type question here...", text: Binding(
//                    get: { card.content },
//                    set: { newValue in
//                        card.content = newValue
//                        try? modelContext.save()
//                    }
//                ))
//                
//                ForEach(tempOptions.indices, id: \.self) { index in
//                    HStack {
//                        // Toggle is bound to whether this row is the correct answer.
//                        Toggle(isOn: Binding(
//                            get: { index == correctAnswer },
//                            set: { newValue in
//                                if newValue {
//                                    correctAnswer = index
//                                } else if index == correctAnswer {
//                                    // If toggling off the current correct answer,
//                                    // advance correctAnswer (wrap back to 0 if needed).
//                                    correctAnswer = (correctAnswer + 1) % tempOptions.count
//                                }
//                                updateCorrectAnswers()
//                            }
//                        )) {
//                            EmptyView()
//                        }
//                        .toggleStyle(SwitchToggleStyle(tint: .green))
//                        
//                        // Text field for the answer.
//                        TextField("Add an option", text: Binding(
//                            get: { tempOptions[index] },
//                            set: { newValue in
//                                updateOption(at: index, with: newValue)
//                            }
//                        ))
//                        .frame(maxWidth: .infinity, alignment: .leading)
//                        
//                        // Delete button appears on the right when more than 2 answers exist.
//                        if canDeleteOption() {
//                            Button(action: {
//                                deleteOption(at: index)
//                            }) {
//                                Image(systemName: "minus.circle")
//                                    .foregroundColor(.red)
//                            }
//                        }
//                    }
//                }
//                
//                // Add Option button appears only if fewer than 4 answers exist.
//                if tempOptions.count < 4 {
//                    Button(action: addOption) {
//                        HStack {
//                            Image(systemName: "plus.circle")
//                            Text("Add Option")
//                        }
//                    }
//                    .padding(.top, 8)
//                }
//            }
//        }
//        .onAppear {
//            if card.potentialAnswers.isEmpty {
//                // Start with at least two answer rows.
//                tempOptions = ["", ""]
//                // Initialize dictionary entries.
//                for (i, answer) in tempOptions.enumerated() {
//                    card.potentialAnswers[answer] = (i == correctAnswer)
//                }
//            } else {
//                // Use the stored answers (order is not guaranteed).
//                tempOptions = Array(card.potentialAnswers.keys)
//                if tempOptions.count < 2 {
//                    tempOptions.append("")
//                }
//            }
//            // Ensure a valid correct answer index.
//            if let index = tempOptions.firstIndex(where: { card.potentialAnswers[$0] == true }) {
//                correctAnswer = index
//            } else {
//                correctAnswer = 0
//                updateCorrectAnswers()
//            }
//        }
//    }
//    
//    private func updateOption(at index: Int, with newValue: String) {
//        let oldValue = tempOptions[index]
//        tempOptions[index] = newValue
//        
//        // Get the current answers, update, and assign back.
//        var answers = card.potentialAnswers
//        if oldValue != newValue {
//            answers.removeValue(forKey: oldValue)
//        }
//        answers[newValue] = (index == correctAnswer)
//        card.potentialAnswers = answers
//        try? modelContext.save()
//    }
//    /// Ensures that only the option at correctAnswer is marked correct.
//    private func updateCorrectAnswers() {
//        for i in tempOptions.indices {
//            card.potentialAnswers[tempOptions[i]] = (i == correctAnswer)
//        }
//        try? modelContext.save()
//    }
//    
//    /// Returns true if deletion is allowed (i.e. more than 2 answers exist).
//    private func canDeleteOption() -> Bool {
//        return tempOptions.count > 2
//    }
//    
//    private func deleteOption(at index: Int) {
//        tempOptions.remove(at: index)
//        
//        // Adjust correctAnswer if necessary.
//        if index == correctAnswer {
//            correctAnswer = (correctAnswer >= tempOptions.count) ? 0 : correctAnswer
//        } else if index < correctAnswer {
//            correctAnswer -= 1
//        }
//        
//        // Build a new dictionary and assign it back.
//        var newAnswers = [String: Bool]()
//        for i in tempOptions.indices {
//            newAnswers[tempOptions[i]] = (i == correctAnswer)
//        }
//        card.potentialAnswers = newAnswers
//        try? modelContext.save()
//    }
//    
//    /// Appends a new empty option (up to 4 total).
//    private func addOption() {
//        if tempOptions.count < 4 {
//            tempOptions.append("")
//            card.potentialAnswers[""] = false
//            try? modelContext.save()
//        }
//    }
//}
