import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:flashcard_studio/services/pdf_import_service.dart';
import 'package:flashcard_studio/services/flashcard_generator_service.dart';

PdfSource fixture(String name) => PdfSource(
  name: name,
  read: () => File('test/fixtures/$name').openRead().map(Uint8List.fromList),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  // The real PDFium engine runs here. Only path_provider is bypassed on host.
  Pdfrx.cacheDirectoryPath = Directory.systemTemp.path;
  // Flutter's host runner bundles this next to native_assets.json rather than
  // in the engine's lib/ directory searched by PDFium's default loader.
  if (Platform.isLinux) {
    Pdfrx.pdfiumModulePath = File('build/native_assets/linux/libpdfium.so')
        .absolute
        .path;
  }
  final service = PdfImportService();

  test('real PDF extracts readable text and feeds the generator', () async {
    final progress = <String>[];
    final document = await service.extract(
      fixture('study_notes.pdf'),
      onProgress: (stage, value) => progress.add(stage),
    );
    expect(document.pages, hasLength(1));
    expect(
      document.pages.single.text,
      contains('Encapsulation is the bundling'),
    );
    expect(document.hasText, isTrue);
    expect(progress.first, 'Reading PDF…');
    expect(progress.last, contains('Page 1 of 1'));
    expect(await LocalFlashcardGenerator().generate(document), hasLength(2));
  });

  test('real PDF with no text returns no fabricated material', () async {
    final document = await service.extract(fixture('no_text.pdf'));
    expect(document.hasText, isFalse);
    expect(await LocalFlashcardGenerator().generate(document), isEmpty);
  });

  test('wrong extension, oversized input, invalid header and cancellation fail clearly', () async {
    final bytes = Uint8List.fromList('not a PDF'.codeUnits);
    for (final source in [
      PdfSource(name: 'notes.txt', read: () => Stream.value(bytes)),
      PdfSource(
        name: 'big.pdf',
        size: PdfImportService.maxBytes + 1,
        read: () => Stream.value(bytes),
      ),
      PdfSource(name: 'renamed.pdf', read: () => Stream.value(bytes)),
    ]) {
      await expectLater(
        service.extract(source),
        throwsA(isA<PdfImportException>()),
      );
    }
    final cancellation = ImportCancellation()..cancelled = true;
    await expectLater(
      service.extract(fixture('study_notes.pdf'), cancellation: cancellation),
      throwsA(isA<PdfImportException>()),
    );
  });

  test('damaged PDF reports an actionable error', () async {
    final source = PdfSource(
      name: 'damaged.pdf',
      read: () =>
          Stream.value(Uint8List.fromList('%PDF-1.4\ninvalid'.codeUnits)),
    );
    await expectLater(
      service.extract(source),
      throwsA(
        isA<PdfImportException>().having(
          (error) => error.message,
          'message',
          contains('damaged or password-protected'),
        ),
      ),
    );
  });
}
