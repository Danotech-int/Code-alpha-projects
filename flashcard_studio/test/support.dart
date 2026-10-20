import 'package:flashcard_studio/controllers/flashcard_controller.dart';
import 'package:flashcard_studio/models/flashcard.dart';
import 'package:flashcard_studio/services/flashcard_storage_service.dart';

class MemoryStorage implements FlashcardStorageService {
  MemoryStorage([this.saved]);
  List<Flashcard>? saved;
  bool failWrites = false;

  @override
  Future<List<Flashcard>?> load() async => saved == null ? null : [...saved!];

  @override
  Future<void> save(List<Flashcard> cards) async {
    if (failWrites) throw StateError('Disk full');
    saved = [...cards];
  }
}

Flashcard testCard([String id = '1']) => Flashcard(
  id: id,
  question: 'Question $id?',
  answer: 'Answer $id.',
  hint: 'Clue $id.',
  explanation: 'Explanation $id.',
  createdAt: DateTime.utc(2026, 1, 1),
);

Future<FlashcardController> testController(List<Flashcard> cards) async {
  final controller = FlashcardController(MemoryStorage(cards));
  await controller.initialize();
  return controller;
}
