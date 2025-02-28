////
////  ToDoCard.swift
////  TopNote
////
////  Created by Zachary Sturman on 2/18/25.
////
//
//import SwiftUI
//import SwiftData
//
//struct ToDoCardForm: View {
//    @Environment(\.modelContext) private var modelContext
//
//    var card: Card
//
//    // Local state to manage the task text fields.
//    @State private var tempTasks: [String] = [""]
//
//    var body: some View {
//        Form {
//            Section(header: Text("To-Do List")) {
//                TextField("Type group title here...", text: Binding(
//                    get: { card.content },
//                    set: { newValue in
//                        card.content = newValue
//                        try? modelContext.save()
//                    }
//                ))
//                
//                ForEach(tempTasks.indices, id: \.self) { index in
//                    HStack {
//                        Button(action: {
//                            completeTask(for: tempTasks[index])
//                        }) {
//                            Image(systemName: isTaskComplete(taskName: tempTasks[index])
//                                  ? "checkmark.circle.fill" : "circle")
//                                .foregroundColor(isTaskComplete(taskName: tempTasks[index])
//                                  ? .green : .gray)
//                        }
//                        .buttonStyle(BorderlessButtonStyle())
//                        
//                        TextField("Add a task", text: Binding(
//                            get: { tempTasks[index] },
//                            set: { newValue in
//                                updateTask(at: index, with: newValue)
//                            }
//                        ))
//                    }
//                }
//            }
//        }
//        .onAppear {
//            // Sort the card's toDos and sync the temporary tasks with the card's toDos.
//            card.sortToDos()
//            if card.toDos.isEmpty {
//                tempTasks = [""]
//            } else {
//                tempTasks = card.toDos.compactMap { task in
//                    switch task {
//                    case let .task(_, content, _):
//                        return content
//                    }
//                }
//                if tempTasks.last != "" {
//                    tempTasks.append("")
//                }
//            }
//        }
//    }
//    
//    private func updateTask(at index: Int, with newValue: String) {
//        let trimmedValue = newValue.trimmingCharacters(in: .whitespaces)
//        let oldValue = tempTasks[index]
//        tempTasks[index] = newValue
//        
//        if !trimmedValue.isEmpty {
//            if let taskIndex = card.toDos.firstIndex(where: {
//                switch $0 {
//                case let .task(_, content, _):
//                    return content == oldValue
//                }
//            }) {
//                // Update the task's content manually.
//                if case let .task(id, _, isComplete) = card.toDos[taskIndex] {
//                    card.toDos[taskIndex] = .task(id: id, content: trimmedValue, isComplete: isComplete)
//                }
//            } else {
//                // Use the extension function to add a new ToDo.
//                card.addToDo(content: trimmedValue)
//            }
//        } else if !oldValue.isEmpty {
//            // Use the extension function to delete the ToDo.
//            if let taskIndex = card.toDos.firstIndex(where: {
//                switch $0 {
//                case let .task(_, content, _):
//                    return content == oldValue
//                }
//            }) {
//                let task = card.toDos[taskIndex]
//                card.deleteToDo(withId: task.id)
//            }
//        }
//        
//        // After updating, sort the tasks and save the context.
//        card.sortToDos()
//        try? modelContext.save()
//        
//        // Ensure an extra empty field is always available.
//        if !trimmedValue.isEmpty, tempTasks.last?.isEmpty == false {
//            tempTasks.append("")
//        }
//    }
//    
//    private func completeTask(for taskName: String) {
//        guard !taskName.isEmpty else { return }
//        if let taskIndex = card.toDos.firstIndex(where: {
//            switch $0 {
//            case let .task(_, content, _):
//                return content == taskName
//            }
//        }) {
//            let task = card.toDos[taskIndex]
//            // Only mark as complete if not already complete.
//            if !task.isComplete {
//                card.markToDoComplete(withId: task.id)
//                // Sort the tasks after toggling completion.
//                card.sortToDos()
//                try? modelContext.save()
//            }
//        }
//    }
//    
//    private func isTaskComplete(taskName: String) -> Bool {
//        if let taskIndex = card.toDos.firstIndex(where: {
//            switch $0 {
//            case let .task(_, content, _):
//                return content == taskName
//            }
//        }) {
//            if case let .task(_, _, isComplete) = card.toDos[taskIndex] {
//                return isComplete
//            }
//        }
//        return false
//    }
//}
