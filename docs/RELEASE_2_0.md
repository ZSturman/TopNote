# Top Note 2.0 release record

Version 2.0.0, build 41. Build 40 (uploaded earlier) is superseded and must not be submitted: build 41 adds the store-recovery safety fix and the Reminders due-date fix below.

## Fixes made during release testing

| Problem | Fix | Regression test |
|---|---|---|
| The widget extension ran the same store-opening code as the app and moved the library aside on *any* open failure, e.g. a widget refreshing before first unlock. A healthy library could disappear from view. | `StoreRecoveryPolicy`: only the app, never an extension, sets a store aside, and only when the file is readable but not a healthy SQLite database (header + `PRAGMA quick_check`). Unreadable or locked files are left alone. SwiftData's thrown error is opaque (`loadIssueModelContainer`), so the file is inspected directly. | `TopNote2Tests`: garbage store, extension, healthy, missing and unreadable stores |
| Reminders due dates were read with `DateComponents.date`, which is nil without a calendar. EventKit attaches one to fetched reminders, so this worked in practice; resolving through the calendar makes it independent of that. | `RemindersSync.date(of:)` | `RemindersSyncTests` (15 EventKit tests) |
| UI test checked sheet dismissal with `waitForExistence` and tapped moving elements on iPad hardware | `waitForNonExistence`, `tapWhenSettled` | — |

## Testing

| Area | Where | Result |
|---|---|---|
| Unit tests (scheduling, migration, routes, stats, undo, store recovery, welcome) | iPhone 17 Pro Max simulator | 147/147 pass |
| Reminders two-way sync against real EventKit: create, import once, no duplicates across devices, title and due date both ways, conflict (Top Note wins), completion both ways, repeating to-dos, reopen, offline changes then reconnect, deleted reminder, Undo | Simulator **and physical iPad Pro 12.9" (5th gen)** with iCloud Reminders | 15/15 pass on both; disposable "Top Note QA" lists removed (verified none left) |
| App Intents (Add Note/To-do/Flashcard, What's Next order, Cards Ready, routes) | Simulator and physical iPad | 5/5 pass |
| UI flows: Up Next, flip and rate, Undo toast, note thought, capture all kinds, Save and add another, Library, Settings, onboarding with examples, What's New | iPhone 17 Pro Max and iPad Pro 13" simulators, **physical iPad** (landscape, hardware keyboard) | 3/3 pass on each |
| 1.x → 2.0 upgrade | Disposable simulator: 1.10.3 built from `origin/main` creates a 30-card library (8 flashcards, 12 notes, 10 to-dos, 4 folders, 13 tags), then 2.0 installed over it | All card content, answers, intervals, due times, rating/completion history, folders and tags byte-identical; exactly the 7 flashcards on the 1.x Good policy changed None → Mild; What's New shown; nothing moved to Recovery |
| Force quit and relaunch | Same simulator | Store identical after `kill -9` and relaunch |
| Corrupt store | Same simulator | File moved byte-identical to `Recovery/<date>/`, app opens empty; a healthy store is never moved |

Not covered by automation, needing a person with a device:

- Placing the Home Screen widget and Lock Screen "Ready Now" widget; tapping widget buttons.
- Siri by voice, the Control Center controls, the Action button.
- iCloud sync between two devices on the **Production** CloudKit environment (TestFlight/App Store builds). 2.0 changes no SwiftData model, so the production CloudKit schema needs no deployment.

Legacy 1.x UI tests (`UITests/UITests.swift`, `CardSelectionUITests.swift`, `WidgetUITests.swift`) assume the 1.x single-list home screen and were not updated for the 2.0 tabs; they are not part of this validation.
