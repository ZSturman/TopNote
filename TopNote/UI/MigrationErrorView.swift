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
            Text("Top Note will set the unreadable library aside in a recovery folder on this device and start fresh. Cards synced with iCloud download again.")
        }
    }
    
    private func resetDatabase() {
        isResetting = true
        TopNoteLogger.dataAccess.warning("User initiated database reset from error screen")
        
        // Keep a recovery copy of the unreadable library instead of deleting it.
        preserveUnreadableStore()
        
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
