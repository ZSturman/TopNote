////
////  ToDoWidgetView.swift
////  TopNoteWidgetExtension
////
////  Created by Zachary Sturman on 2/25/25.
////
//
//import Foundation
//import SwiftUI
//import WidgetKit
//
//struct ToDoWidgetView: View {
//    let toDoGrouptitle: String
//    let toDos: [ToDo]
//    let isAllComplete: Bool
//    
//    let isEssential: Bool
//    
//    @State private var todoCompletionStates: [String: Bool] = [:]
//    
//    // Computed property to sort to-dos: incomplete first, completed at the bottom.
//    var sortedToDos: [ToDo] {
//        toDos.sorted { first, second in
//            let firstCompleted = todoCompletionStates["\(first.id)"] ?? false
//            let secondCompleted = todoCompletionStates["\(second.id)"] ?? false
//            if firstCompleted == secondCompleted {
//                // Fallback ordering (using the id's string representation for consistency)
//                return "\(first.id)" < "\(second.id)"
//            }
//            // Incomplete ones come first
//            return !firstCompleted && secondCompleted
//        }
//    }
//    
//    var body: some View {
//      
//            VStack(alignment: .leading) {
//                Text(toDoGrouptitle)
//                    .font(.subheadline)
//                    .bold()
//                    .lineLimit(1)
//                    .truncationMode(.tail)
//                
//                // Display each ToDo item in the sorted order.
//                ForEach(Array(sortedToDos.prefix(3)), id: \.id) { todo in
//                    let key = "\(todo.id)"
//                    Button(intent: ToggleToDoIntent(toDoId: key)) {
//                        HStack {
//                            Image(systemName: (todoCompletionStates[key] ?? false) ? "checkmark.circle.fill" : "circle")
//                                .foregroundColor((todoCompletionStates[key] ?? false) ? .green : .red)
//                            Text(todo.content)
//                                .font(.footnote)
//                                .lineLimit(1)
//                                .truncationMode(.tail)
//                        }
//                    }
//                    .buttonStyle(.borderless)
//                }
//                
//                // Display status or new button based on completion states.
//                if toDos.isEmpty {
//                    Button(intent: CompleteAllIntent()) {
//                        Text("Nothing to do")
//                            .font(.footnote)
//                    }
//                    .buttonStyle(.bordered)
//                } else if toDos.allSatisfy({ todoCompletionStates["\($0.id)"] ?? false }) {
//                    VStack(alignment: .leading, spacing: 4) {
//                        Text("All ToDos Completed")
//                            .font(.footnote)
//                            .foregroundColor(.green)
//                        Button(intent: CompleteAllIntent()) {
//                            Text("Done")
//                                .font(.footnote)
//                        }
//                        .buttonStyle(.bordered)
//                    }
//                }
//            }
//            .onAppear {
//                // Initialize local state for each ToDo item from UserDefaults.
//                var states: [String: Bool] = [:]
//                for todo in toDos {
//                    let key = "\(todo.id)"
//                    states[key] = UserDefaults.standard.bool(forKey: key)
//                }
//                todoCompletionStates = states
//            }
//        
//    }
//}
//
//
//struct ToDoWidgetView_Previews: PreviewProvider {
//    static let sampleToDos: [ToDo] = [
//        .dummy(content: "Buy milk"),
//        .dummy(content: "Walk the dog"),
//        .dummy(content: "Call mom"),
//        .dummy(content: "Another thing")
//    ]
//    
//    static let taskContent: String = "Daily Tasks with a somewhat long title to see how it wraps"
//    
//    static let isAllComplete: Bool = false
//    
//    static let isEssential: Bool = true
//    
//    static var previews: some View {
//        Group {
//            // Small widget preview
//            ToDoWidgetView(
//                toDoGrouptitle: taskContent,
//                toDos: sampleToDos,
//                isAllComplete: isAllComplete,
//                isEssential:  isEssential
//            )
//            .containerBackground(for: .widget) {
//                Color(.tertiarySystemFill)
//            }
//            .previewContext(WidgetPreviewContext(family: .systemSmall))
//            .previewDisplayName("ToDo Widget - Small")
//            
//            // Medium widget preview
//            ToDoWidgetView(
//                toDoGrouptitle: taskContent,
//                toDos: sampleToDos,
//                isAllComplete: isAllComplete,
//                isEssential:  isEssential
//            )
//            .containerBackground(for: .widget) {
//                Color(.tertiarySystemFill)
//            }
//            .previewContext(WidgetPreviewContext(family: .systemMedium))
//            .previewDisplayName("ToDo Widget - Medium")
//            
//            // Large widget preview
//            ToDoWidgetView(
//                toDoGrouptitle: taskContent,
//                toDos: sampleToDos,
//                isAllComplete: isAllComplete,
//                isEssential:  isEssential
//            )
//            .containerBackground(for: .widget) {
//                Color(.tertiarySystemFill)
//            }
//            .previewContext(WidgetPreviewContext(family: .systemLarge))
//            .previewDisplayName("ToDo Widget - Large")
//            
//            // Extra Large widget preview
//            ToDoWidgetView(
//                toDoGrouptitle: taskContent,
//                toDos: sampleToDos,
//                isAllComplete: isAllComplete,
//                isEssential:  isEssential
//            )
//            .containerBackground(for: .widget) {
//                Color(.tertiarySystemFill)
//            }
//            .previewContext(WidgetPreviewContext(family: .systemExtraLarge))
//            .previewDisplayName("ToDo Widget - Extra Large")
//        }
//    }
//}
