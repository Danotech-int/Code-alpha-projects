# Flashcard Studio

## Overview

Flashcard Studio is an offline Flutter mobile application for the CodeAlpha **Flashcard Quiz App** assignment. It includes the full question/answer, navigation and card-management requirements, with hints, explanations and PDF study support.

The Material 3 interface uses warm paper backgrounds, forest-green actions, rounded study cards, readable typography and scrollable phone layouts. Five starter cards introduce programming and study concepts on the first launch.

## Core Assignment Features

| Requirement | Implementation |
| --- | --- |
| Question on front, answer on back | Study cards begin with the question; the revealed side includes the answer and explanation. |
| Show Answer | Show Answer / Hide Answer, with a short fade transition. |
| Previous / Next | Bounded navigation with a card counter and progress bar. |
| Add | Create Card opens a validated four-field form. |
| Edit | Card options opens a pre-filled form; identity and creation date stay the same. |
| Delete | Card options requires confirmation; cancelling preserves the card. |
| Clean UI | Material 3, SafeArea, consistent surfaces and comfortable controls. |

Phase 1 was completed and verified with **14 passing tests and clean analysis before PDF implementation began**.

## Extended Features

- Per-card hints, hidden again when navigating to another card.
- An explanation section alongside every revealed answer.
- Local persistence using Hive CE, including additions, edits, deletions and batch imports.
- A useful empty state; deleting all cards does not bring starter cards back on restart.
- Native PDF selection on Android/iOS using extension filtering.
- Real PDFium text extraction through pdfrx, with progress reported per page.
- Conservative local suggestions from English definitions; answers are copied from the source, with filename/page references and nearby context when available.
- Review and select suggestions before adding them to the library. Edit saved suggestions using the normal card editor.
- A manual fallback: select a source page, long-press a passage, choose **Create card from selection**, and write a question. The selected text becomes the editable answer.
- Cancellation, invalid-file, unreadable-PDF, storage-error and no-readable-text feedback.

All document processing happens locally. There is no remote AI, Firebase, API key, account or upload to a server. Native file pickers can still access cloud-provider documents when the provider is installed on the phone.

## Technologies

| Direct dependency | Purpose |
| --- | --- |
| Flutter SDK | Material 3 UI, navigation, animations, ChangeNotifier and forms. |
| hive_ce ^2.22.0 | Lightweight local database, storing a versioned deck snapshot. |
| path_provider ^2.1.6 | Finds the application's private support directory for the database. |
| file_picker ^13.1.0 | Opens the OS picker and streams the selected PDF. |
| pdfrx ^2.9.0 | Initializes PDFium and extracts actual PDF text. |
| flutter_test (development) | Widget, model, controller, storage, extraction and generator tests. |
| flutter_lints ^6.0.0 (development) | Static analysis rules. |

The lockfile records the resolved dependency versions. There are no generated Hive adapters or code-generation steps.

Compatibility was checked against Flutter **3.47.7**, Dart **3.13.5**, the installed package sources and the publisher documentation:

- [Hive CE](https://pub.dev/packages/hive_ce): Dart 3 local storage, Android/iOS support.
- [file_picker](https://pub.dev/packages/file_picker): the current static `FilePicker.pickFile` API, custom extension filters and streamed file reads.
- [pdfrx](https://pub.dev/packages/pdfrx): Android support, Flutter 3.47 / Dart 3.13 minimum, native PDFium packaging and initialization instructions.

Android uses the Flutter template's minimum API 24 and target/compile API 36. The iOS deployment target is 15 to match pdfrx. Building iOS requires macOS/Xcode and has not been verified on this Linux machine. Android/iOS are the generated platform targets.

## Architecture

```text
flashcard_studio/
├── android/                         Android runner and public app label
├── ios/                             iOS runner and deployment target
├── lib/
│   ├── main.dart                    Bootstrap, startup failure/retry and app root
│   ├── controllers/
│   │   └── flashcard_controller.dart Deck state and persistent CRUD
│   ├── models/
│   │   └── flashcard.dart            Immutable record, validation and JSON
│   ├── data/
│   │   └── sample_flashcards.dart    Five first-launch starter cards
│   ├── screens/
│   │   ├── home_screen.dart         Library, deck count and entry points
│   │   ├── study_screen.dart        Current index, navigation and empty state
│   │   ├── flashcard_form_screen.dart Validated add/edit form
│   │   └── pdf_import_screen.dart   Import progress, review and text selection
│   ├── widgets/
│   │   ├── flashcard_view.dart       Question, answer, explanation and hint
│   │   ├── progress_header.dart     Counter and accessible progress bar
│   │   └── empty_deck.dart          Empty library/session state
│   ├── services/
│   │   ├── flashcard_storage_service.dart Hive persistence boundary
│   │   ├── pdf_import_service.dart  Picker, bounded read and PDFium extraction
│   │   └── flashcard_generator_service.dart Interface and local generator
│   └── utils/
│       ├── app_theme.dart           Shared palette, theme and width constraint
│       └── card_actions.dart        Add/edit routes and confirmed deletion
├── test/
│   ├── app_test.dart                Library, study, forms and phone layouts
│   ├── flashcard_controller_test.dart CRUD, validation and write failures
│   ├── storage_test.dart            Real Hive close/reopen and corrupt data
│   ├── generator_test.dart          Grounded deterministic generation
│   ├── pdf_extraction_test.dart     Actual native PDFium extraction
│   ├── pdf_import_screen_test.dart  Import review and failure states
│   ├── support.dart                Small test-only memory storage
│   └── fixtures/                   Original readable and text-free PDFs
├── docs/
│   ├── instructor-guide.md         Walkthrough and seven instructor questions
│   └── verification/               Saved validation output
├── pubspec.yaml
└── pubspec.lock
```

The directory was created as `02_flashcard_studio` and renamed externally to `flashcard_studio` during development. This README uses the current directory name. The existing `daily_light` project was not modified.

## How To Run

With a compatible Flutter SDK on PATH:

```bash
cd "/home/astroboy/Documents/Code alpha mobile app internship/flashcard_studio"
flutter pub get
flutter run
flutter analyze
flutter test
```

The default `flutter` command on this computer points to a Snap launcher that failed in the development session. The working SDK is `/opt/flutter`. Use:

```bash
cd "/home/astroboy/Documents/Code alpha mobile app internship/flashcard_studio"
/opt/flutter/bin/flutter pub get
/opt/flutter/bin/flutter devices
/opt/flutter/bin/flutter run -d <android-device-id>
```

For host tests, PDFium's native build needs `clang` on PATH. This computer already has a compatible host-targeting clang inside its Android NDK. No system packages need to be installed to run the tests:

```bash
cd "/home/astroboy/Documents/Code alpha mobile app internship/flashcard_studio"
export PATH="/home/astroboy/Android/Sdk/ndk/28.2.13676358/toolchains/llvm/prebuilt/linux-x86_64/bin:/opt/flutter/bin:$PATH"
dart format .
flutter analyze
flutter test
```

On another Linux machine, install a normal host C toolchain (including clang) or put an existing compatible clang on PATH. The first PDFium build downloads native binaries; internet is needed for dependency installation and the first native build. Document extraction itself runs offline. Host tests explicitly point PDFium at Flutter's bundled test native library; Android uses the library packaged in the app.

## How It Works

### Model and state

`Flashcard` contains `id`, `question`, `answer`, `hint`, `explanation` and `createdAt`. The constructor trims text and rejects an empty id/question/answer. `copyWith` creates an edited record without changing the original identity or creation date. UTC timestamps and JSON serialization make storage straightforward.

`FlashcardController` extends ChangeNotifier and exposes an unmodifiable deck. Screens rebuild through ListenableBuilder. Local screen state is kept in StatefulWidgets; there is no BLoC, Redux, Provider package or dependency-injection framework.

### CRUD and local storage

The form validates question and answer, then calls `add` or `update`. Deletion first asks for confirmation. Every mutation constructs the proposed deck, awaits a Hive `put` and `flush`, then changes the visible deck. A failed write leaves the visible deck unchanged and gives the user retry feedback. Concurrent writes are rejected while saving.

The database is in the private application support directory, in the `cards_v1` Hive box. Its `deck` entry is JSON with `schemaVersion: 1` and a list of card records. One snapshot keeps the small deck and batch-import persistence easy to understand. This rewrites the deck per mutation and is intended for a modest student study collection, not a large document database.

A missing entry means first launch and seeds five cards. A saved empty list means intentional deletion and stays empty. Unsupported/corrupt data fails visibly at startup instead of being silently replaced with sample data. App-private storage survives ordinary closing/reopening; uninstalling or clearing app data removes it.

### Study navigation, reveal and hints

StudyScreen stores a zero-based index. Previous is disabled at the first card, Next at the last, and both are disabled for a one-card deck. The index is clamped after deck changes. An empty deck shows an action to create a card rather than indexing into an empty list. The counter and linear progress reflect position, not a score or evidence that an answer was memorized.

FlashcardView starts with answer and hint hidden. Show Answer reveals the answer plus the WHY section through AnimatedSwitcher; Hide Answer reverses it. Hint shows only the saved clue before reveal. Each card has a stable widget key, and edited records also reset visibility. Returning to a previously visited card starts hidden. The view respects reduced-motion settings and scrolls when content is long.

### PDF pipeline

```text
Choose PDF → selected filename → Generate Flashcards
    → stream and validate bytes → initialize PDFium → extract each page
    → identify complete English definition sentences → review/select drafts
    → convert drafts to Flashcards → persist once → return to library
```

The importer uses the native OS picker with a `pdf` extension filter, then also checks the filename and PDF header. It streams at most 20 MB, refuses documents above 150 pages or 500,000 extracted characters, reports page progress and disposes the native document in a finally block. These limits prevent unbounded work on a phone. Navigating back cancels subsequent processing stages.

Image-only/scanned PDFs produce a useful OCR message. OCR and password entry are not implemented. Damaged/encrypted PDFs show a read error. Complex columns, unusual font encodings and extraction order can affect text quality; review is required.

`FlashcardGeneratorService` is the replacement boundary for a future AI generator. The current LocalFlashcardGenerator recognizes complete definition sentences containing `is`, `are`, `means` or `refers to`. It rejects short/incomplete content and vague pronoun subjects, deduplicates concepts and caps suggestions at 30. Question order and content are deterministic. New record ids and timestamps are created only when drafts are saved.

Hints use a keyword's initial; explanations cite the filename/page and optionally a nearby sentence. These are source-based study aids, not newly reasoned explanations. When automatic suggestions are unsuitable, use the Source text tab and manually create a card from a selected passage. Raw PDFs/extracted documents are not kept in the application database; saved cards and their source references are.

## Testing and Device Checks

See `docs/verification/` for saved check output and `docs/instructor-guide.md` for the device checklist and discussion guide. Widget tests use predictable card records and a small memory storage implementation. Persistence tests open real Hive files. PDF extraction tests load real PDFs through the actual PDFium library; UI tests inject a fake import service only to test picker cancellation, review and error presentation reliably.

No physical Android phone was connected at the initial device check. A host test does not establish that the Android document picker or a phone-specific native library has been exercised. Use the physical-device checklist before recording an internship demo.
