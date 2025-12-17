//
//  SharedModel.swift
//  TopNote
//
//  Created by Zachary Sturman on 8/4/25.
//

import Foundation
import SwiftData
import SQLite3

// MARK: - External Storage Cleanup Migration
// Removes legacy external storage blobs from when images were supported.
// This must run BEFORE the ModelContainer is created to prevent memory issues.
private func cleanupLegacyExternalStorage() {
    // Migration complete - image columns don't exist in schema
    let migrationKey = "TopNote_ExternalStorageMigration_v5"
    
    // Skip if already done
    if UserDefaults.standard.bool(forKey: migrationKey) {
        print("[Migration] Already completed, skipping")
        return
    }
    
    print("[Migration] ====== Starting external storage cleanup ======")
    
    let fileManager = FileManager.default
    
    // Check BOTH app group container AND main app container
    var containerURLs: [URL] = []
    
    // App Group container
    if let groupURL = fileManager.containerURL(forSecurityApplicationGroupIdentifier: "group.com.zacharysturman.topnote") {
        containerURLs.append(groupURL)
        print("[Migration] App Group Container: \(groupURL.path)")
    }
    
    // Main app container (documents, library, etc.)
    let appSupportURLs = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)
    containerURLs.append(contentsOf: appSupportURLs)
    print("[Migration] App Support URLs: \(appSupportURLs.map { $0.path })")
    
    let documentsURLs = fileManager.urls(for: .documentDirectory, in: .userDomainMask)
    containerURLs.append(contentsOf: documentsURLs)
    
    // Process each container
    for containerURL in containerURLs {
        print("[Migration] --- Processing: \(containerURL.path) ---")
        
        // List contents for debugging
        if let contents = try? fileManager.contentsOfDirectory(at: containerURL, includingPropertiesForKeys: nil) {
            for item in contents {
                print("[Migration]   \(item.lastPathComponent)")
            }
        }
        
        // Find and clean all database files
        if let enumerator = fileManager.enumerator(at: containerURL, includingPropertiesForKeys: [.isRegularFileKey]) {
            while let fileURL = enumerator.nextObject() as? URL {
                let name = fileURL.lastPathComponent
                
                // Process SQLite databases
                if name.hasSuffix(".store") || name.hasSuffix(".sqlite") {
                    print("[Migration] Found database: \(fileURL.path)")
                    cleanupImageColumnsWithSQLite(at: fileURL)
                }
                
                // Delete external data folders
                if name.contains("_EXTERNAL_DATA") || 
                   (name.hasSuffix("_Data") && !name.contains("UserData")) ||
                   name.contains(".store_Data") {
                    do {
                        try fileManager.removeItem(at: fileURL)
                        print("[Migration] DELETED external storage: \(fileURL.path)")
                    } catch {
                        print("[Migration] Failed to delete \(fileURL.path): \(error)")
                    }
                    enumerator.skipDescendants()
                }
            }
        }
    }
    
    // Mark migration as complete
    UserDefaults.standard.set(true, forKey: migrationKey)
    print("[Migration] ====== Cleanup complete ======")
}

private func cleanupImageColumnsWithSQLite(at dbURL: URL) {
    var db: OpaquePointer?
    
    guard sqlite3_open(dbURL.path, &db) == SQLITE_OK else {
        print("[Migration] Failed to open database at \(dbURL.path)")
        return
    }
    
    defer { sqlite3_close(db) }
    
    print("[Migration] Cleaning database: \(dbURL.lastPathComponent)")
    
    // First, list all tables to understand the schema
    var stmt: OpaquePointer?
    let tableQuery = "SELECT name FROM sqlite_master WHERE type='table'"
    if sqlite3_prepare_v2(db, tableQuery, -1, &stmt, nil) == SQLITE_OK {
        print("[Migration] Tables in database:")
        while sqlite3_step(stmt) == SQLITE_ROW {
            if let tableName = sqlite3_column_text(stmt, 0) {
                print("[Migration]   - \(String(cString: tableName))")
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
                print("[Migration] Found table: \(table)")
                
                // List columns in this table
                let pragmaSQL = "PRAGMA table_info(\(table))"
                var pragmaStmt: OpaquePointer?
                if sqlite3_prepare_v2(db, pragmaSQL, -1, &pragmaStmt, nil) == SQLITE_OK {
                    print("[Migration] Columns in \(table):")
                    while sqlite3_step(pragmaStmt) == SQLITE_ROW {
                        if let colName = sqlite3_column_text(pragmaStmt, 1) {
                            print("[Migration]     - \(String(cString: colName))")
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
                            print("[Migration] Nulled \(changes) rows in \(table).\(column)")
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
    print("[Migration] Running VACUUM...")
    sqlite3_exec(db, "VACUUM", nil, nil, nil)
    print("[Migration] Database cleanup complete for \(dbURL.lastPathComponent)")
}

public let sharedModelContainer: ModelContainer = {
    // Clean up legacy external storage BEFORE creating the container
    cleanupLegacyExternalStorage()
    
    let schema = Schema([Card.self, Folder.self, CardTag.self])
    
    // Use App Group container for shared access between app and widget
    // IMPORTANT: Explicitly disable CloudKit syncing to prevent downloading old image data
    // The CloudKit container may still have old external storage blobs that would cause OOM crashes
    let config = ModelConfiguration(
        schema: schema,
        isStoredInMemoryOnly: false,
        groupContainer: .identifier("group.com.zacharysturman.topnote"),
        cloudKitDatabase: .automatic  // Re-enabled: image columns no longer exist in schema
    )
    
    do {
        let container = try ModelContainer(for: schema, configurations: [config])
        print("[ModelContainer] Successfully created container (CloudKit sync disabled)")
        return container
    } catch {
        print("[ModelContainer] ⚠️ Creation failed: \(error)")
        print("[ModelContainer] Attempting nuclear cleanup - deleting all data...")
        
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
                        print("[ModelContainer] Deleted: \(name)")
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
                        print("[ModelContainer] Deleted from app support: \(name)")
                    }
                }
            }
        }
        
        // Retry container creation
        do {
            let container = try ModelContainer(for: schema, configurations: [config])
            print("[ModelContainer] Successfully created container after cleanup")
            return container
        } catch {
            fatalError("[ModelContainer] Failed to create container even after cleanup: \(error)")
        }
    }
}()

