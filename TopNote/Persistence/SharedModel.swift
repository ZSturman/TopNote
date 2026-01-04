//
//  SharedModel.swift
//  TopNote
//
//  Created by Zachary Sturman on 8/4/25.
//

import Foundation
import SwiftData
import SQLite3
import os.log

// MARK: - External Storage Cleanup Migration
// Removes legacy external storage blobs from when images were supported.
// This must run BEFORE the ModelContainer is created to prevent memory issues.
private func cleanupLegacyExternalStorage() {
    // Migration complete - image columns don't exist in schema
    let migrationKey = "TopNote_ExternalStorageMigration_v5"
    
    // Skip if already done
    if UserDefaults.standard.bool(forKey: migrationKey) {
        TopNoteLogger.migration.debug("External storage cleanup already completed, skipping")
        return
    }
    
    TopNoteLogger.migration.info("Starting external storage cleanup")
    
    let fileManager = FileManager.default
    
    // Check BOTH app group container AND main app container
    var containerURLs: [URL] = []
    
    // App Group container
    if let groupURL = fileManager.containerURL(forSecurityApplicationGroupIdentifier: "group.com.zacharysturman.topnote") {
        containerURLs.append(groupURL)
        TopNoteLogger.migration.debug("App Group Container: \(groupURL.path)")
    }
    
    // Main app container (documents, library, etc.)
    let appSupportURLs = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)
    containerURLs.append(contentsOf: appSupportURLs)
    TopNoteLogger.migration.debug("App Support URLs: \(appSupportURLs.map { $0.path })")
    
    let documentsURLs = fileManager.urls(for: .documentDirectory, in: .userDomainMask)
    containerURLs.append(contentsOf: documentsURLs)
    
    // Process each container
    for containerURL in containerURLs {
        TopNoteLogger.migration.debug("Processing container: \(containerURL.path)")
        
        // List contents for debugging
        if let contents = try? fileManager.contentsOfDirectory(at: containerURL, includingPropertiesForKeys: nil) {
            for item in contents {
                TopNoteLogger.migration.debug("  Found item: \(item.lastPathComponent)")
            }
        }
        
        // Find and clean all database files
        if let enumerator = fileManager.enumerator(at: containerURL, includingPropertiesForKeys: [.isRegularFileKey]) {
            while let fileURL = enumerator.nextObject() as? URL {
                let name = fileURL.lastPathComponent
                
                // Process SQLite databases
                if name.hasSuffix(".store") || name.hasSuffix(".sqlite") {
                    TopNoteLogger.migration.info("Found database: \(fileURL.path)")
                    cleanupImageColumnsWithSQLite(at: fileURL)
                }
                
                // Delete external data folders
                if name.contains("_EXTERNAL_DATA") || 
                   (name.hasSuffix("_Data") && !name.contains("UserData")) ||
                   name.contains(".store_Data") {
                    do {
                        try fileManager.removeItem(at: fileURL)
                        TopNoteLogger.migration.info("Deleted external storage: \(fileURL.path)")
                    } catch {
                        TopNoteLogger.migration.error("Failed to delete \(fileURL.path): \(error.localizedDescription)")
                    }
                    enumerator.skipDescendants()
                }
            }
        }
    }
    
    // Mark migration as complete
    UserDefaults.standard.set(true, forKey: migrationKey)
    TopNoteLogger.migration.info("External storage cleanup complete")
}

private func cleanupImageColumnsWithSQLite(at dbURL: URL) {
    var db: OpaquePointer?
    
    guard sqlite3_open(dbURL.path, &db) == SQLITE_OK else {
        TopNoteLogger.migration.error("Failed to open database at \(dbURL.path)")
        return
    }
    
    defer { sqlite3_close(db) }
    
    TopNoteLogger.migration.debug("Cleaning database: \(dbURL.lastPathComponent)")
    
    // First, list all tables to understand the schema
    var stmt: OpaquePointer?
    let tableQuery = "SELECT name FROM sqlite_master WHERE type='table'"
    if sqlite3_prepare_v2(db, tableQuery, -1, &stmt, nil) == SQLITE_OK {
        TopNoteLogger.migration.debug("Scanning tables in database")
        while sqlite3_step(stmt) == SQLITE_ROW {
            if let tableName = sqlite3_column_text(stmt, 0) {
                TopNoteLogger.migration.debug("  Found table: \(String(cString: tableName))")
            }
        }
    }
    sqlite3_finalize(stmt)
    
    // SwiftData uses Z-prefixed table names (CoreData convention)
    let tablesToCheck = ["ZCARD", "Card", "card", "CARD"]
    let columnsToNull = [
        "ZCONTENTIMAGEDATA", "ZANSWERIMAGEDATA",
        "contentImageData", "answerImageData",
        "ZCONTENTIMAGE", "ZANSWERIMAGE",
        "contentImage", "answerImage"
    ]
    
    for table in tablesToCheck {
        // First check if table exists
        let checkSQL = "SELECT name FROM sqlite_master WHERE type='table' AND name='\(table)'"
        var checkStmt: OpaquePointer?
        if sqlite3_prepare_v2(db, checkSQL, -1, &checkStmt, nil) == SQLITE_OK {
            if sqlite3_step(checkStmt) == SQLITE_ROW {
                TopNoteLogger.migration.debug("Found table: \(table)")
                
                // List columns in this table
                let pragmaSQL = "PRAGMA table_info(\(table))"
                var pragmaStmt: OpaquePointer?
                if sqlite3_prepare_v2(db, pragmaSQL, -1, &pragmaStmt, nil) == SQLITE_OK {
                    TopNoteLogger.migration.debug("Scanning columns in \(table)")
                    while sqlite3_step(pragmaStmt) == SQLITE_ROW {
                        if let colName = sqlite3_column_text(pragmaStmt, 1) {
                            TopNoteLogger.migration.debug("    Column: \(String(cString: colName))")
                        }
                    }
                }
                sqlite3_finalize(pragmaStmt)
                
                // NULL out image columns
                for column in columnsToNull {
                    let sql = "UPDATE \(table) SET \(column) = NULL WHERE \(column) IS NOT NULL"
                    var errMsg: UnsafeMutablePointer<CChar>?
                    
                    let result = sqlite3_exec(db, sql, nil, nil, &errMsg)
                    if result == SQLITE_OK {
                        let changes = sqlite3_changes(db)
                        if changes > 0 {
                            TopNoteLogger.migration.info("Nulled \(changes) rows in \(table).\(column)")
                        }
                    }
                    if let errMsg = errMsg {
                        sqlite3_free(errMsg)
                    }
                }
            }
        }
        sqlite3_finalize(checkStmt)
    }
    
    // Vacuum to reclaim space
    TopNoteLogger.migration.debug("Running VACUUM...")
    sqlite3_exec(db, "VACUUM", nil, nil, nil)
    TopNoteLogger.migration.info("Database cleanup complete for \(dbURL.lastPathComponent)")
}

// MARK: - Model Container Error Handling

/// Errors that can occur during model container initialization
public enum ModelContainerError: LocalizedError {
    case creationFailed(underlying: Error)
    case recoveryFailed(underlying: Error)
    
    public var errorDescription: String? {
        switch self {
        case .creationFailed(let error):
            return "Unable to load your data: \(error.localizedDescription)"
        case .recoveryFailed(let error):
            return "Unable to recover data after cleanup: \(error.localizedDescription)"
        }
    }
}

/// Observable state for tracking model container initialization errors
public class ModelContainerState: ObservableObject {
    public static let shared = ModelContainerState()
    
    @Published public var error: ModelContainerError? = nil
    @Published public var isRecovering: Bool = false
    
    private init() {}
}

/// Result of model container initialization
public enum ModelContainerResult {
    case success(ModelContainer)
    case failure(ModelContainerError)
}

/// Attempts to create the shared model container with graceful error handling
private func createModelContainer() -> ModelContainerResult {
    // Clean up legacy external storage BEFORE creating the container
    cleanupLegacyExternalStorage()
    
    let schema = Schema([Card.self, Folder.self, CardTag.self])
    
    // Use App Group container for shared access between app and widget
    let config = ModelConfiguration(
        schema: schema,
        isStoredInMemoryOnly: false,
        groupContainer: .identifier("group.com.zacharysturman.topnote"),
        cloudKitDatabase: .automatic
    )
    
    do {
        let container = try ModelContainer(for: schema, configurations: [config])
        TopNoteLogger.dataAccess.info("Successfully created model container")
        return .success(container)
    } catch {
        TopNoteLogger.dataAccess.error("Model container creation failed: \(error.localizedDescription)")
        TopNoteLogger.dataAccess.warning("Attempting recovery by deleting corrupted data...")
        
        // NUCLEAR OPTION: Delete the entire database and recreate
        if let containerURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: "group.com.zacharysturman.topnote"
        ) {
            let fileManager = FileManager.default
            
            // Find and delete ALL database-related files
            if let enumerator = fileManager.enumerator(at: containerURL, includingPropertiesForKeys: nil) {
                while let fileURL = enumerator.nextObject() as? URL {
                    let name = fileURL.lastPathComponent
                    if name.contains(".store") || 
                       name.contains("sqlite") || 
                       name.contains("_Data") ||
                       name.contains("EXTERNAL") ||
                       name.contains("_SUPPORT") {
                        try? fileManager.removeItem(at: fileURL)
                        TopNoteLogger.dataAccess.debug("Deleted during recovery: \(name)")
                    }
                }
            }
        }
        
        // Also check main app support directory
        let appSupportURLs = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)
        for appSupportURL in appSupportURLs {
            if let enumerator = FileManager.default.enumerator(at: appSupportURL, includingPropertiesForKeys: nil) {
                while let fileURL = enumerator.nextObject() as? URL {
                    let name = fileURL.lastPathComponent
                    if name.contains(".store") || 
                       name.contains("sqlite") || 
                       name.contains("_Data") ||
                       name.contains("EXTERNAL") {
                        try? FileManager.default.removeItem(at: fileURL)
                        TopNoteLogger.dataAccess.debug("Deleted from app support during recovery: \(name)")
                    }
                }
            }
        }
        
        // Retry container creation
        do {
            let container = try ModelContainer(for: schema, configurations: [config])
            TopNoteLogger.dataAccess.info("Successfully created container after recovery")
            return .success(container)
        } catch let recoveryError {
            TopNoteLogger.dataAccess.critical("Failed to create container even after recovery: \(recoveryError.localizedDescription)")
            return .failure(.recoveryFailed(underlying: recoveryError))
        }
    }
}

/// The shared model container. Access via `sharedModelContainerResult` to handle potential errors.
public let sharedModelContainerResult: ModelContainerResult = createModelContainer()

/// Convenience accessor for successful container initialization.
/// Falls back to an in-memory container if initialization failed, allowing the app to show an error UI.
public let sharedModelContainer: ModelContainer = {
    switch sharedModelContainerResult {
    case .success(let container):
        return container
    case .failure(let error):
        // Store the error for UI display
        DispatchQueue.main.async {
            ModelContainerState.shared.error = error
        }
        TopNoteLogger.dataAccess.critical("Using fallback in-memory container due to initialization failure")
        
        // Return an in-memory container as fallback so the app can launch and show error UI
        let schema = Schema([Card.self, Folder.self, CardTag.self])
        let fallbackConfig = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true
        )
        do {
            return try ModelContainer(for: schema, configurations: [fallbackConfig])
        } catch {
            // This should never happen with in-memory container, but handle gracefully
            TopNoteLogger.dataAccess.critical("Even in-memory container failed: \(error.localizedDescription)")
            // Last resort: return a minimal container
            return try! ModelContainer(for: Card.self, Folder.self, CardTag.self)
        }
    }
}()
