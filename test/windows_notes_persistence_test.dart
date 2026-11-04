import 'dart:io';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kip_helper/services/guide_notes.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:path_provider_windows/path_provider_windows.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';
import 'package:shared_preferences_windows/shared_preferences_windows.dart';

class TestSupportPath extends PathProviderPlatform {
  TestSupportPath(this.path);
  final String path;
  @override
  Future<String?> getApplicationSupportPath() async => path;
}

class TestWindowsSupportPath extends PathProviderWindows {
  TestWindowsSupportPath(this.path);
  final String path;
  @override
  Future<String?> getApplicationSupportPath() async => path;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory root;
  late PathProviderPlatform previousPath;
  late SharedPreferencesStorePlatform previousPreferences;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('kip-windows-notes-test-');
    previousPath = PathProviderPlatform.instance;
    previousPreferences = SharedPreferencesStorePlatform.instance;
    PathProviderPlatform.instance = TestSupportPath(root.path);
    SharedPreferences.setMockInitialValues({});
    SharedPreferencesStorePlatform.instance = SharedPreferencesWindows()
      ..pathProvider = TestWindowsSupportPath(root.path);
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
  });

  tearDown(() async {
    debugDefaultTargetPlatformOverride = null;
    PathProviderPlatform.instance = previousPath;
    SharedPreferencesStorePlatform.instance = previousPreferences;
    await root.delete(recursive: true);
  });

  test(
    'Windows reopen never treats a failed plugin-cache write as saved',
    () async {
      final preferences = await SharedPreferences.getInstance();
      final key = SharedPreferencesGuideNotesStore.key('sipart');
      expect(
        await preferences.setString(key, '{"version":1,"text":"saved A"}'),
        isTrue,
      );
      final disk = File('${root.path}/shared_preferences.json');
      final original = await disk.rename('${disk.path}.test-backup');
      // Real pinned Windows plugin: mutates its cache before a failed disk write.
      await Directory(disk.path).create();
      try {
        expect(
          await preferences.setString(key, '{"version":1,"text":"unsaved B"}'),
          isFalse,
        );
      } finally {
        await Directory(disk.path).delete();
        await original.rename(disk.path);
      }
      final reopened = GuideNotesController('sipart');
      await reopened.load();
      expect(reopened.loadFailed, isFalse);
      expect(reopened.text, 'saved A');
      reopened.dispose();
    },
  );

  test(
    'Windows note files survive a rejected write and a fresh adapter',
    () async {
      final store = FileGuideNotesStore(
        directory: Directory('${root.path}/notes'),
      );
      expect(await store.write('sipart', '  A\nё 👷🏽\t'), isTrue);
      final name = sha256.convert(utf8.encode('sipart'));
      final pending = Directory('${root.path}/notes/$name.json.tmp');
      await pending.create();
      final editor = GuideNotesController('sipart', store: store);
      await editor.load();
      editor.edit('unsaved B');
      expect(await editor.save(), isFalse);
      expect(editor.dirty, isTrue);
      final fresh = FileGuideNotesStore(
        directory: Directory('${root.path}/notes'),
      );
      expect(await fresh.read('sipart'), '  A\nё 👷🏽\t');
      await pending.delete();
      expect(await editor.save(), isTrue);
      expect(await fresh.read('sipart'), 'unsaved B');
      editor.dispose();
    },
  );

  for (final missing in [true, false]) {
    test('Recover saved backup with missing=$missing primary', () async {
      final dir = Directory('${root.path}/notes');
      final store = FileGuideNotesStore(directory: dir);
      await store.write('sipart', 'saved');
      final name = sha256.convert(utf8.encode('sipart'));
      final main = File('${dir.path}/$name.json');
      await main.rename('${main.path}.bak');
      if (!missing) await main.writeAsString('{broken');
      expect(await FileGuideNotesStore(directory: dir).read('sipart'), 'saved');
      expect(jsonDecode(await main.readAsString())['text'], 'saved');
    });
  }

  test(
    'Legacy raw text migrates exactly and malformed data blocks editing',
    () async {
      final legacy = File('${root.path}/shared_preferences.json');
      const raw = '{"version":1,"text":"this is literal old text"}';
      await legacy.writeAsString(
        jsonEncode({'flutter.kip.guideNotes.v1.sipart': raw}),
      );
      final store = FileGuideNotesStore(
        directory: Directory('${root.path}/notes'),
        legacyPreferencesFile: legacy,
      );
      expect(await store.read('sipart'), raw);
      await legacy.writeAsString('{broken');
      expect(await store.read('sipart'), raw);
      final blocked = GuideNotesController('other', store: store);
      await blocked.load();
      expect(blocked.loadFailed, isTrue);
      expect(blocked.canEdit, isFalse);
      blocked.dispose();
    },
  );

  test(
    'Separate guide transactions retain both notes and serialize shared guide',
    () async {
      final dir = Directory('${root.path}/notes');
      final first = FileGuideNotesStore(directory: dir);
      final second = FileGuideNotesStore(directory: dir);
      await Future.wait([first.write('a', 'A'), second.write('b', 'B')]);
      expect(await first.read('a'), 'A');
      expect(await first.read('b'), 'B');
      await Future.wait([first.write('a', 'first'), second.write('a', 'last')]);
      expect(await second.read('a'), anyOf('first', 'last'));
      await second.write('a', 'final');
      expect(await first.read('a'), 'final');
    },
  );
}
