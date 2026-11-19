import 'dart:async';
import 'dart:convert';

import 'guide_notes.dart';
import 'position_snapshot_v2.dart';

/// Storage adapter for the versioned map; it never falls back from corrupt v2.
class PositionRepositoryV2 {
  PositionRepositoryV2(this.store);
  final GuideNotesStore store;
  static const v1Key = 'user-positions-map-v1';
  static const v2Key = 'user-positions-map-v2';
  Future<void> _pending = Future.value();

  Future<T> _serial<T>(Future<T> Function() operation) async {
    final previous = _pending;
    final done = Completer<void>();
    _pending = done.future;
    await previous;
    try {
      return await operation();
    } finally {
      done.complete();
    }
  }

  Future<PositionSnapshotV2> load() => _serial(() async {
    final current = await store.read(v2Key);
    if (current != null) {
      if (current is! String) throw const FormatException('Invalid v2 storage');
      final result = PositionSnapshotV2.decode(current);
      final data = jsonDecode(current);
      if (data is! Map || data['version'] != 2) {
        throw const FormatException('Invalid v2 storage version');
      }
      return result;
    }
    final old = await store.read(v1Key);
    if (old == null) {
      return PositionSnapshotV2.decode('{"version":2,"sheets":[],"points":[]}');
    }
    if (old is! String) throw const FormatException('Invalid v1 storage');
    final parsed = jsonDecode(old);
    if (parsed is! Map || parsed['version'] != 1) {
      throw const FormatException('Invalid v1 storage version');
    }
    final migrated = PositionSnapshotV2.decode(old);
    if (!await store.write(v2Key, migrated.encode())) {
      throw StateError('Migration failed');
    }
    return migrated;
  });

  Future<void> save(PositionSnapshotV2 snapshot) => _serial(() async {
    final data = snapshot.encode();
    if (!await store.write(v2Key, data)) throw StateError('Save failed');
  });
}
