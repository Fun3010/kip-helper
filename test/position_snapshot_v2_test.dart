import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:kip_helper/services/position_snapshot_v2.dart';

void main() {
  test('v1 migration retains every site, unknown fields and unknown guide', () {
    final raw = jsonEncode({
      'version': 1,
      'points': [
        {
          'site': 'ГП',
          'name': 'A',
          'x': .1,
          'y': .9,
          'guide': 'unknown',
          'extra': {'future': true},
        },
        {'site': 'ДКС', 'name': 'A', 'x': .2, 'y': .8},
        {'site': 'УПМТ', 'name': 'B', 'x': .3, 'y': .7},
      ],
    });
    final snapshot = PositionSnapshotV2.decode(raw);
    expect(
      snapshot.points.map((p) => p['coordinateSpace']),
      everyElement('sketch'),
    );
    expect(snapshot.points.first['guide'], 'unknown');
    expect(snapshot.points.first['extra'], {'future': true});
    final restored = PositionSnapshotV2.decode(snapshot.encode());
    expect(restored.points, snapshot.points);
  });

  test('sheet coordinates require matching sheet identity and hash', () {
    const hash =
        'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
    String document(String pointHash) => jsonEncode({
      'version': 2,
      'sheets': [
        {
          'id': 'synthetic',
          'site': 'ГП',
          'sha256': hash,
          'width': 1000,
          'height': 600,
        },
      ],
      'points': [
        {
          'site': 'ГП',
          'name': 'Example',
          'coordinateSpace': 'sheet',
          'sheetId': 'synthetic',
          'sheetSha256': pointHash,
          'x': .1,
          'y': .15,
        },
        {
          'site': 'ГП',
          'name': 'Pending',
          'coordinateSpace': 'unplaced',
          'source': {'note': 'user input'},
        },
      ],
    });
    final valid = PositionSnapshotV2.decode(document(hash));
    expect(valid.points.last.containsKey('x'), isFalse);
    expect(PositionSnapshotV2.decode(valid.encode()).points, valid.points);
    expect(
      () => PositionSnapshotV2.decode(document('b' * 64)),
      throwsFormatException,
    );
  });

  test('unplaced must not silently carry scene coordinates', () {
    final raw = jsonEncode({
      'version': 2,
      'sheets': [],
      'points': [
        {
          'site': 'ГП',
          'name': 'Pending',
          'coordinateSpace': 'unplaced',
          'x': .2,
          'y': .3,
        },
      ],
    });
    expect(() => PositionSnapshotV2.decode(raw), throwsFormatException);
  });
}
