import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/guide.dart';

enum CatalogueView {
  catalog('Каталог', 'Каталог приборов'),
  favorites('Избранное', 'Избранные приборы'),
  recent('Недавние', 'Недавние приборы');

  const CatalogueView(this.label, this.title);
  final String label;
  final String title;
}

/// One local snapshot and ordered writes keep rapid taps from saving stale state.
class QuickAccessController extends ChangeNotifier {
  QuickAccessController(Iterable<InstrumentGuide> guides)
    : _ids = guides.map((guide) => guide.id).toSet(),
      _categories = guides.map((guide) => guide.category).toSet();

  static const storageKey = 'kip.quickAccess.v1';
  static const recentLimit = 10;
  final Set<String> _ids;
  final Set<String> _categories;
  final Set<String> _favorites = {};
  final List<String> _recent = [];
  SharedPreferences? _preferences;
  Future<void> _writes = Future.value();
  bool _disposed = false;
  bool ready = false;
  bool saveFailed = false;
  CatalogueView view = CatalogueView.catalog;
  String? category;

  bool isFavorite(String id) => _favorites.contains(id);
  List<String> get recent => List.unmodifiable(_recent);

  Future<void> load() async {
    try {
      _preferences = await SharedPreferences.getInstance();
      final stored = _preferences!.get(storageKey);
      if (stored is String) {
        try {
          final data = jsonDecode(stored);
          if (data is Map<String, dynamic>) {
            _favorites.addAll(_validIds(data['favorites']));
            _recent.addAll(_validIds(data['recent']).take(recentLimit));
            view = CatalogueView.values.firstWhere(
              (item) => item.name == data['view'],
              orElse: () => CatalogueView.catalog,
            );
            final savedCategory = data['category'];
            if (savedCategory is String &&
                _categories.contains(savedCategory)) {
              category = savedCategory;
            }
          }
        } on FormatException {
          // A corrupt snapshot must not prevent opening the offline catalogue.
        }
      }
    } catch (_) {
      saveFailed = true;
    }
    ready = true;
    _notify();
  }

  Iterable<String> _validIds(Object? value) => value is List
      ? value.whereType<String>().where(_ids.contains).toSet()
      : const <String>[];

  void toggleFavorite(String id) {
    if (!_ids.contains(id)) return;
    if (!_favorites.remove(id)) _favorites.add(id);
    _changed();
  }

  void recordVisit(String id) {
    if (!_ids.contains(id)) return;
    _recent.remove(id);
    _recent.insert(0, id);
    if (_recent.length > recentLimit) _recent.removeLast();
    _changed();
  }

  void selectView(CatalogueView value) {
    if (view == value) return;
    view = value;
    _changed();
  }

  void selectCategory(String? value) {
    if (value != null && !_categories.contains(value)) return;
    if (category == value) return;
    category = value;
    _changed();
  }

  void _changed() {
    final snapshot = jsonEncode({
      'favorites': _favorites.toList(),
      'recent': _recent,
      'view': view.name,
      'category': category,
    });
    _notify();
    _writes = _writes.then((_) async {
      try {
        final preferences = _preferences ??=
            await SharedPreferences.getInstance();
        saveFailed = !await preferences.setString(storageKey, snapshot);
      } catch (_) {
        saveFailed = true;
      }
      _notify();
    });
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
