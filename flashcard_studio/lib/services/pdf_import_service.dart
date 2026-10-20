import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:pdfrx/pdfrx.dart';

class PdfSource {
  const PdfSource({required this.name, required this.read, this.size});
  final String name;
  final int? size;
  final Stream<Uint8List> Function() read;
}

class PdfStudyPage {
  const PdfStudyPage({required this.number, required this.text});
  final int number;
  final String text;
}

class ExtractedPdf {
  const ExtractedPdf({required this.name, required this.pages});
  final String name;
  final List<PdfStudyPage> pages;
  bool get hasText => pages.any((page) => page.text.trim().isNotEmpty);
}

class PdfImportException implements Exception {
  const PdfImportException(this.message);
  final String message;
  @override
  String toString() => message;
}

class ImportCancellation {
  bool cancelled = false;
  void check() {
    if (cancelled) throw const PdfImportException('Import cancelled.');
  }
}

typedef PdfProgress = void Function(String stage, double? progress);

class PdfImportService {
  static const maxBytes = 20 * 1024 * 1024;
  static const maxPages = 150;
  static const maxCharacters = 500000;

  Future<PdfSource?> pick() async {
    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      dialogTitle: 'Choose study notes',
    );
    if (file == null) return null;
    return PdfSource(
      name: file.name,
      size: file.lengthSync(),
      read: file.readAsByteStream,
    );
  }

  /// PDFium runs parsing in its worker isolate. Documents are always disposed.
  /// Initialization is lazy so a PDF failure cannot prevent manual study.
  Future<ExtractedPdf> extract(
    PdfSource source, {
    PdfProgress? onProgress,
    ImportCancellation? cancellation,
  }) async {
    cancellation?.check();
    if (!source.name.toLowerCase().endsWith('.pdf')) {
      throw const PdfImportException('Please choose a PDF file.');
    }
    if ((source.size ?? 0) > maxBytes) {
      throw const PdfImportException('Choose a PDF smaller than 20 MB.');
    }
    onProgress?.call('Reading PDF…', null);
    final builder = BytesBuilder(copy: false);
    await for (final chunk in source.read()) {
      cancellation?.check();
      if (builder.length + chunk.length > maxBytes) {
        throw const PdfImportException('Choose a PDF smaller than 20 MB.');
      }
      builder.add(chunk);
    }
    final bytes = builder.takeBytes();
    final header = String.fromCharCodes(bytes.take(1024));
    if (!header.contains('%PDF-')) {
      throw const PdfImportException('This file does not contain a valid PDF.');
    }
    cancellation?.check();
    onProgress?.call('Extracting text…', 0);
    PdfDocument? document;
    try {
      await pdfrxFlutterInitialize();
      document = await PdfDocument.openData(
        bytes,
        sourceName: source.name,
        passwordProvider: () async => null,
      );
      if (document.pages.length > maxPages) {
        throw const PdfImportException('Choose a PDF with 150 pages or fewer.');
      }
      final pages = <PdfStudyPage>[];
      var characters = 0;
      for (final page in document.pages) {
        cancellation?.check();
        final raw = await page.loadText();
        final text = (raw?.fullText ?? '').replaceAll('\u0000', '').trim();
        characters += text.length;
        if (characters > maxCharacters) {
          throw const PdfImportException(
            'These notes are too long. Import a smaller section of the PDF.',
          );
        }
        pages.add(PdfStudyPage(number: page.pageNumber, text: text));
        onProgress?.call(
          'Extracting text… Page ${pages.length} of ${document.pages.length}',
          pages.length / document.pages.length,
        );
      }
      cancellation?.check();
      return ExtractedPdf(name: source.name, pages: pages);
    } on PdfImportException {
      rethrow;
    } catch (_) {
      throw const PdfImportException(
        'This PDF could not be read. It may be damaged or password-protected. Try an unlocked copy.',
      );
    } finally {
      await document?.dispose();
    }
  }
}
