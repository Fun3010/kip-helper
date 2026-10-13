import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kip_helper/data/guides.dart';
import 'package:kip_helper/features/guides/guide_page.dart';
import 'package:kip_helper/features/notes/guide_notes_page.dart';
import 'package:kip_helper/services/guide_notes.dart';
import 'package:kip_helper/services/quick_access.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'guide_notes_test.dart' show MemoryNotesStore;

Future<GlobalKey<NavigatorState>> openNotes(
  WidgetTester tester,
  GuideNotesController controller, {
  bool dark = false,
  double scale = 1,
}) async {
  final navigator = GlobalKey<NavigatorState>();
  await tester.pumpWidget(
    MaterialApp(
      navigatorKey: navigator,
      theme: ThemeData(brightness: dark ? Brightness.dark : Brightness.light),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(scale)),
        child: child!,
      ),
      home: const Scaffold(body: Text('Каталог')),
    ),
  );
  navigator.currentState!.push(
    MaterialPageRoute<void>(
      builder: (_) => GuideNotesPage(
        guideId: 'sipart',
        guideTitle: 'SIPART PS2',
        controller: controller,
      ),
    ),
  );
  await tester.pumpAndSettle();
  return navigator;
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets(
    'Guide overflow opens personal notes preserving existing actions',
    (tester) async {
      final quick = QuickAccessController(guides);
      await quick.load();
      addTearDown(quick.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: GuidePage(
            guide: guides.firstWhere((guide) => guide.id == 'sipart'),
            quickAccess: quick,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byTooltip('Добавить SIPART PS2 в избранное'), findsOneWidget);
      expect(find.byTooltip('Развернуть всё'), findsOneWidget);
      await tester.tap(find.byTooltip('Дополнительные действия'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Личные заметки'));
      await tester.pumpAndSettle();
      expect(find.byType(GuideNotesPage), findsOneWidget);
      expect(find.textContaining('SIPART PS2'), findsWidgets);
    },
  );

  testWidgets('Explicit save failure preserves editor and retry succeeds', (
    tester,
  ) async {
    final store = MemoryNotesStore()..failWrite = true;
    final controller = GuideNotesController('sipart', store: store);
    addTearDown(controller.dispose);
    await openNotes(tester, controller);
    await tester.enterText(find.byType(TextField), '  exact\ntext  ');
    await tester.pump();
    expect(store.values, isEmpty);
    await tester.tap(find.text('Сохранить'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Не удалось сохранить'), findsOneWidget);
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      '  exact\ntext  ',
    );
    store.failWrite = false;
    await tester.tap(find.text('Повторить сохранение'));
    await tester.pumpAndSettle();
    expect(find.text('Сохранено'), findsOneWidget);
    expect(store.values['sipart'], '  exact\ntext  ');
    expect(tester.takeException(), isNull);
  });

  testWidgets('Failed load disables edits and retry restores saved text', (
    tester,
  ) async {
    final store = MemoryNotesStore()
      ..values['sipart'] = 'saved'
      ..failRead = true;
    final controller = GuideNotesController('sipart', store: store);
    addTearDown(controller.dispose);
    await openNotes(tester, controller);
    expect(tester.widget<TextField>(find.byType(TextField)).enabled, isFalse);
    expect(find.textContaining('Не удалось загрузить'), findsOneWidget);
    store.failRead = false;
    await tester.tap(find.text('Повторить загрузку'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      'saved',
    );
    expect(store.values['sipart'], 'saved');
  });

  for (final exit in ['app bar', 'programmatic', 'system']) {
    testWidgets('Dirty $exit exit supports cancelled discard then discard', (
      tester,
    ) async {
      final controller = GuideNotesController(
        'sipart',
        store: MemoryNotesStore(),
      );
      addTearDown(controller.dispose);
      final navigator = await openNotes(tester, controller);
      await tester.enterText(find.byType(TextField), 'unsaved');
      await tester.pump();
      Future<void> back() async {
        if (exit == 'app bar') {
          await tester.tap(find.byType(BackButton));
        } else if (exit == 'programmatic') {
          navigator.currentState!.pop();
        } else {
          await tester.binding.handlePopRoute();
        }
        await tester.pumpAndSettle();
      }

      await back();
      expect(find.text('Несохранённые изменения'), findsOneWidget);
      await tester.tap(find.text('Продолжить редактирование'));
      await tester.pumpAndSettle();
      expect(find.byType(GuideNotesPage), findsOneWidget);
      expect(controller.text, 'unsaved');
      await back();
      await tester.tap(find.text('Выйти без сохранения'));
      await tester.pumpAndSettle();
      expect(find.byType(GuideNotesPage), findsNothing);
      expect(find.text('Каталог'), findsOneWidget);
    });
  }

  testWidgets(
    'Exit save failure stays in editor until successful retry and back',
    (tester) async {
      final store = MemoryNotesStore()..failWrite = true;
      final controller = GuideNotesController('sipart', store: store);
      addTearDown(controller.dispose);
      await openNotes(tester, controller);
      await tester.enterText(find.byType(TextField), 'keep me');
      await tester.pump();
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Сохранить и выйти'));
      await tester.pumpAndSettle();
      expect(find.byType(GuideNotesPage), findsOneWidget);
      expect(controller.text, 'keep me');
      store.failWrite = false;
      await tester.tap(find.text('Повторить сохранение'));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.byType(GuideNotesPage), findsNothing);
      expect(store.values['sipart'], 'keep me');
    },
  );

  testWidgets('Clear cancel retains text and confirm requires explicit save', (
    tester,
  ) async {
    final store = MemoryNotesStore()..values['sipart'] = 'old note';
    final controller = GuideNotesController('sipart', store: store);
    addTearDown(controller.dispose);
    await openNotes(tester, controller);
    await tester.tap(find.text('Очистить'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Отмена'));
    await tester.pumpAndSettle();
    expect(controller.text, 'old note');
    await tester.tap(find.text('Очистить'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Очистить текст'));
    await tester.pumpAndSettle();
    expect(controller.text, isEmpty);
    expect(controller.dirty, isTrue);
    expect(store.values['sipart'], 'old note');
    await tester.tap(find.text('Сохранить'));
    await tester.pumpAndSettle();
    expect(store.values['sipart'], isEmpty);
  });

  for (final dark in [false, true]) {
    testWidgets(
      'Notes and confirmations fit 320px with keyboard and 2.25 scale dark=$dark',
      (tester) async {
        tester.view.physicalSize = const Size(320, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetViewInsets);
        final controller = GuideNotesController(
          'sipart',
          store: MemoryNotesStore(),
        );
        addTearDown(controller.dispose);
        await openNotes(tester, controller, dark: dark, scale: 2.25);
        await tester.enterText(find.byType(TextField), 'Личный текст');
        tester.view.viewInsets = const FakeViewPadding(bottom: 300);
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text('Сохранить'));
        expect(find.text('Сохранить').hitTestable(), findsOneWidget);
        await tester.tap(find.text('Сохранить'));
        await tester.pumpAndSettle();
        expect(controller.dirty, isFalse);
        await tester.ensureVisible(find.text('Очистить'));
        await tester.tap(find.text('Очистить'));
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text('Отмена'));
        await tester.tap(find.text('Отмена'));
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextField), 'Изменённый текст');
        await tester.pump();
        await tester.tap(find.byType(BackButton));
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text('Продолжить редактирование'));
        await tester.tap(find.text('Продолжить редактирование'));
        await tester.pumpAndSettle();
        expect(
          MediaQuery.textScalerOf(
            tester.element(find.byType(TextField)),
          ).scale(10),
          22.5,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }
}
