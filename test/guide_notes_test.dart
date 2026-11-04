import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:kip_helper/services/guide_notes.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

class MemoryNotesStore implements GuideNotesStore {
  final values = <String, Object?>{};
  bool failRead = false;
  bool failWrite = false;
  Completer<bool>? pendingWrite;

  @override
  Future<Object?> read(String guideId) async {
    if (failRead) throw StateError('read failed');
    return values[guideId];
  }

  @override
  Future<bool> write(String guideId, String text) async {
    final success = pendingWrite == null
        ? !failWrite
        : await pendingWrite!.future;
    if (success) values[guideId] = text;
    return success;
  }
}

class PlatformNotesStore extends InMemorySharedPreferencesStore {
  PlatformNotesStore() : super.empty();

  static const reservedPrefixes = [
    'VGhpcyBpcyB0aGUgcHJlZml4IGZvciBhIGxpc3Qu',
    'VGhpcyBpcyB0aGUgcHJlZml4IGZvciBCaWdJbnRlZ2Vy',
    'VGhpcyBpcyB0aGUgcHJlZml4IGZvciBEb3VibGUu',
  ];
  bool rejectWrites = false;
  bool throwWrites = false;
  bool failReads = false;

  @override
  Future<Map<String, Object>> getAll() async {
    if (failReads) throw StateError('platform read failed');
    return super.getAll();
  }

  @override
  Future<bool> setValue(String valueType, String key, Object value) async {
    if (throwWrites) throw StateError('platform write failed');
    if (rejectWrites) return false;
    if (valueType == 'String' &&
        value is String &&
        reservedPrefixes.any(value.startsWith)) {
      throw ArgumentError('Reserved Android string prefix');
    }
    return super.setValue(valueType, key, value);
  }
}

PlatformNotesStore installPlatformNotesStore() {
  SharedPreferences.setMockInitialValues({});
  final store = PlatformNotesStore();
  SharedPreferencesStorePlatform.instance = store;
  return store;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Save and reload preserve exact personal text per guide', () async {
    SharedPreferences.setMockInitialValues({});
    const text = '  Личная заметка\n\nКонтроль: ё ± 👷\t\n';
    final first = GuideNotesController('sipart');
    await first.load();
    first.edit(text);
    expect(first.dirty, isTrue);
    expect(await first.save(), isTrue);
    expect(first.dirty, isFalse);
    final reloaded = GuideNotesController('sipart');
    final other = GuideNotesController('su1s');
    await reloaded.load();
    await other.load();
    expect(reloaded.text, text);
    expect(other.text, isEmpty);
    other.edit('СУ-1С');
    await other.save();
    final unchanged = GuideNotesController('sipart');
    await unchanged.load();
    expect(unchanged.text, text);
    for (final controller in [first, reloaded, other, unchanged]) {
      controller.dispose();
    }
  });

  for (final corrupt in [
    42,
    true,
    List<String>.filled(1, 'broken'),
    'x' * 20001,
  ]) {
    test(
      'Corrupt note blocks overwrite and can retry loading: ${corrupt.runtimeType}',
      () async {
        final store = MemoryNotesStore()..values['sipart'] = corrupt;
        final controller = GuideNotesController('sipart', store: store);
        await controller.load();
        expect(controller.ready, isTrue);
        expect(controller.loadFailed, isTrue);
        controller.edit('replacement');
        expect(await controller.save(), isFalse);
        expect(store.values['sipart'], corrupt);
        store.values['sipart'] = 'recovered';
        await controller.load();
        expect(controller.loadFailed, isFalse);
        expect(controller.text, 'recovered');
        controller.dispose();
      },
    );
  }

  test('Read failure cannot silently overwrite saved text', () async {
    final store = MemoryNotesStore()
      ..values['sipart'] = 'saved text'
      ..failRead = true;
    final controller = GuideNotesController('sipart', store: store);
    await controller.load();
    controller.edit('new text');
    expect(await controller.save(), isFalse);
    expect(store.values['sipart'], 'saved text');
    store.failRead = false;
    await controller.load();
    expect(controller.text, 'saved text');
    expect(controller.dirty, isFalse);
    controller.dispose();
  });

  test(
    'Failed save keeps edits and dirty state until retry succeeds',
    () async {
      final store = MemoryNotesStore()
        ..values['sipart'] = 'old'
        ..failWrite = true;
      final controller = GuideNotesController('sipart', store: store);
      await controller.load();
      controller.edit('new');
      expect(await controller.save(), isFalse);
      expect(controller.saveFailed, isTrue);
      expect(controller.dirty, isTrue);
      expect(controller.text, 'new');
      expect(store.values['sipart'], 'old');
      store.failWrite = false;
      expect(await controller.save(), isTrue);
      expect(controller.saveFailed, isFalse);
      expect(controller.dirty, isFalse);
      expect(store.values['sipart'], 'new');
      controller.dispose();
    },
  );

  test('Editing during a pending save keeps newer text dirty', () async {
    final store = MemoryNotesStore()..pendingWrite = Completer<bool>();
    final controller = GuideNotesController('sipart', store: store);
    await controller.load();
    controller.edit('first');
    final saved = controller.save();
    controller.edit('second');
    store.pendingWrite!.complete(true);
    expect(await saved, isTrue);
    expect(controller.text, 'second');
    expect(controller.dirty, isTrue);
    expect(store.values['sipart'], 'first');
    controller.dispose();
  });

  test(
    'Length limit accepts 20000 and rejects excess without truncating',
    () async {
      final controller = GuideNotesController(
        'sipart',
        store: MemoryNotesStore(),
      );
      await controller.load();
      final limit = 'a' * 20000;
      controller.edit(limit);
      expect(controller.text, limit);
      controller.edit('$limit!');
      expect(controller.text, limit);
      expect(await controller.save(), isTrue);
      controller.dispose();
    },
  );

  test(
    'Length limit counts Unicode graphemes without changing exact text',
    () async {
      final controller = GuideNotesController(
        'sipart',
        store: MemoryNotesStore(),
      );
      await controller.load();
      final text = '👷🏽' * 20000;
      controller.edit(text);
      expect(controller.text, text);
      expect(GuideNotesController.characterCount(text), 20000);
      expect(await controller.save(), isTrue);
      controller.edit('$text!');
      expect(controller.text, text);
      controller.dispose();
    },
  );

  for (final throws in [false, true]) {
    test(
      'Production adapter reopens durable note after failed write throws=$throws',
      () async {
        final platform = installPlatformNotesStore();
        final first = GuideNotesController('sipart');
        await first.load();
        first.edit('saved A');
        expect(await first.save(), isTrue);
        platform.rejectWrites = !throws;
        platform.throwWrites = throws;
        first.edit('unsaved B');
        expect(await first.save(), isFalse);
        expect(first.text, 'unsaved B');
        expect(first.dirty, isTrue);
        first.dispose();
        final reopened = GuideNotesController('sipart');
        await reopened.load();
        expect(reopened.text, 'saved A');
        expect(reopened.dirty, isFalse);
        reopened.edit('retry B');
        expect(await reopened.save(), isFalse);
        expect(reopened.text, 'retry B');
        platform.rejectWrites = false;
        platform.throwWrites = false;
        expect(await reopened.save(), isTrue);
        reopened.dispose();
        final restored = GuideNotesController('sipart');
        await restored.load();
        expect(restored.text, 'retry B');
        expect(restored.dirty, isFalse);
        restored.dispose();
      },
    );
  }

  for (final prefix in PlatformNotesStore.reservedPrefixes) {
    test(
      'Production adapter round-trips reserved Android prefix $prefix',
      () async {
        installPlatformNotesStore();
        final note = '$prefix  Личный текст\n👷🏽\t';
        final first = GuideNotesController('sipart');
        await first.load();
        first.edit(note);
        expect(await first.save(), isTrue);
        first.dispose();
        final restored = GuideNotesController('sipart');
        await restored.load();
        expect(restored.text, note);
        restored.dispose();
      },
    );
  }

  test(
    'Production adapter refresh failure blocks stale cached note and overwrite',
    () async {
      final platform = installPlatformNotesStore();
      final initial = GuideNotesController('sipart');
      await initial.load();
      initial.edit('saved');
      expect(await initial.save(), isTrue);
      initial.dispose();
      platform.failReads = true;
      final blocked = GuideNotesController('sipart');
      await blocked.load();
      expect(blocked.loadFailed, isTrue);
      blocked.edit('replacement');
      expect(await blocked.save(), isFalse);
      platform.failReads = false;
      await blocked.load();
      expect(blocked.text, 'saved');
      expect(blocked.loadFailed, isFalse);
      blocked.dispose();
    },
  );

  test('Production adapter applies grapheme limit to decoded text', () async {
    installPlatformNotesStore();
    final adapter = SharedPreferencesGuideNotesStore();
    final note = '👷🏽' * 20000;
    expect(await adapter.write('sipart', note), isTrue);
    final accepted = GuideNotesController('sipart');
    await accepted.load();
    expect(accepted.loadFailed, isFalse);
    expect(accepted.text, note);
    accepted.dispose();
    expect(await adapter.write('sipart', '$note!'), isTrue);
    final blocked = GuideNotesController('sipart');
    await blocked.load();
    expect(blocked.loadFailed, isTrue);
    expect(await blocked.save(), isFalse);
    blocked.dispose();
  });

  test(
    'Production adapter preserves legacy raw text during safe-format migration',
    () async {
      final platform = installPlatformNotesStore();
      const original = '{"version":1,"text":"literal raw personal text"}';
      await platform.setValue(
        'String',
        'flutter.kip.guideNotes.v1.sipart',
        original,
      );
      final first = GuideNotesController('sipart');
      await first.load();
      expect(first.text, original);
      first.edit('$original\nEdited');
      expect(await first.save(), isTrue);
      first.dispose();
      final restored = GuideNotesController('sipart');
      await restored.load();
      expect(restored.text, '$original\nEdited');
      restored.dispose();
    },
  );

  test(
    'Production adapter does not expose malformed encoded state as a note',
    () async {
      final platform = installPlatformNotesStore();
      await platform.setValue(
        'String',
        'flutter.${SharedPreferencesGuideNotesStore.key('sipart')}',
        '{}',
      );
      final blocked = GuideNotesController('sipart');
      await blocked.load();
      expect(blocked.loadFailed, isTrue);
      blocked.edit('replacement');
      expect(await blocked.save(), isFalse);
      expect(
        (await platform
            .getAll())['flutter.${SharedPreferencesGuideNotesStore.key('sipart')}'],
        '{}',
      );
      blocked.dispose();
    },
  );
}
