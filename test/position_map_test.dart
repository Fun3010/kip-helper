import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kip_helper/features/positions/position_map_page.dart';
import 'package:kip_helper/services/guide_notes.dart';

class MemoryPositionStore implements GuideNotesStore {
  final values = <String, String>{};
  @override
  Future<Object?> read(String guideId) async => values[guideId];
  @override
  Future<bool> write(String guideId, String text) async {
    values[guideId] = text;
    return true;
  }
}

void main() {
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
    expect(tester.takeException(), isNull);
  });
}
