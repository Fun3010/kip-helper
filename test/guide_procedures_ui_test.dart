import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kip_helper/data/guide_procedures.dart';
import 'package:kip_helper/features/guides/procedure_page.dart';

Future<void> openProcedure(
  WidgetTester tester, {
  bool dark = false,
  double scale = 1,
  String guideId = 'sokrat',
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(brightness: dark ? Brightness.dark : Brightness.light),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(scale)),
        child: child!,
      ),
      home: ProcedurePage(procedure: proceduresForGuide(guideId).first),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'Variant and prerequisites gate steps; navigation is reversible',
    (tester) async {
      await openProcedure(tester);
      expect(find.byKey(const ValueKey('procedure-step')), findsNothing);
      expect(
        tester
            .widget<FilledButton>(find.byKey(const ValueKey('procedure-start')))
            .onPressed,
        isNull,
      );
      await tapVisible(tester, find.byKey(const ValueKey('variant-r3-n3')));
      await tapVisible(tester, find.byKey(const ValueKey('procedure-confirm')));
      await tapVisible(tester, find.byKey(const ValueKey('procedure-start')));
      await tapVisible(tester, find.byKey(const ValueKey('procedure-back')));
      expect(find.byKey(const ValueKey('procedure-step')), findsNothing);
      expect(
        tester
            .widget<CheckboxListTile>(
              find.byKey(const ValueKey('procedure-confirm')),
            )
            .value,
        isFalse,
      );
      await tapVisible(tester, find.byKey(const ValueKey('variant-r3-n3')));
      expect(find.text('Перед началом'), findsOneWidget);
      expect(
        tester
            .widget<FilledButton>(find.byKey(const ValueKey('procedure-start')))
            .onPressed,
        isNull,
      );
      await tapVisible(tester, find.byKey(const ValueKey('procedure-confirm')));
      await tapVisible(tester, find.byKey(const ValueKey('procedure-start')));
      expect(find.text('Шаг 1 из 5'), findsOneWidget);
      expect(
        find.textContaining('не подтверждает состояние прибора'),
        findsOneWidget,
      );
      await tapVisible(tester, find.byKey(const ValueKey('procedure-next')));
      expect(find.text('Шаг 2 из 5'), findsOneWidget);
      await tapVisible(tester, find.byKey(const ValueKey('procedure-back')));
      expect(find.text('Шаг 1 из 5'), findsOneWidget);
      for (var step = 0; step < 5; step++) {
        await tapVisible(tester, find.byKey(const ValueKey('procedure-next')));
      }
      expect(find.text('Просмотр шагов завершён'), findsOneWidget);
      expect(
        find.textContaining('не подтверждает состояние прибора'),
        findsOneWidget,
      );
      await tapVisible(tester, find.byKey(const ValueKey('procedure-back')));
      expect(find.text('Шаг 5 из 5'), findsOneWidget);
      await tapVisible(tester, find.byKey(const ValueKey('procedure-reset')));
      expect(find.byKey(const ValueKey('procedure-step')), findsNothing);
      expect(
        tester
            .widget<FilledButton>(find.byKey(const ValueKey('procedure-start')))
            .onPressed,
        isNull,
      );
    },
  );

  testWidgets('Changing SIPART variant clears confirmation before start', (
    tester,
  ) async {
    await openProcedure(tester, guideId: 'sipart');
    await tapVisible(tester, find.byKey(const ValueKey('variant-linear')));
    await tapVisible(tester, find.byKey(const ValueKey('procedure-confirm')));
    await tapVisible(tester, find.byKey(const ValueKey('variant-rotary')));
    expect(
      tester
          .widget<CheckboxListTile>(
            find.byKey(const ValueKey('procedure-confirm')),
          )
          .value,
      isFalse,
    );
    expect(
      tester
          .widget<FilledButton>(find.byKey(const ValueKey('procedure-start')))
          .onPressed,
      isNull,
    );
    await tapVisible(tester, find.byKey(const ValueKey('procedure-confirm')));
    await tapVisible(tester, find.byKey(const ValueKey('procedure-start')));
    expect(find.textContaining('5.7'), findsWidgets);
    expect(find.textContaining('Поворотный привод · § 5.7'), findsWidgets);
  });

  for (final dark in [false, true]) {
    testWidgets(
      'Procedure fits 320px at 225% including source and controls dark=$dark',
      (tester) async {
        tester.view.physicalSize = const Size(320, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await openProcedure(tester, dark: dark, scale: 2.25);
        await tapVisible(tester, find.byKey(const ValueKey('variant-r3-n3')));
        await tapVisible(
          tester,
          find.byKey(const ValueKey('procedure-confirm')),
        );
        await tapVisible(tester, find.byKey(const ValueKey('procedure-start')));
        await tapVisible(tester, find.byKey(const ValueKey('procedure-next')));
        expect(find.text('Шаг 2 из 5'), findsOneWidget);
        await tester.ensureVisible(find.text('Источник шага'));
        expect(find.textContaining('PDF с. 51–52'), findsWidgets);
        await tapVisible(tester, find.byKey(const ValueKey('procedure-back')));
        await tapVisible(tester, find.byKey(const ValueKey('procedure-reset')));
        expect(tester.takeException(), isNull);
        expect(
          MediaQuery.textScalerOf(
            tester.element(find.byType(CheckboxListTile)),
          ).scale(10),
          22.5,
        );
      },
    );
  }
}
