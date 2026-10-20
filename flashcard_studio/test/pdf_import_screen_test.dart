import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flashcard_studio/screens/pdf_import_screen.dart';
import 'package:flashcard_studio/screens/flashcard_form_screen.dart';
import 'package:flashcard_studio/services/pdf_import_service.dart';
import 'package:flashcard_studio/utils/app_theme.dart';

import 'support.dart';
import 'app_test.dart' show tapVisible;

class FakePdfImport extends PdfImportService {
  FakePdfImport({this.empty = false, this.cancel = false, this.fail = false});
  final bool empty;
  final bool cancel;
  final bool fail;

  @override
  Future<PdfSource?> pick() async => cancel
      ? null
      : PdfSource(name: 'notes.pdf', read: () => Stream.value(Uint8List(0)));

  @override
  Future<ExtractedPdf> extract(
    PdfSource source, {
    PdfProgress? onProgress,
    ImportCancellation? cancellation,
  }) async {
    if (fail) throw const PdfImportException('This PDF could not be read.');
    onProgress?.call('Extracting text…', 0.5);
    return ExtractedPdf(
      name: source.name,
      pages: [
        PdfStudyPage(
          number: 1,
          text: empty ? '' : 'Encapsulation is the bundling of data and methods within a class.',
        ),
      ],
    );
  }
}

void main() {
  testWidgets('source selection pre-fills a manual card and saves its source', (
    tester,
  ) async {
    final controller = await testController([]);
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        theme: studioTheme(),
        home: PdfImportScreen(
          controller: controller,
          importService: FakePdfImport(),
        ),
      ),
    );
    await tapVisible(tester, find.text('Choose PDF'));
    await tapVisible(tester, find.text('Generate Flashcards'));
    await tapVisible(tester, find.text('Source text'));
    final text = tester.widget<SelectableText>(find.byType(SelectableText));
    text.onSelectionChanged!(
      TextSelection(baseOffset: 0, extentOffset: text.data!.length),
      SelectionChangedCause.longPress,
    );
    await tester.pumpAndSettle();
    await tapVisible(tester, find.text('Create card from selection'));
    expect(find.byType(FlashcardFormScreen), findsOneWidget);
    final fields = tester
        .widgetList<TextFormField>(find.byType(TextFormField))
        .toList();
    expect(
      fields[1].controller!.text,
      'Encapsulation is the bundling of data and methods within a class.',
    );
    expect(fields[3].controller!.text, 'Source: notes.pdf, page 1.');
    await tester.enterText(
      find.byType(TextFormField).first,
      'What does encapsulation bundle?',
    );
    await tapVisible(tester, find.byKey(const Key('save-card')));
    expect(controller.cards.single.question, 'What does encapsulation bundle?');
  });

  testWidgets('cancelled picker leaves the deck and import screen intact', (
    tester,
  ) async {
    final controller = await testController([]);
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        theme: studioTheme(),
        home: PdfImportScreen(
          controller: controller,
          importService: FakePdfImport(cancel: true),
        ),
      ),
    );
    await tapVisible(tester, find.text('Choose PDF'));
    expect(find.text('Generate Flashcards'), findsNothing);
    expect(controller.cards, isEmpty);
  });

  testWidgets('PDF suggestions are reviewed before saving and persisted once', (
    tester,
  ) async {
    final controller = await testController([]);
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        theme: studioTheme(),
        home: PdfImportScreen(
          controller: controller,
          importService: FakePdfImport(),
        ),
      ),
    );
    await tapVisible(tester, find.text('Choose PDF'));
    expect(find.text('notes.pdf'), findsOneWidget);
    await tapVisible(tester, find.text('Generate Flashcards'));
    expect(controller.cards, isEmpty);
    expect(find.text('What is Encapsulation?'), findsOneWidget);
    await tapVisible(tester, find.text('Add 1 card to library'));
    expect(controller.cards.single.answer, contains('bundling of data'));
  });

  testWidgets(
    'no readable text shows the OCR message without generating cards',
    (tester) async {
      final controller = await testController([]);
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        MaterialApp(
          theme: studioTheme(),
          home: PdfImportScreen(
            controller: controller,
            importService: FakePdfImport(empty: true),
          ),
        ),
      );
      await tapVisible(tester, find.text('Choose PDF'));
      await tapVisible(tester, find.text('Generate Flashcards'));
      expect(
        find.textContaining('Scanned documents may require OCR'),
        findsOneWidget,
      );
      expect(find.text('Cards (0)'), findsNothing);
      expect(controller.cards, isEmpty);
    },
  );

  testWidgets('extraction failure shows an error with no fabricated results', (
    tester,
  ) async {
    final controller = await testController([]);
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        theme: studioTheme(),
        home: PdfImportScreen(
          controller: controller,
          importService: FakePdfImport(fail: true),
        ),
      ),
    );
    await tapVisible(tester, find.text('Choose PDF'));
    await tapVisible(tester, find.text('Generate Flashcards'));
    expect(find.text('This PDF could not be read.'), findsOneWidget);
    expect(find.text('Source text'), findsNothing);
    expect(controller.cards, isEmpty);
  });
}
