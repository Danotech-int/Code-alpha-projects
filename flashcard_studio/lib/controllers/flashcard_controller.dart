import 'package:flutter/foundation.dart';

import '../data/sample_flashcards.dart';
import '../models/flashcard.dart';
import '../services/flashcard_storage_service.dart';

class FlashcardController extends ChangeNotifier {
  FlashcardController(this.storage);

  final FlashcardStorageService storage;
  List<Flashcard> _cards = [];
  bool _saving = false;
  List<Flashcard> get cards => List.unmodifiable(_cards);
  bool get saving => _saving;

  Future<void> initialize() async {
    final saved = await storage.load();
    if (saved == null) {
      final samples = sampleFlashcards();
      await storage.save(samples);
      _cards = samples;
    } else {
      _cards = saved;
    }
    notifyListeners();
  }

  Future<void> add(Flashcard card) => addAll([card]);

  Future<void> addAll(List<Flashcard> cards) async {
    if (cards.isEmpty) return;
    final next = [..._cards, ...cards];
    if (next.map((card) => card.id).toSet().length != next.length) {
      throw ArgumentError('Card ids must be unique.');
    }
    await _commit(next);
  }

  Future<void> update(Flashcard card) async {
    final index = _cards.indexWhere((item) => item.id == card.id);
    if (index < 0) throw StateError('This card no longer exists.');
    final next = [..._cards];
    next[index] = card;
    await _commit(next);
  }

  Future<void> delete(String id) async {
    await _commit(_cards.where((card) => card.id != id).toList());
  }

  Future<void> _commit(List<Flashcard> next) async {
    if (_saving) throw StateError('Please wait for the current save.');
    _saving = true;
    notifyListeners();
    try {
      // Commit to the visible deck only after the disk write succeeds.
      await storage.save(next);
      _cards = next;
    } finally {
      _saving = false;
      notifyListeners();
    }
  }
}
