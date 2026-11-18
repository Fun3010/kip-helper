import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/services.dart';

const positionSites = ['ГП', 'ДКС', 'УПМТ'];
const maxPositionBackupBytes = 2 * 1024 * 1024;

/// Validate the exact persisted format without discarding unknown fields.
List<Map<String, dynamic>> decodePositionSnapshot(String raw) {
  if (utf8.encode(raw).length > maxPositionBackupBytes) {
    throw const FormatException('Backup too large');
  }
  final data = jsonDecode(raw);
  if (data is! Map || data['version'] != 1 || data['points'] is! List) {
    throw const FormatException('Unsupported backup');
  }
  final parsed = <Map<String, dynamic>>[];
  for (final entry in data['points'] as List) {
    if (entry is! Map ||
        entry['site'] is! String ||
        !positionSites.contains(entry['site']) ||
        entry['name'] is! String ||
        (entry['name'] as String).trim().isEmpty ||
        entry['x'] is! num ||
        entry['y'] is! num ||
        !(entry['x'] as num).isFinite ||
        !(entry['y'] as num).isFinite ||
        (entry['x'] as num) < 0 ||
        (entry['x'] as num) > 1 ||
        (entry['y'] as num) < 0 ||
        (entry['y'] as num) > 1 ||
        (entry['guide'] != null && entry['guide'] is! String)) {
      throw const FormatException('Invalid position');
    }
    parsed.add(Map<String, dynamic>.from(entry));
  }
  return parsed;
}

abstract interface class PositionBackupIO {
  Future<String?> pickBackup();

  /// True means the file was saved; false means the user cancelled.
  Future<bool> saveBackup(String content);
}

class PlatformPositionBackupIO implements PositionBackupIO {
  PlatformPositionBackupIO({bool? android})
    : _isAndroid = android ?? Platform.isAndroid;
  final bool _isAndroid;
  static const _android = MethodChannel('ru.kiphelper.app/position_backup');
  static const _filename = 'kip-helper-positions.json';

  @override
  Future<String?> pickBackup() async {
    const type = XTypeGroup(
      label: 'JSON',
      extensions: ['json'],
      mimeTypes: ['application/json', 'text/plain'],
      uniformTypeIdentifiers: ['public.json'],
    );
    final file = await openFile(acceptedTypeGroups: [type]);
    if (file == null) return null;
    final builder = BytesBuilder(copy: false);
    var count = 0;
    await for (final chunk in file.openRead()) {
      count += chunk.length;
      if (count > maxPositionBackupBytes) {
        throw const FormatException('Backup too large');
      }
      builder.add(chunk);
    }
    return utf8.decode(builder.takeBytes());
  }

  @override
  Future<bool> saveBackup(String content) async {
    final bytes = Uint8List.fromList(utf8.encode(content));
    if (bytes.length > maxPositionBackupBytes) {
      throw const FormatException('Backup too large');
    }
    if (_isAndroid) {
      return await _android.invokeMethod<bool>('save', {
            'name': _filename,
            'bytes': bytes,
          }) ??
          false;
    }
    final location = await getSaveLocation(
      suggestedName: _filename,
      acceptedTypeGroups: const [
        XTypeGroup(
          label: 'JSON',
          extensions: ['json'],
          mimeTypes: ['application/json'],
          uniformTypeIdentifiers: ['public.json'],
        ),
      ],
    );
    if (location == null) return false;
    await XFile.fromData(
      bytes,
      mimeType: 'application/json',
      name: _filename,
    ).saveTo(location.path);
    return true;
  }
}
