import 'package:daily_light/services/favorites_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:shared_preferences_platform_interface/types.dart';

final class FailingPreferences extends InMemorySharedPreferencesAsync {
  FailingPreferences() : super.empty();

  @override
  Future<bool> setStringList(
    String key,
    List<String> value,
    SharedPreferencesOptions options,
  ) async {
    throw PlatformException(code: 'write_failed');
  }
}

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  test(
    'starts empty, adds favorites, and restores them in a new service',
    () async {
      final first = FavoritesService();
      addTearDown(first.dispose);
      await first.load();
      expect(first.isLoaded, isTrue);
      expect(first.contains('scripture_001'), isFalse);
      await first.toggle('scripture_001');
      await first.toggle('motivation_004');

      final restarted = FavoritesService();
      addTearDown(restarted.dispose);
      await restarted.load();
      expect(restarted.contains('scripture_001'), isTrue);
      expect(restarted.contains('motivation_004'), isTrue);
      await restarted.toggle('scripture_001');

      final third = FavoritesService();
      addTearDown(third.dispose);
      await third.load();
      expect(third.contains('scripture_001'), isFalse);
      expect(third.contains('motivation_004'), isTrue);
    },
  );

  test('ignores toggles before storage is loaded', () async {
    final service = FavoritesService();
    addTearDown(service.dispose);
    await service.toggle('scripture_001');
    expect(service.contains('scripture_001'), isFalse);
    await service.load();
    expect(service.contains('scripture_001'), isFalse);
  });

  test(
    'failed writes retain the previous state and reset the saving flag',
    () async {
      SharedPreferencesAsyncPlatform.instance = FailingPreferences();
      final service = FavoritesService();
      addTearDown(service.dispose);
      await service.load();
      await expectLater(
        service.toggle('scripture_001'),
        throwsA(isA<PlatformException>()),
      );
      expect(service.contains('scripture_001'), isFalse);
      expect(service.isSaving, isFalse);
    },
  );
}
