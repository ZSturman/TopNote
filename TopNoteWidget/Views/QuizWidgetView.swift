////
////  QuizWidgetView.swift
////  TopNoteWidgetExtension
////
////  Created by Zachary Sturman on 2/25/25.
////
//import Foundation
//import SwiftUI
//import WidgetKit
//
//struct QuizWidgetView: View {
//    @Environment(\.widgetFamily) var family
//    
//    let question: String
//    let potentialAnswers: [String: Bool]
//    let hasBeenAnswered: Bool
//    let isEssential: Bool
//    
//    // Sorted keys for consistent ordering.
//    var answerKeys: [String] {
//        Array(potentialAnswers.keys).sorted()
//    }
//    
//    // Local state is loaded from shared storage.
//    @State private var selectedAnswer: String = UserDefaults.standard.string(forKey: "selectedAnswer") ?? ""
//    @State private var isAnswerCorrect: Bool = UserDefaults.standard.bool(forKey: "isAnswerCorrect")
//    
//    var body: some View {
//        VStack(spacing: 4) {
//            
//            // Top: Question
//            Text(question)
//                .font(.subheadline)
//                .bold()
//                .multilineTextAlignment(.center)
//                .lineLimit(2)
//                .minimumScaleFactor(0.6)
//                .padding(.top, 6)
//            
//            // Middle: Answers or result
//            if !hasBeenAnswered {
//                switch family {
//                case .systemSmall:
//                    smallAnswersView
//                case .systemMedium:
//                    mediumAnswersView
//                default:
//                    // Fallback for larger widget families
//                    mediumAnswersView
//                }
//            } else {
//                answeredView
//            }
//            
//            Spacer(minLength: 0)
//            
//            // Bottom: Skip/Next button
//            SkipOrNextButton(isEssential: isEssential)
//                .padding(.bottom, 6)
//        }
//        .padding(.horizontal, 6)
//        .containerBackground(.fill.tertiary, for: .widget)
//        .onAppear {
//            // Load interactive state and store potential answers.
//            selectedAnswer = UserDefaults.standard.string(forKey: "selectedAnswer") ?? ""
//            isAnswerCorrect = UserDefaults.standard.bool(forKey: "isAnswerCorrect")
//            UserDefaults.standard.set(potentialAnswers, forKey: "potentialAnswers")
//        }
//    }
//    
//    // MARK: - Small Widget Layout
//    private var smallAnswersView: some View {
//        Group {
//            // If you have 2 or fewer answers, a single row is fine;
//            // if 3 or 4 answers, show them in a 2×2 grid.
//            if answerKeys.count <= 2 {
//                HStack(spacing: 4) {
//                    ForEach(answerKeys, id: \.self) { answer in
//                        answerButton(answer)
//                    }
//                }
//            } else {
//                let columns = [
//                    GridItem(.flexible()),
//                    GridItem(.flexible())
//                ]
//                LazyVGrid(columns: columns, spacing: 4) {
//                    ForEach(answerKeys, id: \.self) { answer in
//                        answerButton(answer)
//                    }
//                }
//            }
//        }
//    }
//    
//    // MARK: - Medium Widget Layout
//    private var mediumAnswersView: some View {
//        // A 2×2 grid works well for 2–4 answers on medium.
//        let columns = [
//            GridItem(.flexible()),
//            GridItem(.flexible())
//        ]
//        return LazyVGrid(columns: columns, spacing: 8) {
//            ForEach(answerKeys, id: \.self) { answer in
//                answerButton(answer)
//            }
//        }
//    }
//    
//    // MARK: - Single Answer Button
//    private func answerButton(_ answer: String) -> some View {
//        Button(intent: SelectAnswerIntent(selectedAnswer: answer)) {
//            Text(answer)
//                .font(.footnote)
//                .foregroundColor(.blue)
//                .lineLimit(1)
//                .minimumScaleFactor(0.8)
//                .frame(maxWidth: .infinity)
//                .padding(6)
//                .background(Color(UIColor.secondarySystemBackground))
//                .cornerRadius(6)
//        }
//    }
//    
//    // MARK: - Answered View
//    private var answeredView: some View {
//        VStack(spacing: 4) {
//            Image(systemName: "rosette")
//            Text(selectedAnswer)
//                .font(.footnote)
//                .foregroundColor(isAnswerCorrect ? .green : .red)
//            if isAnswerCorrect {
//                Image(systemName: "rosette")
//            } else {
//                Text("Incorrect")
//                    .font(.footnote)
//                if let correctAnswer = potentialAnswers.first(where: { $0.value })?.key {
//                    Text("Correct Answer: \(correctAnswer)")
//                        .font(.footnote)
//                        .foregroundColor(.green)
//                }
//            }
//            
//            // "Done" button for answered state
//            Button(intent: NextCardIntent()) {
//                Text("Done")
//                    .font(.footnote)
//            }
//            .buttonStyle(.bordered)
//        }
//    }
//}
//
//struct QuizWidgetView_Previews: PreviewProvider {
//    static let samplePotentialAnswers: [String: Bool] = [
//        "Paris": true,
//        "London": false,
//        "Berlin": false,
//        "Rome": false
//    ]
//    static let question: String = "What is the capital of France?"
//    
//    static var previews: some View {
//        Group {
//            // Unanswered, small
//            QuizWidgetView(
//                question: question,
//                potentialAnswers: samplePotentialAnswers,
//                hasBeenAnswered: false,
//                isEssential: false
//            )
//            .previewContext(WidgetPreviewContext(family: .systemSmall))
//            .previewDisplayName("Small - Unanswered")
//            
//            // Answered, small
//            QuizWidgetView(
//                question: question,
//                potentialAnswers: samplePotentialAnswers,
//                hasBeenAnswered: true,
//                isEssential: true
//            )
//            .previewContext(WidgetPreviewContext(family: .systemSmall))
//            .previewDisplayName("Small - Answered")
//            
//            // Unanswered, medium
//            QuizWidgetView(
//                question: question,
//                potentialAnswers: samplePotentialAnswers,
//                hasBeenAnswered: false,
//                isEssential: false
//            )
//            .previewContext(WidgetPreviewContext(family: .systemMedium))
//            .previewDisplayName("Medium - Unanswered")
//            
//            // Answered, medium
//            QuizWidgetView(
//                question: question,
//                potentialAnswers: samplePotentialAnswers,
//                hasBeenAnswered: true,
//                isEssential: true
//            )
//            .previewContext(WidgetPreviewContext(family: .systemMedium))
//            .previewDisplayName("Medium - Answered")
//        }
//    }
//}
//
////
////// MARK: - SkipOrNextButton (unchanged)
////struct SkipOrNextButton: View {
////    var isEssential: Bool
////    var widgetSize: WidgetFamily? = .systemMedium
////    
////    var body: some View {
////        if widgetSize == .systemSmall {
////            if isEssential {
////                Button(intent: SkipCardIntent()) {
////                    Image(systemName: "clock.arrow.trianglehead.2.counterclockwise.rotate.90")
////                        .font(.footnote)
////                }
////                .buttonStyle(.bordered)
////                .frame(width: 44, height: 44)
////                .buttonBorderShape(.circle)
////            } else {
////                Button(intent: NextCardIntent()) {
////                    Image(systemName: "rectangle.on.rectangle.angled")
////                        .font(.footnote)
////                }
////                .buttonStyle(.bordered)
////                .frame(width: 44, height: 44)
////                .buttonBorderShape(.circle)
////            }
////        } else {
////            if isEssential {
////                Button(intent: SkipCardIntent()) {
////                    HStack {
////                        Spacer()
////                        Image(systemName: "clock.arrow.trianglehead.2.counterclockwise.rotate.90")
////                        Text("Skip")
////                        Spacer()
////                    }
////                    .font(.footnote)
////                }
////                .buttonStyle(.bordered)
////            } else {
////                Button(intent: NextCardIntent()) {
////                    HStack {
////                        Spacer()
////                        Image(systemName: "rectangle.on.rectangle.angled")
////                        Text("Next")
////                        Spacer()
////                    }
////                    .font(.footnote)
////                }
////                .buttonStyle(.bordered)
////            }
////        }
////    }
////}
