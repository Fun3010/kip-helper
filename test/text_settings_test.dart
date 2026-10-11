import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kip_helper/services/text_settings.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  for (final stored in [null, 'large', 0.5, 2.0, double.nan]) {
    test('Invalid saved text size falls back: $stored', () async {
      SharedPreferences.setMockInitialValues({
        if (stored != null) TextSettings.storageKey: stored,
      });
      final settings = TextSettings();
      await settings.load();
      expect(settings.scale, 1);
      expect(settings.ready, isTrue);
      settings.dispose();
    });
  }
  test(
    'Text scale composes with system scale and ordered writes retain latest',
    () async {
      SharedPreferences.setMockInitialValues({});
      final settings = TextSettings();
      await settings.load();
      settings.select(1.2);
      settings.select(1.5);
      expect(settings.apply(const TextScaler.linear(1.4)).scale(10), 21);
      await pumpEventQueue();
      final restored = TextSettings();
      await restored.load();
      expect(restored.scale, 1.5);
      restored.select(1);
      await pumpEventQueue();
      final reset = TextSettings();
      await reset.load();
      expect(reset.scale, 1);
      settings.dispose();
      restored.dispose();
      reset.dispose();
    },
  );
}
