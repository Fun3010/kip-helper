import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kip_helper/services/desktop_close_guard.dart';

void main() {
  testWidgets(
    'window close respects cancellation and restores veto after failure',
    (tester) async {
      const channel = MethodChannel('window_manager');
      final calls = <MethodCall>[];
      var failClose = true;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            calls.add(call);
            if (call.method == 'close' && failClose) {
              throw PlatformException(code: 'close-failed');
            }
            return true;
          });
      addTearDown(() {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, null);
        DesktopCloseGuard.instance.confirmClose = null;
      });

      DesktopCloseGuard.instance.confirmClose = () async => false;
      DesktopCloseGuard.instance.onWindowClose();
      await tester.pump();
      expect(calls, isEmpty);

      final failure = Completer<Object>();
      DesktopCloseGuard.instance.confirmClose = () async => true;
      runZonedGuarded(
        () => DesktopCloseGuard.instance.onWindowClose(),
        (error, _) => failure.complete(error),
      );
      await tester.pump();
      await tester.pump();
      expect(await failure.future, isA<PlatformException>());
      expect(calls.map((c) => c.method), [
        'setPreventClose',
        'close',
        'setPreventClose',
      ]);
      expect(calls.first.arguments, {'isPreventClose': false});
      expect(calls.last.arguments, {'isPreventClose': true});

      var asked = false;
      DesktopCloseGuard.instance.confirmClose = () async {
        asked = true;
        return false;
      };
      DesktopCloseGuard.instance.onWindowClose();
      await tester.pump();
      expect(asked, isTrue);
      expect(calls.length, 3);

      failClose = false;
      DesktopCloseGuard.instance.confirmClose = () async => true;
      DesktopCloseGuard.instance.onWindowClose();
      await tester.pump();
      await tester.pump();
      expect(calls.map((c) => c.method), [
        'setPreventClose',
        'close',
        'setPreventClose',
        'setPreventClose',
        'close',
      ]);
      expect(calls[3].arguments, {'isPreventClose': false});
    },
  );
}
