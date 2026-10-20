import 'package:flutter_test/flutter_test.dart';
import 'package:flashcard_studio/controllers/flashcard_controller.dart';
import 'package:flashcard_studio/models/flashcard.dart';

import 'support.dart';

void main() {
  test(
    'first launch seeds cards once; a deliberately empty deck stays empty',
    () async {
      final storage = MemoryStorage();
      final first = FlashcardController(storage);
      await first.initialize();
      expect(first.cards, hasLength(5));
      for (final card in first.cards) {
        await first.delete(card.id);
      }
      final reopened = FlashcardController(storage);
      await reopened.initialize();
      expect(reopened.cards, isEmpty);
      first.dispose();
      reopened.dispose();
    },
  );

  test('add, edit, and delete persist with stable id and timestamp', () async {
    final storage = MemoryStorage([]);
    final controller = FlashcardController(storage);
    addTearDown(controller.dispose);
    await controller.initialize();
    final card = testCard();
    await controller.add(card);
    expect(storage.saved!.single.question, 'Question 1?');
    await controller.update(card.copyWith(question: 'Updated?'));
    expect(controller.cards.single.question, 'Updated?');
    expect(storage.saved!.single.id, card.id);
    expect(storage.saved!.single.createdAt, card.createdAt);
    await controller.delete(card.id);
    expect(controller.cards, isEmpty);
    expect(storage.saved, isEmpty);
  });

  test('failed persistence keeps visible deck intact', () async {
    final storage = MemoryStorage([testCard()]);
    final controller = FlashcardController(storage);
    addTearDown(controller.dispose);
    await controller.initialize();
    storage.failWrites = true;
    await expectLater(controller.delete('1'), throwsStateError);
    expect(controller.cards, hasLength(1));
    expect(controller.saving, isFalse);
  });

  test('batch import rejects duplicate ids without writing', () async {
    final controller = await testController([testCard()]);
    addTearDown(controller.dispose);
    await expectLater(
      controller.addAll([testCard('2'), testCard()]),
      throwsArgumentError,
    );
    expect(controller.cards, hasLength(1));
  });

  test('model rejects blank required fields and trims text', () {
    for (final values in [(' ', 'answer'), ('question', '\n')]) {
      expect(
        () => Flashcard.create(question: values.$1, answer: values.$2),
        throwsArgumentError,
      );
    }
    final card = Flashcard.create(question: ' Question? ', answer: ' Answer. ');
    expect(card.question, 'Question?');
    expect(card.answer, 'Answer.');
    final restored = Flashcard.fromJson(card.toJson());
    expect(restored.toJson(), card.toJson());
  });
}
