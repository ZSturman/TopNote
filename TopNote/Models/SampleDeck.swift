import Foundation

struct SampleDeck {
    static func create() -> (folders: [Folder], extraCards: [Card], tags: [Tag]) {
        // Create Tags
        let geographyTag = Tag(name: "Geography")
        let scienceTag = Tag(name: "Science")
        let workTag = Tag(name: "Work")
        let mathTag = Tag(name: "Math")
        let literatureTag = Tag(name: "Literature")
        let natureTag = Tag(name: "Nature")
        
        let tags = [geographyTag, scienceTag, workTag, mathTag, literatureTag, natureTag]
        
        // Folder with no cards.
        let emptyFolder = Folder(name: "Empty Folder")
        
        // Folder with cards of all card types.
        let allTypesFolder = Folder(name: "All Card Types Folder")
        
        // Folder with only a few card types.
        let fewTypesFolder = Folder(name: "Few Card Types Folder")
        
        // MARK: - Cards for the "All Card Types Folder"
        
        // Flash Card
        let flashCard = Card(
            createdAt: Date(),
            cardType: .flashCard,
            priorityTypeRaw: .med,
            content: "What is the capital of Italy?",
            isEssential: false,
            skipCount: 0,
            seenCount: 0,
            timeOnTop: nil,
            timeInQueue: nil,
            addedOnTop: nil,
            addedToQueue: nil,
            spacedTimeFrame: 48, // 48 hours
            dynamicTimeframe: true,
            nextTimeInQueue: Date(timeIntervalSinceNow: -3600), // enqueued (1 hour ago)
            lastRemovedFromQueue: nil,
            folder: allTypesFolder,
            tags: [geographyTag],
            //toDos: [],
            back: "Rome",
            //potentialAnswers: [:],
            rating: [],
            //isCorrect: [],
            archived: false,
            hasBeenFlipped: false
        )
    
        
        // No Card Type
        let noType = Card(
            createdAt: Date(),
            cardType: .none,
            priorityTypeRaw: .none,
            content: "A scenic view of the mountains",
            isEssential: false,
            skipCount: 0,
            seenCount: 0,
            timeOnTop: nil,
            timeInQueue: nil,
            addedOnTop: nil,
            addedToQueue: nil,
            spacedTimeFrame: 96, // 96 hours
            dynamicTimeframe: true,
            nextTimeInQueue: Date(timeIntervalSinceNow: 3 * 3600), // not enqueued (3 hours in future)
            lastRemovedFromQueue: nil,
            folder: allTypesFolder,
            tags: [natureTag],
            //toDos: [],
            back: nil,
            //potentialAnswers: [:],
            rating: [],
            //isCorrect: [],
            archived: true,
            hasBeenFlipped: false
        )
        
        // Add all cards to the folder.
        if allTypesFolder.cards == nil {
            allTypesFolder.cards = [flashCard, noType]
        } else {
            allTypesFolder.cards?.append(contentsOf: [flashCard, noType])
        }
        
        // MARK: - Cards for the "Few Card Types Folder"
        
        // Flash Card
        let fewFlashCard = Card(
            createdAt: Date(),
            cardType: .flashCard,
            priorityTypeRaw: .med,
            content: "What is 5 + 3?",
            isEssential: false,
            skipCount: 0,
            seenCount: 0,
            timeOnTop: nil,
            timeInQueue: nil,
            addedOnTop: nil,
            addedToQueue: nil,
            spacedTimeFrame: 12, // 12 hours
            dynamicTimeframe: true,
            nextTimeInQueue: Date(timeIntervalSinceNow: -3600), // enqueued
            lastRemovedFromQueue: nil,
            folder: fewTypesFolder,
            tags: [mathTag],
            //toDos: [],
            back: "8",
            //potentialAnswers: [:],
            rating: [],
            //isCorrect: [],
            archived: false,
            hasBeenFlipped: false
        )
        

        
        if fewTypesFolder.cards == nil {
            fewTypesFolder.cards = [fewFlashCard, noType]
        } else {
            fewTypesFolder.cards?.append(contentsOf: [fewFlashCard, noType])
        }
        
        // MARK: - Extra Cards with no folder
        
        let extraFlashCard = Card(
            createdAt: Date(),
            cardType: .flashCard,
            priorityTypeRaw: .high,
            content: "Who wrote 'To be, or not to be'?",
            isEssential: false,
            skipCount: 0,
            seenCount: 0,
            timeOnTop: nil,
            timeInQueue: nil,
            addedOnTop: nil,
            addedToQueue: nil,
            spacedTimeFrame: 60, // 60 hours
            dynamicTimeframe: true,
            nextTimeInQueue: Date(timeIntervalSinceNow: -3600), // enqueued
            lastRemovedFromQueue: nil,
            folder: nil,
            tags: [literatureTag],
            //toDos: [],
            back: "William Shakespeare",
            //potentialAnswers: [:],
            rating: [],
            //isCorrect: [],
            archived: true,
            hasBeenFlipped: false
        )
    
        
        let extraCards = [extraFlashCard]
        
        return (folders: [emptyFolder, allTypesFolder, fewTypesFolder], extraCards: extraCards, tags: tags)
    }
    
    func addCard(_ card: Card, to folder: Folder) {
        if folder.cards == nil {
            folder.cards = [card]
        } else {
            folder.cards?.append(card)
        }
    }
}
