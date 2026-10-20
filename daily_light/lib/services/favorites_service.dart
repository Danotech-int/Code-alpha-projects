import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FavoritesService extends ChangeNotifier {
  FavoritesService({SharedPreferencesAsync? preferences})
    : _preferences = preferences ?? SharedPreferencesAsync();

  static const storageKey = 'daily_light.favorite_ids';
  final SharedPreferencesAsync _preferences;
  Set<String> _ids = {};
  bool _isLoaded = false;
  bool _isSaving = false;

  bool get isLoaded => _isLoaded;
  bool get isSaving => _isSaving;
  bool contains(String id) => _ids.contains(id);

  Future<void> load() async {
    final saved = await _preferences.getStringList(storageKey);
    _ids = (saved ?? []).toSet();
    _isLoaded = true;
    notifyListeners();
  }

  Future<void> toggle(String id) async {
    if (!_isLoaded || _isSaving) return;
    _isSaving = true;
    notifyListeners();
    final updated = Set<String>.of(_ids);
    if (!updated.add(id)) updated.remove(id);
    try {
      // Commit the UI state only after storage succeeds.
      await _preferences.setStringList(storageKey, updated.toList()..sort());
      _ids = updated;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }
}
