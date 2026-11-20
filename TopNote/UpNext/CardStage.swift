//
//  CardStage.swift
//  TopNote
//
//  How each kind of card is presented when it's the one that matters right now.
//

import SwiftUI
import TipKit

struct CardStage: View {
    let card: Card
    let isReviewingAhead: Bool
    let perform: (CardAction) -> Void
    let edit: () -> Void

    var body: some View {
        switch card.cardType {
        case .flashcard: FlashcardStage(card: card, perform: perform, edit: edit)
        case .todo: TodoStage(card: card, perform: perform, edit: edit)
        case .note: NoteStage(card: card, perform: perform, edit: edit)
        }
    }
}

/// The ⋯ menu shared by every stage.
private struct StageMenu: View {
    let card: Card
    let perform: (CardAction) -> Void
    let edit: () -> Void

    var body: some View {
        Menu {
            Button(action: edit) { Label("Edit", systemImage: "pencil") }
            if card.skipEnabled {
                Button { perform(.skip) } label: {
                    Label("Skip · back \(IntervalText.long(hours: card.previewSkipHours()))", systemImage: "arrow.uturn.forward")
                }
            }
            Divider()
            Button { perform(.archive) } label: { Label("Archive", systemImage: "archivebox") }
        } label: {
            Image(systemName: "ellipsis")
                .font(.body.weight(.semibold))
                .frame(width: 36, height: 36)
                .contentShape(Rectangle())
        }
        .accessibilityLabel("More actions")
        .accessibilityIdentifier("stageMenu")
    }
}

private struct StageHeader: View {
    let card: Card
    var trailing: AnyView? = nil

    var body: some View {
        HStack(spacing: 8) {
            Pill(text: card.cardType.rawValue, systemImage: card.cardType.systemImage, tint: card.cardType.tintColor)
            if let folder = card.folder {
                Pill(text: folder.name, systemImage: "folder")
            }
            if card.priority == .high {
                Image(systemName: "flag.fill").foregroundStyle(.orange).accessibilityLabel("High priority")
            }
            Spacer(minLength: 0)
            trailing
        }
    }
}

/// A big two-line action button: what it does, and when the card comes back.
private struct StageButton: View {
    let title: String
    var detail: String? = nil
    var systemImage: String? = nil
    let tint: Color
    var prominent = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 2) {
                HStack(spacing: 6) {
                    if let systemImage { Image(systemName: systemImage) }
                    Text(title)
                }
                .font(.headline)
                if let detail {
                    Text(detail)
                        .font(.caption)
                        .opacity(0.85)
                }
            }
            .frame(maxWidth: .infinity, minHeight: detail == nil ? 44 : 52)
            .foregroundStyle(prominent ? Color.white : tint)
            .background(prominent ? AnyShapeStyle(tint.gradient) : AnyShapeStyle(tint.opacity(0.12)), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(PressableButtonStyle())
    }
}

struct PressableButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.snappy(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - Flashcard

struct FlashcardStage: View {
    let card: Card
    let perform: (CardAction) -> Void
    let edit: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var revealed = false
    private let revealTip = RevealAnswerTip()
    private let ratingTip = RatingTip()

    var body: some View {
        VStack(spacing: 14) {
            if revealed {
                TipView(ratingTip)
            } else {
                TipView(revealTip)
            }

            ZStack {
                face(isAnswer: false)
                    .opacity(revealed ? 0 : 1)
                face(isAnswer: true)
                    .opacity(revealed ? 1 : 0)
                    .rotation3DEffect(.degrees(reduceMotion ? 0 : 180), axis: (x: 0, y: 1, z: 0))
            }
            .rotation3DEffect(.degrees(revealed && !reduceMotion ? 180 : 0), axis: (x: 0, y: 1, z: 0), perspective: 0.4)
            .onTapGesture { reveal() }
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(revealed ? [] : .isButton)
            .accessibilityHint(revealed ? "" : "Shows the answer")

            if revealed {
                HStack(spacing: 10) {
                    ForEach([RatingType.hard, .good, .easy]) { rating in
                        StageButton(
                            title: rating.rawValue,
                            detail: card.isRecurring ? IntervalText.short(hours: card.previewIntervalHours(for: rating)) : nil,
                            tint: rating.tintColor
                        ) {
                            ratingTip.invalidate(reason: .actionPerformed)
                            perform(.rate(rating))
                        }
                        .accessibilityLabel("\(rating.rawValue): \(rating.meaning)")
                        .accessibilityValue(card.isRecurring ? "Back \(IntervalText.long(hours: card.previewIntervalHours(for: rating)))" : "")
                        .accessibilityIdentifier("rate-\(rating.rawValue)")
                    }
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
                if !card.isRecurring {
                    Text("One-time card: rating it archives it.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            } else {
                HStack(spacing: 10) {
                    StageButton(title: "Show answer", systemImage: "arrow.2.squarepath", tint: CardType.flashcard.tintColor) { reveal() }
                        .accessibilityIdentifier("showAnswer")
                    if card.skipEnabled {
                        StageButton(title: "Skip", tint: .secondary, prominent: false) { perform(.skip) }
                            .frame(maxWidth: 110)
                            .accessibilityIdentifier("skipFlashcard")
                    }
                }
            }
        }
        .animation(reduceMotion ? .easeInOut(duration: 0.2) : .spring(duration: 0.55, bounce: 0.2), value: revealed)
    }

    private func reveal() {
        guard !revealed else { return }
        revealTip.invalidate(reason: .actionPerformed)
        revealed = true
    }

    private func face(isAnswer: Bool) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            StageHeader(card: card, trailing: AnyView(HStack(spacing: 4) {
                StrengthMeter(strength: card.strength)
                StageMenu(card: card, perform: perform, edit: edit)
            }))
            Spacer(minLength: 0)
            if isAnswer {
                Text(card.content)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
                Divider()
                Text(card.answer?.isEmpty == false ? card.answer! : "No answer yet. Tap ⋯ › Edit to add one.")
                    .font(Theme.questionFont)
                    .foregroundStyle(card.answer?.isEmpty == false ? .primary : .secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .accessibilityIdentifier("flashcardAnswer")
            } else {
                Text("QUESTION")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(CardType.flashcard.tintColor)
                    .tracking(1.2)
                Text(card.content)
                    .font(Theme.questionFont)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .accessibilityIdentifier("flashcardQuestion")
            }
            Spacer(minLength: 0)
            if !isAnswer {
                Text("Tap to flip")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, minHeight: 280, alignment: .topLeading)
        .background(Theme.cardSurface, in: RoundedRectangle(cornerRadius: 26, style: .continuous))
        .overlay(alignment: .top) {
            UnevenRoundedRectangle(topLeadingRadius: 26, topTrailingRadius: 26, style: .continuous)
                .fill(CardType.flashcard.tintColor.gradient)
                .frame(height: 6)
        }
        .shadow(color: .black.opacity(0.08), radius: 16, y: 6)
    }
}

// MARK: - To-do

struct TodoStage: View {
    let card: Card
    let perform: (CardAction) -> Void
    let edit: () -> Void

    @State private var checked = false
    @ObservedObject private var reminders = RemindersSync.shared
    private let tip = TodoActionsTip()

    private var tint: Color { CardType.todo.tintColor }

    var body: some View {
        VStack(spacing: 14) {
            TipView(tip)
            VStack(alignment: .leading, spacing: 18) {
                StageHeader(card: card, trailing: AnyView(StageMenu(card: card, perform: perform, edit: edit)))
                HStack(alignment: .top, spacing: 16) {
                    Button(action: complete) {
                        ZStack {
                            Circle().strokeBorder(tint, lineWidth: 2.5)
                            if checked {
                                Circle().fill(tint)
                                Image(systemName: "checkmark").font(.title3.weight(.bold)).foregroundStyle(.white)
                            }
                        }
                        .frame(width: 34, height: 34)
                        .contentShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Mark done")
                    .accessibilityIdentifier("todoCheckbox")
                    Text(card.content)
                        .font(.title3.weight(.semibold))
                        .strikethrough(checked, color: .secondary)
                        .foregroundStyle(checked ? .secondary : .primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .accessibilityIdentifier("todoText")
                }
                VStack(alignment: .leading, spacing: 6) {
                    Label(dueText, systemImage: "clock")
                    if card.isRecurring {
                        Label("Repeats \(card.displayedBaseSchedule.lowercased())", systemImage: "repeat")
                    }
                    if reminders.isActive, reminders.isLinked(card) {
                        Label("In Reminders · \(reminders.selectedList?.title ?? "")", systemImage: "list.bullet.circle")
                    }
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.cardSurface, in: RoundedRectangle(cornerRadius: 26, style: .continuous))
            .overlay(alignment: .leading) {
                UnevenRoundedRectangle(topLeadingRadius: 26, bottomLeadingRadius: 26, style: .continuous)
                    .fill(tint.gradient)
                    .frame(width: 6)
            }
            .shadow(color: .black.opacity(0.08), radius: 16, y: 6)

            HStack(spacing: 10) {
                StageButton(title: "Done", detail: card.isRecurring ? "next \(IntervalText.long(hours: card.resetRepeatIntervalOnComplete ? card.initialRepeatInterval : card.repeatInterval))" : nil, systemImage: "checkmark", tint: tint, action: complete)
                    .accessibilityIdentifier("todoDone")
                StageButton(title: "Later", detail: "back \(IntervalText.long(hours: card.previewSkipHours()))", tint: .orange, prominent: false) {
                    perform(.skip)
                }
                .accessibilityIdentifier("todoLater")
            }
        }
    }

    private var dueText: String {
        let due = card.nextTimeInQueue
        if Date().timeIntervalSince(due) < 3600 { return "Due now" }
        return "Waiting since \(due.formatted(.relative(presentation: .named)))"
    }

    private func complete() {
        guard !checked else { return }
        withAnimation(.spring(duration: 0.3)) { checked = true }
        tip.invalidate(reason: .actionPerformed)
        Task {
            try? await Task.sleep(for: .milliseconds(350))
            perform(.complete)
        }
    }
}

// MARK: - Note

struct NoteStage: View {
    let card: Card
    let perform: (CardAction) -> Void
    let edit: () -> Void

    @State private var isAddingThought = false
    @State private var thought = ""
    @FocusState private var thoughtFocused: Bool
    private let tip = NoteActionsTip()
    private var tint: Color { CardType.note.tintColor }

    var body: some View {
        VStack(spacing: 14) {
            TipView(tip)
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text("\u{201C}")
                        .font(.system(size: 64, weight: .bold, design: .serif))
                        .foregroundStyle(tint.opacity(0.6))
                        .frame(height: 34, alignment: .top)
                        .accessibilityHidden(true)
                    Spacer()
                    StageMenu(card: card, perform: perform, edit: edit)
                        .foregroundStyle(Theme.ink)
                }
                Text(NoteText.attributed(card.content))
                    .font(Theme.noteFont)
                    .lineSpacing(6)
                    .foregroundStyle(Theme.ink)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .textSelection(.enabled)
                    .accessibilityIdentifier("noteText")
                Text(provenance)
                    .font(.system(.footnote, design: .serif).italic())
                    .foregroundStyle(Theme.ink.opacity(0.6))
                if isAddingThought {
                    HStack(alignment: .bottom) {
                        TextField("A thought to keep with this note", text: $thought, axis: .vertical)
                            .font(.system(.body, design: .serif))
                            .focused($thoughtFocused)
                            .submitLabel(.done)
                            .onSubmit(saveThought)
                            .accessibilityIdentifier("thoughtField")
                        Button("Save", action: saveThought)
                            .font(.subheadline.weight(.semibold))
                            .disabled(thought.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                    .padding(12)
                    .background(Theme.ink.opacity(0.06), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
            }
            .padding(22)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background { NotePaper() }
            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
            .shadow(color: .brown.opacity(0.18), radius: 14, x: 0, y: 8)
            .rotationEffect(.degrees(-0.6))
            .padding(.vertical, 4)

            HStack(spacing: 10) {
                StageButton(title: "Got it", detail: card.isRecurring ? "back \(IntervalText.long(hours: card.repeatInterval))" : "archives it", tint: tint) {
                    tip.invalidate(reason: .actionPerformed)
                    perform(.next)
                }
                .accessibilityIdentifier("noteGotIt")
                if card.skipEnabled {
                    StageButton(title: "Less often", detail: "back \(IntervalText.long(hours: card.previewSkipHours()))", tint: tint, prominent: false) {
                        perform(.skip)
                    }
                    .accessibilityIdentifier("noteLessOften")
                }
            }
            Button {
                withAnimation(.snappy) { isAddingThought.toggle() }
                thoughtFocused = isAddingThought
            } label: {
                Label(isAddingThought ? "Cancel" : "Add a thought", systemImage: isAddingThought ? "xmark" : "pencil.line")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(tint)
            }
            .accessibilityIdentifier("addThought")
        }
    }

    private var provenance: String {
        let written = card.createdAt.formatted(date: .abbreviated, time: .omitted)
        let revisits = card.removals.count + card.skips.count
        switch revisits {
        case 0: return "Written \(written) · first time back"
        case 1: return "Written \(written) · revisited once"
        default: return "Written \(written) · revisited \(revisits) times"
        }
    }

    private func saveThought() {
        let trimmed = thought.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        perform(.addThought(trimmed))
    }
}

/// Ruled note paper.
struct NotePaper: View {
    var body: some View {
        Theme.paper
            .overlay {
                Canvas { context, size in
                    var y: CGFloat = 46
                    while y < size.height {
                        context.fill(Path(CGRect(x: 0, y: y, width: size.width, height: 1)), with: .color(Theme.paperRule))
                        y += 31
                    }
                }
            }
            .overlay(alignment: .top) {
                Rectangle().fill(CardType.note.tintColor.opacity(0.55)).frame(height: 4)
            }
    }
}

enum NoteText {
    /// Notes support light Markdown (bold, italics, links) while keeping line breaks.
    static func attributed(_ text: String) -> AttributedString {
        (try? AttributedString(markdown: text, options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace))) ?? AttributedString(text)
    }
}
