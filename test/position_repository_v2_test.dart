import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:kip_helper/services/guide_notes.dart';
import 'package:kip_helper/services/position_repository_v2.dart';

class MemoryStore implements GuideNotesStore {
  final values = <String, String>{};
  bool fail = false;
  @override
  Future<Object?> read(String id) async => values[id];
  @override
  Future<bool> write(String id, String value) async {
    if (fail) return false;
    values[id] = value;
    return true;
  }
}

void main() {
  final original = jsonEncode({
    'version': 1,
    'points': [
      {'site': 'ГП', 'name': 'A', 'x': .2, 'y': .3, 'unknown': true},
      {'site': 'ДКС', 'name': 'A', 'x': .4, 'y': .5, 'guide': 'future'},
      {'site': 'УПМТ', 'name': 'B', 'x': .6, 'y': .7},
    ],
  });
  test(
    'migration writes new validated snapshot without overwriting v1',
    () async {
      final store = MemoryStore()
        ..values[PositionRepositoryV2.v1Key] = original;
      final repo = PositionRepositoryV2(store);
      final result = await repo.load();
      expect(result.points.length, 3);
      expect(result.points.first['coordinateSpace'], 'sketch');
      expect(store.values[PositionRepositoryV2.v1Key], original);
      expect(
        jsonDecode(store.values[PositionRepositoryV2.v2Key]!)['version'],
        2,
      );
      expect((await repo.load()).points[1]['guide'], 'future');
    },
  );
  test(
    'corrupt v2 and failed migration do not fall back or destroy v1',
    () async {
      final store = MemoryStore()
        ..values[PositionRepositoryV2.v1Key] = original;
      store.values[PositionRepositoryV2.v2Key] = 'broken';
      await expectLater(
        PositionRepositoryV2(store).load(),
        throwsFormatException,
      );
      expect(store.values[PositionRepositoryV2.v2Key], 'broken');
      store.values.remove(PositionRepositoryV2.v2Key);
      store.fail = true;
      await expectLater(PositionRepositoryV2(store).load(), throwsStateError);
      expect(store.values[PositionRepositoryV2.v1Key], original);
      expect(store.values.containsKey(PositionRepositoryV2.v2Key), isFalse);
    },
  );
}
