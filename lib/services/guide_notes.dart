import 'dart:convert';

import 'package:flutter/widgets.dart' show ChangeNotifier, Characters;
import 'package:shared_preferences/shared_preferences.dart';

/// Per-guide storage avoids rewriting unrelated personal notes.
abstract interface class GuideNotesStore {
  Future<Object?> read(String guideId);
  Future<bool> write(String guideId, String text);
}

class SharedPreferencesGuideNotesStore implements GuideNotesStore {
  static String key(String guideId) =>
      'kip.guideNotes.v2.${Uri.encodeComponent(guideId)}';

  @override
  Future<Object?> read(String guideId) async {
    final preferences = await SharedPreferences.getInstance();
    // Legacy setters update their cache even when a platform write fails.
    // Never treat that cache as evidence that a personal note was saved.
    await preferences.reload();
    final stored = preferences.get(key(guideId));
    if (stored == null) {
      // A separate key prevents interpreting old user text as an envelope.
      return preferences.get(
        'kip.guideNotes.v1.${Uri.encodeComponent(guideId)}',
      );
    }
    if (stored is! String) {
      throw const FormatException('Invalid stored personal note envelope');
    }
    final envelope = jsonDecode(stored);
    if (envelope is! Map<String, dynamic> ||
        envelope['version'] != 1 ||
        envelope['text'] is! String) {
      throw const FormatException('Invalid stored personal note envelope');
    }
    return envelope['text'] as String;
  }

  @override
  Future<bool> write(String guideId, String text) async {
    // JSON starts with `{`, avoiding Android's three reserved string prefixes.
    // The controller validates the decoded note's graphemes, not this payload.
    final encoded = jsonEncode({'version': 1, 'text': text});
    return (await SharedPreferences.getInstance()).setString(
      key(guideId),
      encoded,
    );
  }
}

class GuideNotesController extends ChangeNotifier {
  GuideNotesController(this.guideId, {GuideNotesStore? store})
    : _store = store ?? SharedPreferencesGuideNotesStore();

  static const maxLength = 20000;
  static int characterCount(String value) => Characters(value).length;
  final String guideId;
  final GuideNotesStore _store;
  String _text = '';
  String _savedText = '';
  bool _disposed = false;
  bool _loading = false;
  bool ready = false;
  bool loadFailed = false;
  bool saveFailed = false;
  bool saving = false;

  String get text => _text;
  bool get dirty => _text != _savedText;
  bool get canEdit => ready && !loadFailed;

  Future<void> load() async {
    if (_loading || saving || dirty) return;
    _loading = true;
    ready = false;
    _notify();
    try {
      final stored = await _store.read(guideId);
      if (stored != null &&
          (stored is! String || characterCount(stored) > maxLength)) {
        throw const FormatException('Invalid stored personal note');
      }
      _text = _savedText = (stored as String?) ?? '';
      loadFailed = false;
      saveFailed = false;
    } catch (_) {
      // Do not replace an unread note with an editable empty draft.
      loadFailed = true;
    } finally {
      ready = true;
      _loading = false;
      _notify();
    }
  }

  void edit(String value) {
    if (!canEdit || characterCount(value) > maxLength || value == _text) return;
    _text = value;
    _notify();
  }

  Future<bool> save() async {
    if (!canEdit || saving) return false;
    if (!dirty && !saveFailed) return true;
    final snapshot = _text;
    saving = true;
    _notify();
    try {
      final saved = await _store.write(guideId, snapshot);
      saveFailed = !saved;
      if (saved) _savedText = snapshot;
    } catch (_) {
      saveFailed = true;
    } finally {
      saving = false;
      _notify();
    }
    return !saveFailed;
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
