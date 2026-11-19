import 'dart:convert';

import 'position_backup.dart';

/// Versioned map data. Image bytes and device paths are stored separately.
class PositionSnapshotV2 {
  PositionSnapshotV2._(this.points, this.sheets);

  final List<Map<String, dynamic>> points;
  final List<Map<String, dynamic>> sheets;

  static PositionSnapshotV2 decode(String raw) {
    if (utf8.encode(raw).length > maxPositionBackupBytes) {
      throw const FormatException('Backup too large');
    }
    final value = jsonDecode(raw);
    if (value is! Map || value['points'] is! List) {
      throw const FormatException('Invalid snapshot');
    }
    if (value['version'] == 1) {
      return PositionSnapshotV2._([
        for (final p in decodePositionSnapshot(raw))
          {...p, 'coordinateSpace': 'sketch'},
      ], []);
    }
    if (value['version'] != 2 || value['sheets'] is! List) {
      throw const FormatException('Unsupported snapshot');
    }
    final sheets = <Map<String, dynamic>>[];
    final keys = <String>{};
    for (final item in value['sheets'] as List) {
      if (item is! Map ||
          item['id'] is! String ||
          (item['id'] as String).isEmpty ||
          !positionSites.contains(item['site']) ||
          item['sha256'] is! String ||
          !RegExp(r'^[0-9a-f]{64}$').hasMatch(item['sha256'] as String) ||
          item['width'] is! num ||
          item['height'] is! num ||
          !(item['width'] as num).isFinite ||
          !(item['height'] as num).isFinite ||
          (item['width'] as num) <= 0 ||
          (item['height'] as num) <= 0 ||
          item.keys.any(
            (key) => !const {
              'id',
              'site',
              'sha256',
              'width',
              'height',
              'title',
              'source',
            }.contains(key),
          )) {
        throw const FormatException('Invalid sheet metadata');
      }
      final key = '${item['id']}|${item['sha256']}';
      if (!keys.add(key)) throw const FormatException('Duplicate sheet');
      sheets.add(Map<String, dynamic>.from(item));
    }
    final points = <Map<String, dynamic>>[];
    for (final item in value['points'] as List) {
      if (item is! Map ||
          !positionSites.contains(item['site']) ||
          item['name'] is! String ||
          (item['name'] as String).trim().isEmpty ||
          (item['guide'] != null && item['guide'] is! String)) {
        throw const FormatException('Invalid position');
      }
      final space = item['coordinateSpace'];
      if (space == 'unplaced') {
        if (item.containsKey('x') || item.containsKey('y')) {
          throw const FormatException('Unplaced position has coordinates');
        }
      } else if (space == 'sketch' || space == 'sheet') {
        for (final axis in ['x', 'y']) {
          final n = item[axis];
          if (n is! num || !n.isFinite || n < 0 || n > 1) {
            throw const FormatException('Invalid coordinate');
          }
        }
        if (space == 'sheet' &&
            !sheets.any(
              (s) =>
                  s['id'] == item['sheetId'] &&
                  s['sha256'] == item['sheetSha256'] &&
                  s['site'] == item['site'],
            )) {
          throw const FormatException('Sheet version missing');
        }
      } else {
        throw const FormatException('Unknown coordinate space');
      }
      points.add(Map<String, dynamic>.from(item));
    }
    return PositionSnapshotV2._(points, sheets);
  }

  String encode() {
    final raw = jsonEncode({'version': 2, 'sheets': sheets, 'points': points});
    PositionSnapshotV2.decode(raw);
    return raw;
  }
}
