import 'package:flutter_test/flutter_test.dart';
import 'package:flashcard_studio/services/flashcard_generator_service.dart';
import 'package:flashcard_studio/services/pdf_import_service.dart';

void main() {
  test(
    'definition generation is repeatable, grounded, and deduplicated',
    () async {
      const document = ExtractedPdf(
        name: 'notes.pdf',
        pages: [
          PdfStudyPage(
            number: 2,
            text: 'Encapsulation is the bundling of data and methods within a class. It protects internal state.\n\nEncapsulation is another definition that should not be duplicated.\n\nThis is a sentence without an identifiable study concept.\n\nA queue is a collection that processes items in arrival order.',
          ),
        ],
      );
      final generator = LocalFlashcardGenerator();
      final cards = await generator.generate(document);
      expect(cards, hasLength(2));
      expect(cards.first.question, 'What is Encapsulation?');
      expect(
        cards.first.answer,
        'Encapsulation is the bundling of data and methods within a class.',
      );
      expect(cards.first.explanation, contains('notes.pdf, page 2'));
      expect(cards.first.explanation, contains('It protects internal state.'));
      expect(cards.first.hint, isNot(contains('bundling')));
      expect(
        (await generator.generate(document)).map((card) => card.question),
        cards.map((card) => card.question),
      );
    },
  );

  test(
    'unstructured, incomplete, or non-definition text produces no guesses',
    () async {
      const document = ExtractedPdf(
        name: 'notes.pdf',
        pages: [
          PdfStudyPage(
            number: 1,
            text: 'Read chapters one and two. Study the diagram.\n\nGravity is the force that attracts',
          ),
        ],
      );
      expect(await LocalFlashcardGenerator().generate(document), isEmpty);
    },
  );

  test('generation caps suggestions at 30 cards', () async {
    final document = ExtractedPdf(
      name: 'long.pdf',
      pages: [
        PdfStudyPage(
          number: 1,
          text: List.generate(
            40,
            (i) => 'Concept $i is a useful definition with enough words.',
          ).join('\n\n'),
        ),
      ],
    );
    expect(await LocalFlashcardGenerator().generate(document), hasLength(30));
  });
}
