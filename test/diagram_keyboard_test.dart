import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kip_helper/data/guides.dart';
import 'package:kip_helper/widgets/guide_illustration.dart';

bool primaryFocusWithin(Element target) {
  final context = FocusManager.instance.primaryFocus?.context;
  if (context == target) return true;
  var found = false;
  context?.visitAncestorElements((element) {
    found = element == target;
    return !found;
  });
  return found;
}

Future<void> tabTo(WidgetTester tester, Finder target) async {
  for (var i = 0; i < 12; i++) {
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    if (primaryFocusWithin(tester.element(target))) return;
  }
  fail('Tab traversal did not reach $target');
}

void main() {
  for (final dark in [false, true]) {
    testWidgets(
      'diagram zoom/reset respond to Tab and keyboard, dark=$dark',
      (tester) async {
        tester.view.physicalSize = const Size(1280, 720);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final illustration = guides
            .singleWhere((g) => g.id == 'su1s')
            .illustrations
            .first;
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData(
              useMaterial3: true,
              brightness: dark ? Brightness.dark : Brightness.light,
            ),
            home: Scaffold(
              body: SingleChildScrollView(
                child: GuideIllustrationCard(illustration: illustration),
              ),
            ),
          ),
        );
        await tester.tap(find.text('${illustration.title} · увеличить'));
        await tester.pumpAndSettle();
        final transform = tester
            .widget<InteractiveViewer>(find.byType(InteractiveViewer))
            .transformationController!;
        final zoomIn = find.byTooltip('Увеличить');
        final zoomOut = find.byTooltip('Уменьшить');
        final reset = find.byTooltip('Вернуть исходный масштаб');

        // No direct callback invocation or requestFocus: these controls must be
        // reachable through the actual viewer's focus traversal and key actions.
        await tabTo(tester, zoomIn);
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pumpAndSettle();
        expect(transform.value.getMaxScaleOnAxis(), closeTo(1.5, 1e-9));
        await tester.sendKeyEvent(LogicalKeyboardKey.space);
        await tester.pumpAndSettle();
        expect(transform.value.getMaxScaleOnAxis(), closeTo(2.25, 1e-9));

        await tabTo(tester, zoomOut);
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pumpAndSettle();
        expect(transform.value.getMaxScaleOnAxis(), closeTo(1.5, 1e-9));
        await tabTo(tester, reset);
        await tester.sendKeyEvent(LogicalKeyboardKey.space);
        await tester.pumpAndSettle();
        expect(transform.value.getMaxScaleOnAxis(), 1);

        await tabTo(tester, zoomIn);
        await tester.sendKeyEvent(LogicalKeyboardKey.space);
        await tester.pumpAndSettle();
        expect(transform.value.getMaxScaleOnAxis(), closeTo(1.5, 1e-9));
        await tabTo(tester, reset);
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pumpAndSettle();
        expect(transform.value.getMaxScaleOnAxis(), 1);
        expect(tester.takeException(), isNull);
      },
      variant: TargetPlatformVariant.only(TargetPlatform.windows),
    );
  }
}
