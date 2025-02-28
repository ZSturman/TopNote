////
////  QuizResultsTableView.swift
////  TopNote
////
////  Created by Zachary Sturman on 2/25/25.
////
//import SwiftUI
//struct QuizResultsTableView: View {
//    let quizResults: [QuizResult]
//    
//    private let dateFormatter: DateFormatter = {
//        let formatter = DateFormatter()
//        formatter.dateStyle = .short
//        formatter.timeStyle = .short
//        return formatter
//    }()
//    
//    var body: some View {
//        List {
//            Section(header: Text("Quiz Results").font(.headline)) {
//                if quizResults.isEmpty {
//                    Text("No Quiz Results Available")
//                        .foregroundColor(.secondary)
//                } else {
//                    ForEach(Array(quizResults.enumerated()), id: \.offset) { index, result in
//                        HStack {
//                            Text("\(index + 1).")
//                            Text(result.isCorrect ? "Correct" : "Incorrect")
//                            Spacer()
//                            Text(result.date, formatter: dateFormatter)
//                        }
//                    }
//                }
//            }
//        }
//        .listStyle(InsetGroupedListStyle())
//    }
//}
//
//struct QuizResultsTableView_Previews: PreviewProvider {
//    static var previews: some View {
//        let sampleResults = [
//            QuizResult(isCorrect: true, date: Date().addingTimeInterval(-3600)),
//            QuizResult(isCorrect: false, date: Date().addingTimeInterval(-1800)),
//            QuizResult(isCorrect: true, date: Date())
//        ]
//        QuizResultsTableView(quizResults: sampleResults)
//            .previewLayout(.sizeThatFits)
//    }
//}
