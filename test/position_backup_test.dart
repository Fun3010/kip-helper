import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kip_helper/services/position_backup.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'Android export sends UTF-8 to the platform and distinguishes cancellation',
    () async {
      const channel = MethodChannel('ru.kiphelper.app/position_backup');
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      MethodCall? observed;
      var saved = false;
      messenger.setMockMethodCallHandler(channel, (call) async {
        observed = call;
        return saved;
      });
      addTearDown(() => messenger.setMockMethodCallHandler(channel, null));
      final io = PlatformPositionBackupIO(android: true);
      expect(await io.saveBackup('{"площадка":"ГП"}'), isFalse);
      expect(observed?.method, 'save');
      final args = observed!.arguments as Map;
      expect(args['name'], 'kip-helper-positions.json');
      expect(
        utf8.decode((args['bytes'] as List).cast<int>()),
        '{"площадка":"ГП"}',
      );
      saved = true;
      expect(await io.saveBackup('{}'), isTrue);
    },
  );
  test(
    'Snapshot validator rejects unsupported versions and invalid coordinates',
    () {
      for (final raw in [
        '{"version":2,"points":[]}',
        '{"version":1,"points":[{"site":"ГП","name":"X","x":-0.1,"y":0}]}',
        '{"version":1,"points":[{"site":"другая","name":"X","x":0,"y":0}]}',
        '{"version":1,"points":[{"site":"ГП","name":" ","x":0,"y":0}]}',
        'not json',
      ]) {
        expect(() => decodePositionSnapshot(raw), throwsFormatException);
      }
    },
  );
  test(
    'Snapshot validator preserves an unknown guide and extension fields',
    () {
      final raw = jsonEncode({
        'version': 1,
        'points': [
          {
            'site': 'ДКС',
            'name': 'FT-1',
            'guide': 'new-guide',
            'x': 0.1,
            'y': 1,
            'extra': 'kept',
          },
        ],
      });
      final point = decodePositionSnapshot(raw).single;
      expect(point['guide'], 'new-guide');
      expect(point['extra'], 'kept');
    },
  );
  test('Snapshot validator refuses oversized input', () {
    final raw = 'a' * (maxPositionBackupBytes + 1);
    expect(() => decodePositionSnapshot(raw), throwsFormatException);
  });
}
