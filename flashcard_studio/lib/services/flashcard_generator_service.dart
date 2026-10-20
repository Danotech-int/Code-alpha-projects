import '../models/flashcard.dart';
import 'pdf_import_service.dart';

/// Replace this interface's implementation to add an AI backend in the future.
abstract class FlashcardGeneratorService {
  Future<List<FlashcardDraft>> generate(ExtractedPdf document);
}

class FlashcardDraft {
  const FlashcardDraft({
    required this.question,
    required this.answer,
    required this.hint,
    required this.explanation,
  });
  final String question;
  final String answer;
  final String hint;
  final String explanation;

  Flashcard toFlashcard() => Flashcard.create(
    question: question,
    answer: answer,
    hint: hint,
    explanation: explanation,
  );
}

/// Conservative English definition extraction, with no invented answers.
/// Non-definition content remains available through the text selection flow.
class LocalFlashcardGenerator implements FlashcardGeneratorService {
  static final _definition = RegExp(
    r'^([A-Z][A-Za-z0-9() /-]{2,64}?)\s+(is|are|means|refers to)\s+(.+)[.!?]?$',
  );
  static final _vagueSubject = RegExp(
    r'^(this|that|these|those|it|they|there|here|we|you|he|she|the following|figure|table|page|chapter|section)\b',
    caseSensitive: false,
  );

  @override
  Future<List<FlashcardDraft>> generate(ExtractedPdf document) async {
    final drafts = <FlashcardDraft>[];
    final seen = <String>{};
    for (final page in document.pages) {
      final paragraphs = page.text
          .replaceAll('\r', '')
          .split(RegExp(r'\n\s*\n'));
      for (final paragraph in paragraphs) {
        final normalized = paragraph.replaceAll(RegExp(r'\s+'), ' ').trim();
        final sentences = normalized.split(RegExp(r'(?<=[.!?])\s+'));
        for (var i = 0; i < sentences.length; i++) {
          final sentence = sentences[i].trim();
          if (sentence.length < 30 ||
              sentence.length > 550 ||
              !sentence.endsWith('.')) {
            continue;
          }
          final match = _definition.firstMatch(sentence);
          if (match == null) continue;
          final concept = match.group(1)!.trim();
          final definition = match.group(3)!;
          if (_vagueSubject.hasMatch(concept) ||
              concept.split(' ').length > 8 ||
              definition.split(' ').length < 4 ||
              !seen.add(concept.toLowerCase())) {
            continue;
          }
          final keywords = RegExp(r'[a-zA-Z]{5,}')
              .allMatches(definition)
              .map((match) => match.group(0)!)
              .where(
                (word) => !{
                  'which',
                  'their',
                  'there',
                  'these',
                  'those',
                  'about',
                  'other',
                }.contains(word.toLowerCase()),
              )
              .toList();
          final clue = keywords.isEmpty
              ? 'Recall the definition from your notes.'
              : 'A key word in the definition starts with “${keywords.first[0].toUpperCase()}”.';
          final context =
              i + 1 < sentences.length && sentences[i + 1].length <= 550
              ? '\n\nNearby context: ${sentences[i + 1]}'
              : '';
          drafts.add(
            FlashcardDraft(
              question:
                  '${match.group(2) == 'are' ? 'What are' : 'What is'} $concept?',
              answer: sentence,
              hint: clue,
              explanation:
                  'Source: ${document.name}, page ${page.number}. This definition is taken directly from your notes.$context',
            ),
          );
          if (drafts.length >= 30) return drafts;
        }
      }
    }
    return drafts;
  }
}
