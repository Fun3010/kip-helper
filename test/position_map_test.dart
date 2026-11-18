import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kip_helper/features/positions/position_map_page.dart';
import 'package:kip_helper/services/guide_notes.dart';

class MemoryPositionStore implements GuideNotesStore {
  final values = <String, String>{};
  bool failWrites = false;
  @override
  Future<Object?> read(String guideId) async => values[guideId];
  @override
  Future<bool> write(String guideId, String text) async {
    if (failWrites) return false;
    values[guideId] = text;
    return true;
  }
}

void main() {
  testWidgets(
    'Cancelling a move and a failed save leave the stored point unchanged',
    (tester) async {
      final store = MemoryPositionStore();
      const key = 'user-positions-map-v1';
      final original = jsonEncode({
        'version': 1,
        'points': [
          {'site': 'ГП', 'name': 'FT-101', 'guide': 'stm10', 'x': .2, 'y': .2},
        ],
      });
      store.values[key] = original;
      await tester.pumpWidget(MaterialApp(home: PositionMapPage(store: store)));
      await tester.pumpAndSettle();
      await tester.tap(find.text('FT-101').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Переместить'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Отменить перемещение'));
      await tester.pumpAndSettle();
      expect(store.values[key], original);
      await tester.tap(find.text('FT-101').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Переместить'));
      await tester.pumpAndSettle();
      store.failWrites = true;
      await tester.tapAt(
        tester.getTopLeft(find.byKey(const ValueKey('position-board'))) +
            const Offset(180, 240),
      );
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Не удалось сохранить изменение'),
        findsOneWidget,
      );
      expect(store.values[key], original);
      expect(find.text('FT-101'), findsWidgets);
    },
  );
  testWidgets(
    'Existing position can be renamed and moved without losing its guide',
    (tester) async {
      final store = MemoryPositionStore();
      store.values['user-positions-map-v1'] = jsonEncode({
        'version': 1,
        'points': [
          {'site': 'ГП', 'name': 'FT-101', 'guide': 'stm10', 'x': .2, 'y': .2},
        ],
      });
      await tester.pumpWidget(MaterialApp(home: PositionMapPage(store: store)));
      await tester.pumpAndSettle();
      await tester.tap(find.text('FT-101').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Изменить'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('position-name')),
        'FT-102',
      );
      await tester.tap(find.text('Сохранить'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('FT-102').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Переместить'));
      await tester.pumpAndSettle();
      final board = find.byKey(const ValueKey('position-board'));
      await tester.tapAt(tester.getTopLeft(board) + const Offset(180, 240));
      await tester.pumpAndSettle();
      final data = jsonDecode(store.values['user-positions-map-v1']!) as Map;
      final point = (data['points'] as List).single as Map;
      expect(point['name'], 'FT-102');
      expect(point['guide'], 'stm10');
      expect(point['x'], isNot(.2));
      expect(point['y'], closeTo(.75, .01));
      expect(point['site'], 'ГП');
    },
  );
  testWidgets('A user position persists on its selected site', (tester) async {
    final store = MemoryPositionStore();
    Future<void> open() async {
      await tester.pumpWidget(MaterialApp(home: PositionMapPage(store: store)));
      await tester.pumpAndSettle();
    }

    await open();
    expect(find.text('ГП'), findsWidgets);
    await tester.tap(find.text('ДКС').first);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const ValueKey('add-position')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('add-position')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('position-name')),
      'FT-101',
    );
    await tester.tap(find.text('Сохранить'));
    await tester.pumpAndSettle();
    expect(find.text('FT-101'), findsWidgets);
    await tester.pumpWidget(const SizedBox.shrink());
    await open();
    await tester.tap(find.text('ДКС').first);
    await tester.pumpAndSettle();
    expect(find.text('FT-101'), findsWidgets);
    await tester.tap(find.text('ГП').first);
    await tester.pumpAndSettle();
    expect(find.text('FT-101'), findsNothing);
  });

  testWidgets('Unreadable stored map is not silently overwritten', (
    tester,
  ) async {
    final store = MemoryPositionStore();
    store.values['user-positions-map-v1'] = 'broken';
    await tester.pumpWidget(MaterialApp(home: PositionMapPage(store: store)));
    await tester.pumpAndSettle();
    expect(find.textContaining('Не удалось прочитать карту'), findsOneWidget);
    expect(find.byKey(const ValueKey('add-position')), findsNothing);
    expect(store.values['user-positions-map-v1'], 'broken');
  });

  testWidgets('Map remains usable at 320px with enlarged text', (tester) async {
    tester.view.physicalSize = const Size(320, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(2.25)),
          child: child!,
        ),
        home: PositionMapPage(store: MemoryPositionStore()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('add-position')),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('add-position')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('position-name')), findsOneWidget);
    await tester.enterText(
      find.byKey(const ValueKey('position-name')),
      'FT-101',
    );
    await tester.ensureVisible(find.text('Сохранить'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Сохранить'));
    await tester.pumpAndSettle();
    expect(find.text('FT-101'), findsWidgets);
    await tester.ensureVisible(find.text('FT-101').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('FT-101').first);
    await tester.pumpAndSettle();
    expect(find.text('Изменить'), findsOneWidget);
    expect(find.text('Переместить'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
