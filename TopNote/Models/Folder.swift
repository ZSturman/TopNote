import Foundation
import SwiftData
import AppIntents

@Model
final class Folder {
    var id: UUID = UUID()
    var name: String = ""
    
    @Relationship(deleteRule: .nullify)
    var cards: [Card]?
    
    var unwrappedCards: [Card] { cards ?? [] }
    
    init(name: String) {
        self.name = name
    }
}

// ——— satisfy Sendable so AppEntity (which inherits Sendable) will compile ———
extension Folder: @unchecked Sendable { }

// ——— Hashable conformance for Set usage ———
extension Folder: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: Folder, rhs: Folder) -> Bool {
        lhs.id == rhs.id
    }
}

// ——— AppIntents conformance in its own extension ———
extension Folder: AppEntity {
    // tie in your query
    static var defaultQuery: FolderQuery { .init() }
    
    // how “Folder” is shown in parameter pickers
    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        .init(name: LocalizedStringResource("Folder", table: "AppIntents"))
    }
    
    // how each Folder instance is rendered
    var displayRepresentation: DisplayRepresentation {
        .init(stringLiteral: name)
    }
}

// ——— your query logic, untouched except returning Folder itself ———
struct FolderQuery: EntityQuery, EnumerableEntityQuery {
    let container = sharedModelContainer

    func entities(for identifiers: [Folder.ID]) async throws -> [Folder] {
        let ctx = ModelContext(container)
        var all = try ctx.fetch(FetchDescriptor<Folder>())
        all.append(Folder.noFolder)
        guard !identifiers.isEmpty else { return all }
        return all.filter { identifiers.contains($0.id) }
    }

    func allEntities() async throws -> [Folder] {
        let ctx = ModelContext(container)
        let all = try ctx.fetch(FetchDescriptor<Folder>())
        return all + [Folder.noFolder]
    }

    func suggestedEntities() async throws -> [Folder] {
        try await allEntities()
    }

    func defaultResult() async -> Folder? {
        try? await suggestedEntities().first
    }
}

