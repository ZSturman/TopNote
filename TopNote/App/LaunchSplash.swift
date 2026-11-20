//
//  LaunchSplash.swift
//  TopNote
//
//  Picks up from the system launch screen (same background) and fans out the three cards from
//  the icon while the library opens.
//

import SwiftUI

struct LaunchSplash: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var fanned = false
    @State private var showsTitle = false

    static let firstLaunchHold = Duration.seconds(1.3)
    static let laterLaunchHold = Duration.seconds(0.45)
    private static let shownKey = "splash.shown.v2"

    /// The first launch of 2.0 holds long enough to read the name; later launches only flash it.
    /// VoiceOver users and UI tests never wait.
    static func hold(voiceOver: Bool) -> Duration {
        let arguments = ProcessInfo.processInfo.arguments
        if voiceOver || arguments.contains("-TopNoteSkipSplash") { return .zero }
        let firstLaunch = !UserDefaults.standard.bool(forKey: shownKey)
        UserDefaults.standard.set(true, forKey: shownKey)
        return firstLaunch ? firstLaunchHold : laterLaunchHold
    }

    var body: some View {
        ZStack {
            Color("LaunchBackground").ignoresSafeArea()
            VStack(spacing: 28) {
                CardFanMark(fanned: fanned || reduceMotion, size: 116)
                VStack(spacing: 6) {
                    Text("Top Note")
                        .font(.system(.largeTitle, design: .rounded, weight: .bold))
                        .foregroundStyle(.white)
                    Text("One thing at a time.")
                        .font(.headline)
                        .foregroundStyle(.white.opacity(0.85))
                }
                .opacity(showsTitle ? 1 : 0)
                .offset(y: showsTitle || reduceMotion ? 0 : 10)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Top Note. One thing at a time.")
        .accessibilityIdentifier("launchSplash")
        .onAppear {
            withAnimation(reduceMotion ? .easeIn(duration: 0.2) : .spring(duration: 0.65, bounce: 0.35)) { fanned = true }
            withAnimation(.easeOut(duration: 0.4).delay(reduceMotion ? 0 : 0.2)) { showsTitle = true }
        }
    }
}

#Preview {
    LaunchSplash()
}
