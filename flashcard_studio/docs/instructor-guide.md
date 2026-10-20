# Flashcard Studio: walkthrough and demonstration guide

## Code walkthrough

1. **Flashcard model — `lib/models/flashcard.dart`:** All six required fields are immutable. Required content is trimmed and validated. `create` supplies a collision-resistant timestamp/random id and UTC creation date; `copyWith` preserves identity and date. `toJson`/`fromJson` bridge the model to storage.
2. **State management — `lib/controllers/flashcard_controller.dart`:** One ChangeNotifier owns the deck. ListenableBuilder refreshes dependent screens. StatefulWidgets own temporary view state such as current position, field text and import progress. The controller accepts a small storage interface so tests can use memory while the real app uses Hive.
3. **Study navigation — `lib/screens/study_screen.dart`:** The current index is bounded; invalid initial positions are clamped. Previous and Next disable at their bounds. Deleting the last card yields the empty view. Moving to another card also returns the scroll position to the top.
4. **Answer reveal — `lib/widgets/flashcard_view.dart`:** A boolean controls the answer and WHY section. AnimatedSwitcher fades between hidden and visible content. Hide Answer reverses it; the question remains available for context.
5. **Hint state — the same widget:** A separate boolean controls the current clue. New card keys and edited card updates reset both booleans. Missing hints are clearly marked; optional explanations have an honest empty placeholder.
6. **CRUD — `flashcard_form_screen.dart` and `utils/card_actions.dart`:** One form supports create and edit with required-field validation and pre-filled values. Save awaits the controller. Delete opens an explicit confirmation dialog. Successful actions show feedback; failed writes offer retry without losing the form.
7. **Persistence — `services/flashcard_storage_service.dart`:** Hive stores a versioned JSON deck in private app storage. Writes are awaited and flushed. First launch is distinct from a deliberately empty deck. Malformed/unsupported data causes startup feedback instead of an automatic reset.
8. **PDF selection — `services/pdf_import_service.dart`:** Current `file_picker` opens a single native PDF picker. A cancellation returns null. The screen shows the selected filename and waits for Generate Flashcards before reading it.
9. **PDF extraction — the same service:** A bounded byte stream is checked for a PDF header, then opened by PDFium through pdfrx. Each page's real text is extracted with progress. The document is disposed even if extraction fails. No OCR, passwords or fabricated output are used.
10. **Generation — `services/flashcard_generator_service.dart`:** An abstract generator accepts the extracted document and returns reviewable drafts. The local implementation detects conservative English definitions, creates questions, preserves source answers, adds a modest hint and cites page context. The user selects drafts before one batch save. Source text selection opens the normal manual form when suggestions are unsuitable. A later AI implementation can use the same interface without rewriting CRUD or the study screen.

## Physical-device testing checklist

- [ ] Enable USB debugging, connect the phone and accept the computer's authorization prompt.
- [ ] Run `/opt/flutter/bin/flutter devices` and verify that an Android device is listed.
- [ ] From the project folder, run `/opt/flutter/bin/flutter run -d <android-device-id>`.
- [ ] Confirm the public app label is Flashcard Studio and the starter deck appears on first launch.
- [ ] Start studying; check the counter, progress, first/last disabled controls and a one-card deck.
- [ ] Reveal a hint, reveal/hide the answer, check WHY, move Next/Previous and confirm visibility resets.
- [ ] Try saving a blank/whitespace question and answer; then create a complete card.
- [ ] Edit all four content fields. Close/force-stop and reopen the app; confirm the edit and new card persist.
- [ ] Cancel a deletion, then confirm it. Delete the final card and reopen; confirm the deck remains empty.
- [ ] Import `test/fixtures/study_notes.pdf` after transferring it to the phone's Downloads folder. Confirm only PDF selection, filename display and real processing progress.
- [ ] Review generated cards, deselect one, save the rest and study/edit a saved document card.
- [ ] Use Source text, select a passage, create a card, write a question and verify the saved answer/source reference.
- [ ] Cancel the native picker and navigate back during processing; verify the existing library is unaffected.
- [ ] Try `test/fixtures/no_text.pdf` or a scanned PDF; confirm the OCR message and no invented cards.
- [ ] Try a damaged/password-protected PDF and a file over 20 MB; confirm useful errors and recovery.
- [ ] Repeat study/form/import interactions on a small display, with larger system text, the keyboard open and in landscape. Confirm content scrolls and touch targets remain usable.
- [ ] Put the phone in airplane mode and study/create/edit cards; extraction of an already-local PDF should work offline.

Device-dependent checks remain manual until an Android phone/emulator is available. iOS additionally needs a separate macOS/Xcode build and device check.

## Seven likely instructor questions

**1. How does your app meet the original assignment?**  
It displays questions, reveals answers with Show Answer, moves through cards with Previous/Next, and supports validated add/edit and confirmed delete in a clean mobile UI.

**2. Why did you use ChangeNotifier instead of BLoC?**  
There is one small deck and a few screens. ChangeNotifier is built into Flutter, makes state updates explicit and keeps the implementation easy to explain and test.

**3. How do cards survive restarting the app?**  
The controller awaits a Hive write and flush before updating the visible deck. On startup the app reloads the versioned records from its private support directory.

**4. What happens if all cards are deleted or Next is pressed at the end?**  
An empty deck displays a creation action. Navigation controls disable at bounds and the index is clamped after changes, so the app never intentionally indexes outside the deck.

**5. How are hints and answers reset for each card?**  
The study card widget has an identity based on the card id. Moving to another card creates fresh hidden state; editing a card also resets its view state.

**6. Is PDF generation actually AI?**  
No. PDFium extracts real text, and a local rule-based generator suggests cards from English definitions. The user reviews them, or manually creates a card from selected text. Scanned pages need OCR, which is not included.

**7. How could you add AI later, and what have you tested?**  
Implement FlashcardGeneratorService with a backend and keep the existing draft-review/save flow. Current tests cover study interactions, validation, CRUD, real Hive reopening, PDFium extraction, deterministic generation and import error states. Native phone selection and device behavior still require the supplied checklist.
