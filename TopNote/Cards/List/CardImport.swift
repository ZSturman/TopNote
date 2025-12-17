//
//  CardImport.swift
//  TopNote
//
//  Created by Zachary Sturman on 11/27/25.
//

import Foundation
import SwiftData

enum CardImport {
    static func makeCard(from dict: [String: Any], context: ModelContext)
        -> Card?
    {
        // Helper: Folder lookup or creation by name
        func folderForName(_ name: String) -> Folder? {
            guard !name.isEmpty else { return nil }
            let request = FetchDescriptor<Folder>(
                predicate: #Predicate { $0.name == name }
            )
            if let found = try? context.fetch(request).first { return found }
            let f = Folder(name: name)
            context.insert(f)
            return f
        }

        // Helper: Tag lookup or creation by name
        func tagsForNames(_ names: [String]) -> [CardTag] {
            names.compactMap { tagName in
                guard !tagName.isEmpty else { return nil }
                let req = FetchDescriptor<CardTag>(
                    predicate: #Predicate { $0.name == tagName }
                )
                if let found = try? context.fetch(req).first { return found }
                let t = CardTag(name: tagName)
                context.insert(t)
                return t
            }
        }

        // Extract and sanitize fields with defaults using separate let bindings
        let rawCardType: String
        if let str = dict["cardType"] as? String {
            rawCardType = str
        } else {
            rawCardType = "todo"
        }
        let cardType = CardType(caseInsensitiveRawValue: rawCardType)

        let contentValue: String
        if let contentStr = dict["content"] as? String, !contentStr.isEmpty {
            contentValue = contentStr
        } else {
            contentValue = "Untitled"
        }

        let answerValue: String?
        if cardType == .flashcard {
            if let ans = dict["answer"] as? String, !ans.isEmpty {
                answerValue = ans
            } else {
                answerValue = "(No answer)"
            }
        } else {
            answerValue = nil
        }

        let createdAtValue: Date
        if let createdStr = dict["createdAt"] as? String,
            let date = ISO8601DateFormatter().date(from: createdStr)
        {
            createdAtValue = date
        } else {
            createdAtValue = Date()
        }

        let nextTimeInQueueValue: Date
        if let nextTimeStr = dict["nextTimeInQueue"] as? String,
            let date = ISO8601DateFormatter().date(from: nextTimeStr)
        {
            nextTimeInQueueValue = date
        } else {
            nextTimeInQueueValue = Date()
        }

        // Updated logic for defaults based on cardType

        // isRecurring
        let isRecurringValue: Bool = {
            if let val = dict["isRecurring"] as? Bool {
                return val
            } else {
                return true
            }
        }()

        // repeatInterval
        let repeatIntervalValue: Int = {
            if let val = dict["repeatInterval"] as? Int {
                return val
            } else {

                return 720

            }
        }()

        // initialRepeatInterval
        let initialRepeatIntervalValue: Int = {
            if let val = dict["initialRepeatInterval"] as? Int {
                return val
            } else {

                return repeatIntervalValue

            }
        }()

        // folder
        let folderNameValue: String
        if let val = dict["folder"] as? String {
            folderNameValue = val
        } else {
            folderNameValue = ""
        }
        let folderValue = folderForName(folderNameValue)

        // tags
        let tagNamesValue: [String]
        if let val = dict["tags"] as? [String] {
            tagNamesValue = val
        } else {
            tagNamesValue = []
        }
        let tagsValue = tagsForNames(tagNamesValue)

        // isArchived
        let isArchivedValue: Bool
        if let val = dict["isArchived"] as? Bool {
            isArchivedValue = val
        } else {
            isArchivedValue = false
        }

        // skipPolicy
        let skipPolicyValue: RepeatPolicy = {
            if let val = dict["skipPolicy"] as? String,
                let policy = RepeatPolicy(rawValue: val)
            {
                return policy
            } else {
                switch cardType {
                case .flashcard:
                    return .none
                case .todo:
                    return .aggressive
                default:
                    return .mild
                }
            }
        }()

        // ratingEasyPolicy
        let ratingEasyPolicyValue: RepeatPolicy = {
            if let val = dict["ratingEasyPolicy"] as? String,
                let policy = RepeatPolicy(rawValue: val)
            {
                return policy
            } else {
                if cardType == .flashcard {
                    return .mild
                } else {
                    // For other types, no default mentioned, keep as .mild for safety
                    return .mild
                }
            }
        }()

        // ratingMedPolicy
        let ratingMedPolicyValue: RepeatPolicy = {
            if let val = dict["ratingMedPolicy"] as? String,
                let policy = RepeatPolicy(rawValue: val)
            {
                return policy
            } else {
                if cardType == .flashcard {
                    return .none
                } else {
                    return .none
                }
            }
        }()

        // ratingHardPolicy
        let ratingHardPolicyValue: RepeatPolicy = {
            if let val = dict["ratingHardPolicy"] as? String,
                let policy = RepeatPolicy(rawValue: val)
            {
                return policy
            } else {
                if cardType == .flashcard {
                    return .aggressive
                } else {
                    return .aggressive
                }
            }
        }()

        // isComplete
        let isCompleteValue: Bool
        if let val = dict["isComplete"] as? Bool {
            isCompleteValue = val
        } else {
            isCompleteValue = false
        }

        // answerRevealed (always false for flashcard, else default false)
        let answerRevealedValue: Bool = {
            if cardType == .flashcard {
                return false
            } else {
                if let val = dict["answerRevealed"] as? Bool {
                    return val
                } else {
                    return false
                }
            }
        }()

        // resetRepeatIntervalOnComplete
        let resetRepeatIntervalOnCompleteValue: Bool = {
            if let val = dict["resetRepeatIntervalOnComplete"] as? Bool {
                return val
            } else {
                if cardType == .todo {
                    return true
                } else {
                    return true
                }
            }
        }()

        // skipEnabled
        let skipEnabledValue: Bool = {
            if let val = dict["skipEnabled"] as? Bool {
                return val
            } else {
                switch cardType {
                case .flashcard:
                    return true
                case .todo:
                    return true
                default:
                    return false
                }
            }
        }()

        let ratingValue: [[RatingType: Date]] = []
        
        // Extract image data from base64 strings
        let contentImageDataValue: Data? = {
            if let base64String = dict["contentImageBase64"] as? String {
                return Data(base64Encoded: base64String)
            }
            return nil
        }()
        
        let answerImageDataValue: Data? = {
            if let base64String = dict["answerImageBase64"] as? String {
                return Data(base64Encoded: base64String)
            }
            return nil
        }()

        return Card(
            createdAt: createdAtValue,
            cardType: cardType,
            priorityTypeRaw: .none,
            content: contentValue,
            isRecurring: isRecurringValue,
            skipCount: dict["skipCount"] as? Int ?? 0,
            seenCount: dict["seenCount"] as? Int ?? 0,
            repeatInterval: repeatIntervalValue,
            initialRepeatInterval: initialRepeatIntervalValue,
            nextTimeInQueue: nextTimeInQueueValue,
            folder: folderValue,
            tags: tagsValue,
            answer: answerValue,
            rating: ratingValue,
            isArchived: isArchivedValue,
            answerRevealed: answerRevealedValue,
            skipPolicy: skipPolicyValue,
            ratingEasyPolicy: ratingEasyPolicyValue,
            ratingMedPolicy: ratingMedPolicyValue,
            ratingHardPolicy: ratingHardPolicyValue,
            isComplete: isCompleteValue,
            resetRepeatIntervalOnComplete: resetRepeatIntervalOnCompleteValue,
            skipEnabled: skipEnabledValue
        )
    }
    
    static func parseCSV(_ csvString: String, context: ModelContext) throws -> [Card] {
        var cards: [Card] = []
        let lines = csvString.components(separatedBy: "\n").filter { !$0.isEmpty }
        
        guard lines.count > 1 else {
            throw NSError(domain: "CSV", code: 1, userInfo: [NSLocalizedDescriptionKey: "CSV file is empty or has no data rows"])
        }
        
        // Parse header to get column indices
        let header = lines[0].components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        
        // Helper: Folder lookup or creation by name
        func folderForName(_ name: String) -> Folder? {
            guard !name.isEmpty else { return nil }
            let request = FetchDescriptor<Folder>(
                predicate: #Predicate { $0.name == name }
            )
            if let found = try? context.fetch(request).first { return found }
            let f = Folder(name: name)
            context.insert(f)
            return f
        }
        
        // Helper: Tag lookup or creation by name
        func tagsForNames(_ names: [String]) -> [CardTag] {
            names.compactMap { tagName in
                guard !tagName.isEmpty else { return nil }
                let req = FetchDescriptor<CardTag>(
                    predicate: #Predicate { $0.name == tagName }
                )
                if let found = try? context.fetch(req).first { return found }
                let t = CardTag(name: tagName)
                context.insert(t)
                return t
            }
        }
        
        for line in lines.dropFirst() {
            let values = line.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            
            guard values.count == header.count else { continue }
            
            var dict: [String: String] = [:]
            for (index, key) in header.enumerated() {
                dict[key] = values[index]
            }
            
            // Parse required fields
            let cardType = CardType(caseInsensitiveRawValue: dict["cardType"] ?? "todo")
            let content = dict["content"]?.isEmpty == false ? dict["content"]! : "Untitled"
            let answer = cardType == .flashcard ? (dict["answer"]?.isEmpty == false ? dict["answer"] : "(No answer)") : nil
            
            let createdAt = ISO8601DateFormatter().date(from: dict["createdAt"] ?? "") ?? Date()
            let nextTimeInQueue = ISO8601DateFormatter().date(from: dict["nextTimeInQueue"] ?? "") ?? Date()
            
            let isRecurring = Bool(dict["isRecurring"] ?? "true") ?? true
            let repeatInterval = Int(dict["repeatInterval"] ?? "") ?? 720
            let initialRepeatInterval = Int(dict["initialRepeatInterval"] ?? "") ?? repeatInterval
            
            let folderName = dict["folder"] ?? ""
            let folder = folderForName(folderName)
            
            let tagNames = (dict["tags"] ?? "").components(separatedBy: ";").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
            let tags = tagsForNames(tagNames)
            
            let isArchived = Bool(dict["isArchived"] ?? "false") ?? false
            
            let skipPolicy = RepeatPolicy(rawValue: dict["skipPolicy"] ?? "") ?? (cardType == .flashcard ? .none : cardType == .todo ? .aggressive : .mild)
            let ratingEasyPolicy = RepeatPolicy(rawValue: dict["ratingEasyPolicy"] ?? "") ?? .mild
            let ratingMedPolicy = RepeatPolicy(rawValue: dict["ratingMedPolicy"] ?? "") ?? .none
            let ratingHardPolicy = RepeatPolicy(rawValue: dict["ratingHardPolicy"] ?? "") ?? .aggressive
            
            let isComplete = Bool(dict["isComplete"] ?? "false") ?? false
            let answerRevealed = cardType == .flashcard ? false : (Bool(dict["answerRevealed"] ?? "false") ?? false)
            let resetRepeatIntervalOnComplete = Bool(dict["resetRepeatIntervalOnComplete"] ?? "") ?? (cardType == .todo)
            let skipEnabled = Bool(dict["skipEnabled"] ?? "") ?? (cardType != .flashcard)
            
            let card = Card(
                createdAt: createdAt,
                cardType: cardType,
                priorityTypeRaw: .none,
                content: content,
                isRecurring: isRecurring,
                skipCount: Int(dict["skipCount"] ?? "0") ?? 0,
                seenCount: Int(dict["seenCount"] ?? "0") ?? 0,
                repeatInterval: repeatInterval,
                initialRepeatInterval: initialRepeatInterval,
                nextTimeInQueue: nextTimeInQueue,
                folder: folder,
                tags: tags,
                answer: answer,
                rating: [],
                isArchived: isArchived,
                answerRevealed: answerRevealed,
                skipPolicy: skipPolicy,
                ratingEasyPolicy: ratingEasyPolicy,
                ratingMedPolicy: ratingMedPolicy,
                ratingHardPolicy: ratingHardPolicy,
                isComplete: isComplete,
                resetRepeatIntervalOnComplete: resetRepeatIntervalOnComplete,
                skipEnabled: skipEnabled
            )
            
            cards.append(card)
        }
        
        return cards
    }
}
