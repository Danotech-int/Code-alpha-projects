import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive_ce.dart';
import 'package:flashcard_studio/services/flashcard_storage_service.dart';

import 'support.dart';

void main() {
  late Directory directory;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('flashcard-storage-test');
    Hive.init(directory.path);
  });

  tearDown(() async {
    await Hive.close();
    await directory.delete(recursive: true);
  });

  test(
    'real Hive box survives close and reopen, including an empty deck',
    () async {
      var box = await Hive.openBox<String>('test');
      var storage = HiveFlashcardStorageService(box);
      expect(await storage.load(), isNull);
      await storage.save([testCard()]);
      await box.close();
      box = await Hive.openBox<String>('test');
      storage = HiveFlashcardStorageService(box);
      expect((await storage.load())!.single.toJson(), testCard().toJson());
      await storage.save([]);
      await box.close();
      box = await Hive.openBox<String>('test');
      expect(await HiveFlashcardStorageService(box).load(), isEmpty);
    },
  );

  test(
    'corrupt storage reports failure without replacing the record',
    () async {
      final box = await Hive.openBox<String>('corrupt');
      await box.put(HiveFlashcardStorageService.deckKey, 'broken json');
      await expectLater(
        HiveFlashcardStorageService(box).load(),
        throwsFormatException,
      );
      expect(box.get(HiveFlashcardStorageService.deckKey), 'broken json');
    },
  );
}
