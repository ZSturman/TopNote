//
//  OnboardingView.swift
//  TopNote
//
//  Three short pages for people new to Top Note, and What's New for people upgrading from 1.x.
//

import SwiftUI
import SwiftData

struct OnboardingView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Environment(AppRouter.self) private var router
    @Query private var cards: [Card]
    @State private var page = 0

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $page) {
                introPage.tag(0)
                kindsPage.tag(1)
                everywherePage.tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .indexViewStyle(.page(backgroundDisplayMode: .always))

            VStack(spacing: 10) {
                if page < 2 {
                    Button {
                        withAnimation { page += 1 }
                    } label: {
                        Text("Continue").frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .accessibilityIdentifier("onboardingContinue")
                } else {
                    Button {
                        finish()
                        router.capture(.note)
                    } label: {
                        Text("Capture my first card").frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .accessibilityIdentifier("onboardingCapture")
                    if cards.isEmpty {
                        Button {
                            CardFactory.insertExamples(into: context)
                            finish()
                        } label: {
                            Text("Try it with examples").frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.large)
                        .accessibilityIdentifier("onboardingExamples")
                    } else {
                        Button("Go to Up Next") { finish() }
                            .controlSize(.large)
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 20)
        }
        .background(Theme.screen)
    }

    private func finish() {
        WelcomeState.markSeen()
        router.tab = .upNext
        dismiss()
    }

    private var introPage: some View {
        page(title: "One thing at a time", message: "Lists you never look at don't help. Top Note shows you the one card that matters right now, in the app, on your Home Screen and with Siri. Handle it, and the next one appears.") {
            CardFanMark(size: 130)
                .padding(.vertical, 20)
        }
    }

    private var kindsPage: some View {
        page(title: "Three kinds of cards", message: "Each one behaves the way you'd expect.") {
            VStack(spacing: 12) {
                ForEach([CardType.note, .flashcard, .todo]) { type in
                    HStack(spacing: 14) {
                        Image(systemName: type.filledSymbol)
                            .font(.title2)
                            .foregroundStyle(type.tintColor)
                            .frame(width: 40)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(type.pluralName).font(.headline)
                            Text(kindDetail(type)).font(.subheadline).foregroundStyle(.secondary)
                        }
                        Spacer(minLength: 0)
                    }
                    .padding(14)
                    .background(type == .note ? AnyShapeStyle(Theme.paper) : AnyShapeStyle(Theme.cardSurface), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
            }
        }
    }

    private var everywherePage: some View {
        page(title: "Right where you look", message: "Top Note works best when you don't have to open it.") {
            VStack(alignment: .leading, spacing: 16) {
                feature("widget.medium", "Home Screen and Lock Screen", "Flip, rate, check off and skip from the widget.")
                feature("mic.fill", "Siri and Shortcuts", "“Add a note in Top Note” or “What's next in Top Note”.")
                feature("list.bullet.circle", "Apple Reminders", "Keep to-dos in sync with a Reminders list, both ways.")
                feature("icloud", "Private iCloud sync", "On all your devices. No account, ads or tracking.")
            }
            .padding(.horizontal, 4)
        }
    }

    private func kindDetail(_ type: CardType) -> String {
        switch type {
        case .note: "Ideas, quotes and thoughts come back on paper, so they don't get lost. Add a thought each time you meet one again."
        case .flashcard: "Answer in your head, flip, then rate Hard, Good or Easy. Cards space themselves out as you learn."
        case .todo: "Show up when they're due. Done checks off; Later sets aside. Syncs with Reminders."
        }
    }

    private func feature(_ symbol: String, _ title: String, _ detail: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: symbol)
                .font(.title3)
                .foregroundStyle(Color.accentColor)
                .frame(width: 32)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.headline)
                Text(detail).font(.subheadline).foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .combine)
    }

    private func page<Content: View>(title: String, message: String, @ViewBuilder content: () -> Content) -> some View {
        ScrollView {
            VStack(spacing: 18) {
                Spacer(minLength: 30)
                content()
                Text(title)
                    .font(.system(.largeTitle, design: .rounded, weight: .bold))
                    .multilineTextAlignment(.center)
                Text(message)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 28)
            .padding(.bottom, 50)
            .frame(maxWidth: 560)
            .frame(maxWidth: .infinity)
        }
    }
}

struct WhatsNewView: View {
    @Environment(\.dismiss) private var dismiss

    private let items: [(String, Color, String, String)] = [
        ("rectangle.stack.fill", .accentColor, "Up Next", "A new home that shows the one card that matters now, with Undo for every action."),
        ("rectangle.on.rectangle.angled", CardType.flashcard.tintColor, "Better flashcards", "Good now spaces a card out, and each button shows when you'll see it again. Strength shows what's sticking. Review ahead any time."),
        ("text.quote", CardType.note.tintColor, "Notes on paper", "Notes have their own look, Markdown, and a history of every time you met them again. Add a thought as you revisit."),
        ("list.bullet.circle", CardType.todo.tintColor, "Apple Reminders", "Keep to-dos in sync with a Reminders list, both ways."),
        ("mic.circle", .purple, "Siri, Shortcuts and Control Center", "Capture and check what's next without opening the app."),
        ("lock.rectangle.stack", .indigo, "Lock Screen widget", "See how many cards are ready, and the next one, at a glance.")
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    VStack(alignment: .leading, spacing: 8) {
                        CardFanMark(size: 70)
                        Text("Top Note 2.0")
                            .font(.system(.largeTitle, design: .rounded, weight: .bold))
                        Text("A brand-new Top Note: simpler to use and more capable. Your cards, folders and tags came along unchanged.")
                            .foregroundStyle(.secondary)
                    }
                    ForEach(items, id: \.2) { symbol, tint, title, detail in
                        HStack(alignment: .top, spacing: 14) {
                            Image(systemName: symbol)
                                .font(.title2)
                                .foregroundStyle(tint)
                                .frame(width: 36)
                            VStack(alignment: .leading, spacing: 3) {
                                Text(title).font(.headline)
                                Text(detail).font(.subheadline).foregroundStyle(.secondary)
                            }
                        }
                        .accessibilityElement(children: .combine)
                    }
                }
                .padding(24)
                .frame(maxWidth: 600)
                .frame(maxWidth: .infinity)
            }
            .safeAreaInset(edge: .bottom) {
                Button {
                    WelcomeState.markSeen()
                    dismiss()
                } label: {
                    Text("Continue").frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .padding(24)
                .background(.bar)
                .accessibilityIdentifier("whatsNewContinue")
            }
        }
        .onDisappear { WelcomeState.markSeen() }
    }
}
