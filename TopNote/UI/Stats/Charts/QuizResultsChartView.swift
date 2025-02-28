////
////  QuizResultsChartView.swift
////  TopNote
////
////  Created by Zachary Sturman on 2/25/25.
////
//
//import Foundation
//import SwiftUI
//import Charts
//
//// MARK: - Quiz Results Chart View
//
//struct QuizResultsChartView: View {
//    // Expect an array of quiz events.
//    let quizResults: [QuizResult]
//    
//    var body: some View {
//        Chart(quizResults) { result in
//            // Plot each result on a timeline:
//            // Y-value is 1 for correct answers, 0 for incorrect.
//            PointMark(
//                x: .value("Date", result.date),
//                y: .value("Result", result.isCorrect ? 1 : 0)
//            )
//            .foregroundStyle(result.isCorrect ? .green : .red)
//        }
//        .chartYAxis {
//            // Customize the y-axis to display labels.
//            AxisMarks(values: [0, 1]) { value in
//                AxisValueLabel {
//                    if let intValue = value.as(Int.self) {
//                        Text(intValue == 1 ? "Correct" : "Incorrect")
//                    }
//                }
//            }
//        }
//        .padding()
//    }
//}
//
//struct QuizResultsChartView_Previews: PreviewProvider {
//    static var previews: some View {
//        let sampleResults = [
//            QuizResult(isCorrect: true, date: Date().addingTimeInterval(-3600)),
//            QuizResult(isCorrect: false, date: Date().addingTimeInterval(-1800)),
//            QuizResult(isCorrect: true, date: Date())
//        ]
//        QuizResultsChartView(quizResults: sampleResults)
//            .previewLayout(.sizeThatFits)
//    }
//}
