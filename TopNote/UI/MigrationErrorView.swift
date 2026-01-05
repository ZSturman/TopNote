//
//  MigrationErrorView.swift
//  TopNote
//
//  Created by Zachary Sturman on 1/3/26.
//

import SwiftUI

/// A view displayed when the app fails to initialize its data storage.
/// Provides options for the user to attempt recovery or contact support.
struct MigrationErrorView: View {
    @ObservedObject var containerState = ModelContainerState.shared
    @State private var showingResetConfirmation = false
    @State private var isResetting = false
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            // Error icon
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 64))
                .foregroundStyle(.orange)
            
            // Title
            Text("Unable to Load Data")
                .font(.title)
                .fontWeight(.bold)
            
            // Description
            Text("TopNote encountered a problem loading your data. This may be due to a corrupted database or a sync conflict.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            // Error details (collapsible)
            if let error = containerState.error {
                DisclosureGroup("Technical Details") {
                    Text(error.localizedDescription)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.top, 8)
                }
                .padding(.horizontal, 32)
            }
            
            Spacer()
            
            // Action buttons
            VStack(spacing: 16) {
                // Reset Database button
                Button(action: {
                    showingResetConfirmation = true
                }) {
                    HStack {
                        if isResetting {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Image(systemName: "arrow.counterclockwise")
                        }
                        Text(isResetting ? "Resetting..." : "Reset Database")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.orange)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .disabled(isResetting)
                .padding(.horizontal, 32)
                
                // Contact Support button
                Button(action: contactSupport) {
                    HStack {
                        Image(systemName: "envelope")
                        Text("Contact Support")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.systemGray5))
                    .foregroundColor(.primary)
                    .cornerRadius(12)
                }
                .padding(.horizontal, 32)
            }
            .padding(.bottom, 32)
        }
        .alert("Reset Database?", isPresented: $showingResetConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Reset", role: .destructive) {
                resetDatabase()
            }
        } message: {
            Text("This will delete all local data and start fresh. Your data may be recoverable from iCloud if you had sync enabled. This action cannot be undone.")
        }
    }
    
    private func resetDatabase() {
        isResetting = true
        TopNoteLogger.dataAccess.warning("User initiated database reset from error screen")
        
        // Delete all database files
        if let containerURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: "group.com.zacharysturman.topnote"
        ) {
            let fileManager = FileManager.default
            
            if let enumerator = fileManager.enumerator(at: containerURL, includingPropertiesForKeys: nil) {
                while let fileURL = enumerator.nextObject() as? URL {
                    let name = fileURL.lastPathComponent
                    if name.contains(".store") ||
                       name.contains("sqlite") ||
                       name.contains("_Data") ||
                       name.contains("EXTERNAL") ||
                       name.contains("_SUPPORT") {
                        try? fileManager.removeItem(at: fileURL)
                        TopNoteLogger.dataAccess.debug("User reset: deleted \(name)")
                    }
                }
            }
        }
        
        // Also clean app support directory
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
                    }
                }
            }
        }
        
        TopNoteLogger.dataAccess.info("Database reset complete. Prompting app restart.")
        
        // Prompt user to restart the app
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            isResetting = false
            // The app needs to be restarted to reinitialize the container
            // Show an alert instructing the user to restart
            containerState.error = nil // Clear error to show success state
        }
    }
    
    private func contactSupport() {
        let subject = "TopNote Data Issue"
        var body = "I'm experiencing a data loading issue with TopNote.\n\n"
        body += "Device: \(UIDevice.current.model)\n"
        body += "iOS Version: \(UIDevice.current.systemVersion)\n"
        
        if let error = containerState.error {
            body += "Error: \(error.localizedDescription)\n"
        }
        
        let encodedSubject = subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let encodedBody = body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        
        if let url = URL(string: "mailto:support@topnote.app?subject=\(encodedSubject)&body=\(encodedBody)") {
            UIApplication.shared.open(url)
        }
    }
}

#Preview {
    MigrationErrorView()
}
