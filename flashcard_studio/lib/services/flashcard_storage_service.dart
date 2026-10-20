import 'dart:convert';

import 'package:hive_ce/hive_ce.dart';
import 'package:path_provider/path_provider.dart';

import '../models/flashcard.dart';

abstract class FlashcardStorageService {
  /// Null means first launch. An empty list means the user emptied the deck.
  Future<List<Flashcard>?> load();
  Future<void> save(List<Flashcard> cards);
}

/// One versioned snapshot keeps batch imports and individual edits together.
/// JSON inside Hive avoids adapters/code generation for this small student app.
class HiveFlashcardStorageService implements FlashcardStorageService {
  HiveFlashcardStorageService(this.box);

  final Box<String> box;
  static const deckKey = 'deck';

  static Future<HiveFlashcardStorageService> open() async {
    final directory = await getApplicationSupportDirectory();
    Hive.init('${directory.path}/flashcard_studio');
    final box = await Hive.openBox<String>('cards_v1');
    return HiveFlashcardStorageService(box);
  }

  @override
  Future<List<Flashcard>?> load() async {
    final raw = box.get(deckKey);
    if (raw == null) return null;
    final data = jsonDecode(raw) as Map<String, dynamic>;
    if (data['schemaVersion'] != 1) {
      throw const FormatException('Unsupported deck version.');
    }
    final cards = (data['cards'] as List)
        .map((item) => Flashcard.fromJson(item as Map<String, dynamic>))
        .toList();
    if (cards.map((card) => card.id).toSet().length != cards.length) {
      throw const FormatException('Duplicate card ids.');
    }
    return cards;
  }

  @override
  Future<void> save(List<Flashcard> cards) async {
    await box.put(
      deckKey,
      jsonEncode({
        'schemaVersion': 1,
        'cards': cards.map((card) => card.toJson()).toList(),
      }),
    );
    await box.flush();
  }
}
