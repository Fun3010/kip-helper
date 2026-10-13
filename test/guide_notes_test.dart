import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:kip_helper/services/guide_notes.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
      'Corrupt note blocks overwrite and can retry loading: $corrupt',
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
}
