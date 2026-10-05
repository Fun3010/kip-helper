import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kip_helper/app.dart';
import 'package:kip_helper/features/guides/guide_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> start(WidgetTester tester) async {
  await tester.pumpWidget(const KipHelperApp());
  await tester.pumpAndSettle();
}

Future<void> search(WidgetTester tester, String query) async {
  await tester.enterText(find.byType(TextField), query);
  await tester.pumpAndSettle();
}

Future<void> selectView(WidgetTester tester, String view) async {
  final chip = find.widgetWithText(ChoiceChip, view);
  await tester.ensureVisible(chip);
  await tester.tap(chip);
  await tester.pumpAndSettle();
}

Future<void> visit(WidgetTester tester, String title) async {
  await search(tester, title);
  await tester.tap(find.text(title));
  await tester.pumpAndSettle();
  expect(find.byType(GuidePage), findsOneWidget);
  await tester.pageBack();
  await tester.pumpAndSettle();
}

List<String> visibleGuideTitles(WidgetTester tester) => tester
    .widgetList<Text>(find.byType(Text))
    .map((text) => text.data)
    .whereType<String>()
    .where((title) => ['SIPART PS2', 'СОКРАТ', 'СУ-1С'].contains(title))
    .toList();

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets(
    'Catalogue favorite toggle does not navigate and filters results',
    (tester) async {
      await start(tester);
      await search(tester, 'SIPART');
      await tester.tap(find.byTooltip('Добавить SIPART PS2 в избранное'));
      await tester.pumpAndSettle();
      expect(find.byType(GuidePage), findsNothing);
      await search(tester, '');
      await selectView(tester, 'Избранное');
      expect(find.text('SIPART PS2'), findsOneWidget);
      expect(find.text('ИВА-8'), findsNothing);
      await tester.tap(find.byTooltip('Удалить SIPART PS2 из избранного'));
      await tester.pumpAndSettle();
      expect(find.text('SIPART PS2'), findsNothing);
      expect(
        find.textContaining('Пока нет избранных приборов'),
        findsOneWidget,
      );
    },
  );

  testWidgets('Detail favorite toggle updates catalogue on return', (
    tester,
  ) async {
    await start(tester);
    await search(tester, 'SIPART');
    await tester.tap(find.text('SIPART PS2'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Добавить SIPART PS2 в избранное'));
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();
    await selectView(tester, 'Избранное');
    expect(find.text('SIPART PS2'), findsOneWidget);
    expect(find.byTooltip('Удалить SIPART PS2 из избранного'), findsOneWidget);
  });

  testWidgets(
    'Recently viewed moves repeat visits to front without duplicates',
    (tester) async {
      await start(tester);
      await visit(tester, 'SIPART PS2');
      await visit(tester, 'СОКРАТ');
      await visit(tester, 'SIPART PS2');
      await search(tester, '');
      await selectView(tester, 'Недавние');
      expect(visibleGuideTitles(tester), ['SIPART PS2', 'СОКРАТ']);
      expect(find.text('ИВА-8'), findsNothing);
    },
  );

  testWidgets('Favorites and category restore in a fresh application tree', (
    tester,
  ) async {
    await start(tester);
    await search(tester, 'SIPART');
    await tester.tap(find.byTooltip('Добавить SIPART PS2 в избранное'));
    await tester.pumpAndSettle();
    await search(tester, '');
    await selectView(tester, 'Избранное');
    await selectView(tester, 'Позиционеры');
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    final preferences = await SharedPreferences.getInstance();
    await preferences.reload();
    await start(tester);
    expect(
      tester
          .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'Избранное'))
          .selected,
      isTrue,
    );
    expect(
      tester
          .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'Позиционеры'))
          .selected,
      isTrue,
    );
    expect(find.text('SIPART PS2'), findsOneWidget);
    expect(find.byTooltip('Удалить SIPART PS2 из избранного'), findsOneWidget);
  });

  testWidgets('Restored history drops obsolete ids and keeps newest order', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'kip.quickAccess.v1': jsonEncode({
        'favorites': ['obsolete-device', 'sipart'],
        'recent': ['su1s', 'sipart', 'su1s', 'obsolete-device'],
        'view': 'recent',
        'category': null,
      }),
    });
    await start(tester);
    expect(visibleGuideTitles(tester), ['СУ-1С', 'SIPART PS2']);
    expect(find.text('ИВА-8'), findsNothing);
    await selectView(tester, 'Избранное');
    expect(find.text('SIPART PS2'), findsOneWidget);
    expect(find.text('СУ-1С'), findsNothing);
  });

  for (final stored in [
    'broken-json',
    '[]',
    '{"favorites":42,"recent":false}',
  ]) {
    testWidgets('Invalid stored preferences recover catalogue: $stored', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({'kip.quickAccess.v1': stored});
      await start(tester);
      expect(find.text('ИВА-8'), findsOneWidget);
      await selectView(tester, 'Избранное');
      expect(
        find.textContaining('Пока нет избранных приборов'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  }

  for (final brightness in Brightness.values) {
    testWidgets('Quick access fits 320px at 150 percent text in $brightness', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 844);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.platformBrightnessTestValue = brightness;
      tester.platformDispatcher.textScaleFactorTestValue = 1.5;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await start(tester);
      await selectView(tester, 'Недавние');
      expect(find.textContaining('Пока нет недавних приборов'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
