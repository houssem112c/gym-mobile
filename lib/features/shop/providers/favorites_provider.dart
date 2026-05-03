import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FavoritesProvider extends ChangeNotifier {
  static const String _prefsKey = 'favorite_product_ids_v1';

  final Set<String> _favoriteIds = <String>{};
  bool _loaded = false;

  bool get isLoaded => _loaded;
  Set<String> get favoriteIds => Set.unmodifiable(_favoriteIds);

  FavoritesProvider() {
    _load();
  }

  bool isFavorite(String productId) => _favoriteIds.contains(productId);

  Future<void> toggleFavorite(String productId) async {
    if (_favoriteIds.contains(productId)) {
      _favoriteIds.remove(productId);
    } else {
      _favoriteIds.add(productId);
    }
    notifyListeners();
    await _persist();
  }

  Future<void> removeFavorite(String productId) async {
    if (_favoriteIds.remove(productId)) {
      notifyListeners();
      await _persist();
    }
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final ids = prefs.getStringList(_prefsKey) ?? const <String>[];
      _favoriteIds
        ..clear()
        ..addAll(ids);
    } finally {
      _loaded = true;
      notifyListeners();
    }
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_prefsKey, _favoriteIds.toList(growable: false));
  }
}
