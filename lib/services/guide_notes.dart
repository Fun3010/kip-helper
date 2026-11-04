import 'dart:convert';
import 'dart:async';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:flutter/widgets.dart' show ChangeNotifier, Characters;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Per-guide storage avoids rewriting unrelated personal notes.
abstract interface class GuideNotesStore {
  Future<Object?> read(String guideId);
  Future<bool> write(String guideId, String text);
}

class SharedPreferencesGuideNotesStore implements GuideNotesStore {
  final _windows = FileGuideNotesStore();
  bool get _useFiles =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.windows;
  static String key(String guideId) =>
      'kip.guideNotes.v2.${Uri.encodeComponent(guideId)}';

  @override
  Future<Object?> read(String guideId) async {
    if (_useFiles) return _windows.read(guideId);
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
    if (_useFiles) return _windows.write(guideId, text);
    // JSON starts with `{`, avoiding Android's three reserved string prefixes.
    // The controller validates the decoded note's graphemes, not this payload.
    final encoded = jsonEncode({'version': 1, 'text': text});
    return (await SharedPreferences.getInstance()).setString(
      key(guideId),
      encoded,
    );
  }
}

/// Windows preferences has a second, non-durable plugin cache. Personal notes
/// use their own atomic files; migration reads the old JSON from disk directly.
class FileGuideNotesStore implements GuideNotesStore {
  FileGuideNotesStore({Directory? directory, File? legacyPreferencesFile})
    : _directory = directory,
      _legacyFile = legacyPreferencesFile;

  Directory? _directory;
  File? _legacyFile;
  static final Map<String, Future<void>> _queues = {};

  Future<Directory> get directory async {
    if (_directory != null) return _directory!;
    final support = await getApplicationSupportDirectory();
    _legacyFile ??= File('${support.path}/shared_preferences.json');
    return _directory = Directory('${support.path}/notes');
  }

  Future<T> _locked<T>(String id, Future<T> Function(File file) action) async {
    final dir = await directory;
    await dir.create(recursive: true);
    final root = await dir.resolveSymbolicLinks();
    final name = sha256.convert(utf8.encode(id)).toString();
    final file = File('$root/$name.json');
    final key = Platform.isWindows ? file.path.toLowerCase() : file.path;
    final previous = _queues[key] ?? Future<void>.value();
    final done = Completer<void>();
    _queues[key] = done.future;
    await previous;
    try {
      return await action(file);
    } finally {
      if (identical(_queues[key], done.future)) _queues.remove(key);
      done.complete();
    }
  }

  String _decode(String data) {
    final value = jsonDecode(data);
    if (value is! Map<String, dynamic> ||
        value['version'] != 1 ||
        value['text'] is! String) {
      throw const FormatException('Invalid personal note file');
    }
    return value['text'] as String;
  }

  Future<String?> _existing(File file) async {
    final backup = File('${file.path}.bak');
    if (!await file.exists()) {
      if (!await backup.exists()) return null;
      final saved = _decode(await backup.readAsString());
      await backup.rename(file.path);
      return saved;
    }
    try {
      return _decode(await file.readAsString());
    } on FormatException {
      if (!await backup.exists()) rethrow;
      final saved = _decode(await backup.readAsString());
      // Retain damaged bytes instead of silently overwriting the only evidence.
      await file.rename(
        '${file.path}.corrupt-${DateTime.now().microsecondsSinceEpoch}',
      );
      await backup.rename(file.path);
      return saved;
    }
  }

  Future<void> _commit(File file, String text) async {
    final temp = File('${file.path}.tmp');
    final backup = File('${file.path}.bak');
    await temp.writeAsString(
      jsonEncode({'version': 1, 'text': text}),
      flush: true,
    );
    if (await backup.exists()) await backup.delete();
    if (await file.exists()) await file.rename(backup.path);
    try {
      await temp.rename(file.path);
    } catch (_) {
      if (await backup.exists()) await backup.rename(file.path);
      rethrow;
    }
    try {
      if (await backup.exists()) await backup.delete();
    } on FileSystemException {
      // A committed note stays successful even if cleanup is denied.
    }
  }

  Future<String?> _legacy(String id) async {
    final legacy = _legacyFile;
    if (legacy == null || !await legacy.exists()) return null;
    final values = jsonDecode(await legacy.readAsString());
    if (values is! Map<String, dynamic>) {
      throw const FormatException('Invalid legacy notes');
    }
    final encoded =
        values['flutter.${SharedPreferencesGuideNotesStore.key(id)}'];
    if (encoded != null) {
      if (encoded is! String) {
        throw const FormatException('Invalid legacy note');
      }
      return _decode(encoded);
    }
    final raw = values['flutter.kip.guideNotes.v1.${Uri.encodeComponent(id)}'];
    if (raw != null && raw is! String) {
      throw const FormatException('Invalid legacy note');
    }
    return raw as String?;
  }

  @override
  Future<Object?> read(String guideId) => _locked(guideId, (file) async {
    final existing = await _existing(file);
    if (existing != null) return existing;
    final migrated = await _legacy(guideId);
    if (migrated != null) await _commit(file, migrated);
    return migrated;
  });

  @override
  Future<bool> write(String guideId, String text) =>
      _locked(guideId, (file) async {
        await _existing(file);
        await _commit(file, text);
        return true;
      });
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
