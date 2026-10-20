# Daily Light

## Overview

Daily Light is a Flutter Random Quote Generator built for the **Code Alpha mobile app internship assignment**. It customizes the assignment with Bible Scripture and motivational quotes, presented in a calm, minimal mobile interface.

The app contains 40 local quotes: 20 Bible passages using King James Version (KJV) wording and 20 original motivational statements credited to **Daily Light · Original**. It does not invent famous-person attributions or retrieve quotes from an API. Scripture references take the place of author names.

## Features

- A random quote on each fresh app launch.
- **New Quote** selects another quote without consecutive repeats.
- **All**, **Scripture**, and **Motivation** filters update the quote immediately.
- Favorite/unfavorite quotes and browse or remove them in the Favorites view.
- Favorites persist locally across app restarts.
- Copy the quote and its source to the clipboard, with a confirmation SnackBar.
- Preview a branded 4:5 quote card and share it as a sharp 1080×1350 PNG through the native mobile share sheet.
- Fully offline quote collection and bundled Lora typography.
- Responsive Material 3 interface with light/dark themes, SafeArea, scrollable content, accessible labels, and support for larger text.
- Subtle fade/slide transitions that respect the system's reduced-motion setting.
- A position indicator such as **12 of 40**, or **12 of 20** within a category. This is the quote's index in the collection, not a count of quotes already seen.

## Screenshots

Captured from the running Android application:

- [Light theme](docs/screenshots/home_light.png)
- [Dark theme](docs/screenshots/home_dark.png)
- [Favorites](docs/screenshots/favorites.png)

## Technologies

- Dart and Flutter (developed with Flutter 3.44.9 / Dart 3.12.2).
- [`shared_preferences`](https://pub.dev/packages/shared_preferences): `SharedPreferencesAsync` stores favorite IDs on the device.
- [`share_plus`](https://pub.dev/packages/share_plus): `SharePlus.instance.share(ShareParams(...))` opens the platform share sheet.
- Flutter's built-in `StatefulWidget`, `setState`, `ChangeNotifier`, `ListenableBuilder`, Navigator, and Clipboard APIs.
- `flutter_test` and `flutter_lints` for tests and analysis. The development-only `shared_preferences_platform_interface` provides an in-memory preferences backend for tests.

No backend, authentication, quote API, or runtime font download is required. Sharing to a particular external app may require that app's own internet connection.

## Project Structure

```text
daily_light/
├── android/                         Android launcher and build configuration
├── ios/                             iOS launcher and Xcode project
├── assets/
│   ├── branding/app_icon.svg        Editable sunrise icon source
│   └── fonts/                       Bundled Lora font and OFL license
├── docs/screenshots/                Verified Android screenshots
├── lib/
│   ├── main.dart                    App entry, service ownership, theme mode
│   ├── models/quote.dart            Quote and QuoteCategory
│   ├── data/quotes_data.dart        40 offline quotes
│   ├── screens/
│   │   ├── home_screen.dart         Selection, filtering, copy/share actions
│   │   └── favorites_screen.dart    Saved list, removal, empty state
│   ├── services/
│   │   ├── quote_picker.dart        Safe random selection without repeats
│   │   ├── favorites_service.dart   Local persistence and change notifications
│   │   └── share_service.dart       Capture PNG bytes and share an image file
│   ├── theme/app_theme.dart         Light and dark Material 3 colors
│   └── widgets/
│       ├── quote_card.dart          Quote, attribution, category, position
│       ├── category_selector.dart   All / Scripture / Motivation controls
│       ├── share_quote_card.dart    Dedicated 4:5 social quote graphic
│       └── share_quote_preview.dart Preview, busy state, and Share Image action
├── test/
│   ├── quote_picker_test.dart       Dataset, random selection, edge cases
│   ├── favorites_service_test.dart  Save, restore, remove, storage failures
│   ├── widget_test.dart             UI, filtering, actions, responsive layouts
│   └── share_quote_test.dart        PNG export, preview, cancellation, failures
├── analysis_options.yaml
├── pubspec.yaml
├── pubspec.lock
└── README.md
```

Generated build/cache files and IDE metadata are excluded from this outline and ignored by version control. Only this first internship application is included; Flashcard Studio and Fitness Tracker have not been created. The assignment identifier “01_daily_light” refers to this project; the Flutter package/folder is `daily_light`.

## How It Works

1. **Quote model:** an immutable `Quote` holds its unique ID, text, source, and a `QuoteCategory` enum. `shareText` formats the quote and attribution for Copy; the share card reads the same model directly.
2. **Local dataset:** a constant `List<Quote>` in `quotes_data.dart` ships inside the app, so browsing works without internet access.
3. **Random selection:** `QuotePicker` uses Dart's `Random`. It excludes the current ID before choosing an index. An empty pool returns `null`; a one-item pool returns its only item safely. Any quote can return later, but two consecutive selections differ whenever there is an alternative. Each fresh launch draws randomly; it can coincidentally match the previous launch.
4. **UI updates and filtering:** `HomeScreen` is a `StatefulWidget`. `setState` updates the selected category and current quote. A `where` filter creates the category pool, and `AnimatedSwitcher` transitions between quote cards. Static visual components are `StatelessWidget`s.
5. **Favorites persistence:** `FavoritesService` loads a string list through `SharedPreferencesAsync` into a set of quote IDs. A toggle writes the updated list before committing the change to the UI. Its `ChangeNotifier` updates both screens through `ListenableBuilder`. Actions are disabled until storage loads and while a write is pending, preventing racing writes. Storage failures leave the saved state intact and offer feedback/retry. Old IDs that are no longer in the dataset do not appear in the saved list.

Copy uses `Clipboard.setData` and shows a SnackBar. Share opens a preview of the current quote, then generates and shares its image. The preview includes an anchor rectangle for iPad and handles rendering, cache-storage, and platform failures with a SnackBar. Repeated taps are disabled until sharing completes; cancellation restores the Share action. Navigator opens the Favorites screen. Favorites survive restarts; theme choice follows the system on launch and can be switched for the current session.

## How to Run

Install Flutter with Dart 3.12 or newer and a supported Android toolchain. Start an Android emulator or attach a phone with USB debugging enabled. From this project directory:

```bash
flutter pub get
flutter run
```

From the parent internship folder:

```bash
cd daily_light
flutter pub get
flutter run
```

For checks:

```bash
dart format .
flutter analyze
flutter test
```

To generate an Android debug APK:

```bash
flutter build apk --debug
```

The APK is written to `build/app/outputs/flutter-apk/app-debug.apk`. Android builds use Java 17 or newer (Java 21 was used here). iOS requires macOS/Xcode and appropriate signing to run on an Apple device. This repository targets Android and iOS; no web application is included.

## Assignment Requirements

| Original requirement | Daily Light implementation |
| --- | --- |
| Display a random quote when the app opens | `HomeScreen.initState` selects from the local collection. |
| A New Quote button that changes the quote | The primary CTA chooses a random alternative and prevents consecutive repeats. |
| Clearly show quote text and author | The card displays large quote text and its source beneath it; Scripture uses a Bible reference. |
| Clean, minimal UI | Material 3, rounded cards, restrained colors, clear spacing, and focused controls. |

## Image Sharing

Tap **Share → Share Image**. Close the preview to return without generating a file. The preview follows the current light/dark theme and contains only Daily Light branding, the quote, its reference/author, category, and subtle decoration.

`ShareQuoteCard` owns a fixed 360×450 logical canvas. Its quote and attribution fit together without ellipsis; longer content scales down. A `FittedBox` scales the preview to fit the phone, while a scrollable dialog accommodates small screens and large system text. The exported graphic uses a fixed text scale for consistent composition.

`ShareQuotePreview` puts a keyed `RepaintBoundary` around only the card. `ShareService` waits for painting to finish, calls `toImage(pixelRatio: 3)`, encodes PNG bytes, and disposes the rendering image. This yields a 1080×1350 image regardless of screen resolution. The service sends `XFile.fromData(..., mimeType: 'image/png')` through `SharePlus.instance.share(ShareParams(files: [...], fileNameOverrides: ['daily_light_quote.png']))`. No duplicated quote text accompanies the image.

The installed `share_plus` 13.3.1 supports this API and prepares a temporary cache file from the bytes internally. No dependency was added and the app does not write to the user's photo library. Cache files remain available to receiving apps and are temporary OS-managed data. See the [package's image-data sharing documentation](https://pub.dev/packages/share_plus#share-data).

Rendered examples (generated from the Flutter share widget):

- [Scripture card](docs/share_cards/scripture.png)
- [Long Scripture card](docs/share_cards/long_scripture.png)
- [Motivation card in dark theme](docs/share_cards/motivation_dark.png)

### Test on an Android Phone

1. Enable **Developer options → USB debugging**, connect the phone, and accept its USB debugging prompt.
2. From the project directory, run:

   ```bash
   flutter pub get
   flutter devices
   flutter run -d DEVICE_ID
   ```

   Replace `DEVICE_ID` with the Android identifier from `flutter devices`. On this machine, `/opt/flutter/bin/flutter` works directly if the Snap launcher fails; alternatively run `export PATH="/opt/flutter/bin:$PATH"` first.
3. Select **Scripture**, tap **Share**, and confirm the preview matches the displayed quote, Bible reference, and **SCRIPTURE** label.
4. Tap **Share Image**. In the Android share sheet, choose an installed image-capable app such as WhatsApp or Telegram. Inspect its image draft: branding, quote, and reference should all be present and sharp. Sending is optional.
5. Return to Daily Light, select **Motivation**, generate another quote, and repeat. Confirm the original-author credit and **MOTIVATION** label.
6. Cancel the Android share sheet with Back. Generate another quote and share again several times. Each image should match its preview; the buttons should become available again after cancellation or return.
7. Try a longer quote, both themes, a larger system font, and landscape orientation. Scroll the preview if needed. The exported card should remain 4:5 with no cut-off text. If saved by the receiving app without resizing, its dimensions are 1080×1350.
8. Quickly tap **Share Image** twice. Only one share operation should start; the preview shows **Preparing image…** while working.

No device was connected during the image-sharing update. Actual receiving-app compatibility and the Android share-sheet interaction should be checked on your phone using these steps.

## Testing Notes

The tests cover all 40 unique entries, random-selection boundaries, category pools, non-repetition, favorites, clipboard payloads, theme changes, and responsive home layouts. Image-sharing tests render all 40 cards in both themes, check attribution/category labels and long content, decode an actual exported PNG to verify 1080×1350 dimensions, exercise preview closing, repeat sharing after cancellation/success, prevent concurrent shares, and recover from cache-storage/plugin failures. Native preference and share/cache channels are mocked; PNG rendering and file preparation run for real.

## Verification Results

For the image-sharing update:

- Formatting completed for all 17 Dart files, keeping the existing source style.
- `flutter analyze`: **No issues found**.
- `flutter test`: **33 tests passed**.
- `flutter build apk --debug --no-pub --target-platform android-arm64`: **successful**. The updated ARM64 test APK is at `build/app/outputs/flutter-apk/app-debug.apk`.
- Actual PNG encoding/decoding verified at **1080×1350**; example cards were visually inspected in light/dark themes, including the longest Scripture passage.
- Share/cache method-channel tests verified image MIME type, filename, repeat sharing, cancellation, concurrent-tap protection, and recovery from storage/sharing failures.
- Android phone/native receiving-app verification remains a manual step because no device is connected. Follow the steps above.

Validation used Flutter 3.47.7 / Dart 3.13.5. The original app was also tested previously on an Android emulator for quote browsing, favorites, offline use, and Copy. Those earlier checks do not replace phone testing of this new image-sharing flow. iOS runtime/build verification requires macOS and Xcode.

## Attribution and Submission Notes

Lora is bundled under the SIL Open Font License; see `assets/fonts/OFL.txt`. The sunrise brand asset is local and editable. Scripture entries are identified as KJV; motivational entries were written for Daily Light and are explicitly marked Original.

Android release builds currently use the generated debug signing key for internship testing. A store submission requires your own application identifier and private release signing configuration. No signing secrets are included.
