import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kip_helper/data/guides.dart';
import 'package:kip_helper/data/guide_procedures.dart';
import 'package:kip_helper/features/guides/guide_page.dart';
import 'package:kip_helper/features/guides/procedure_page.dart';
import 'package:kip_helper/models/guide.dart';
import 'package:kip_helper/widgets/guide_evidence.dart';
import 'package:kip_helper/app.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const note = 'Это рабочая памятка, а не процедура изготовителя.';
  const guide = InstrumentGuide(
    id: 'fixture',
    title: 'Прибор',
    subtitle: 'Исполнение',
    category: 'Тест',
    scope: 'Только указанное исполнение',
    sections: [
      GuideSection(
        title: 'Проверка',
        paragraphs: ['Запишите индикацию.'],
        evidenceByParagraph: {
          0: [
            GuideEvidence(
              sourceKey: 're',
              locator: '§ 2 · с. 10',
              state: GuideEvidenceState.workingChecklist,
              note: note,
            ),
          ],
        },
      ),
    ],
    sources: [
      GuideSource(
        key: 're',
        title: 'Полное название документа',
        document: 'manual.pdf',
      ),
    ],
  );

  testWidgets('Bibliography is collapsed but checklist status stays visible', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: GuidePage(guide: guide)));
    await tester.tap(find.text('Проверка'));
    await tester.pumpAndSettle();
    expect(find.text(note), findsNothing);
    expect(find.textContaining('Рабочий чек-лист'), findsOneWidget);
    await tester.ensureVisible(find.text('§ 2 · с. 10'));
    await tester.tap(find.text('§ 2 · с. 10'));
    await tester.pumpAndSettle();
    expect(find.text(note), findsOneWidget);
    expect(find.text('Запишите индикацию.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'SIPART step shows real controls and navigation without source scrolling',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ProcedurePage(procedure: proceduresForGuide('sipart').first),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Все шаги'), findsNothing);
      for (final key in [
        'variant-rotary',
        'procedure-confirm',
        'procedure-start',
      ]) {
        await tester.ensureVisible(find.byKey(ValueKey(key)));
        await tester.tap(find.byKey(ValueKey(key)));
        await tester.pumpAndSettle();
      }
      expect(find.text('Все шаги'), findsOneWidget);
      expect(find.text('Вход в конфигурацию'), findsOneWidget);
      expect(find.byType(Image), findsWidgets);
      final next = find.byKey(const ValueKey('procedure-next'));
      expect(
        tester.getRect(next).bottom,
        lessThanOrEqualTo(tester.view.physicalSize.height),
      );
      await tester.tap(find.text('Все шаги'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Запуск инициализации'));
      await tester.tap(find.text('Запуск инициализации'));
      await tester.pumpAndSettle();
      expect(find.text('Не менее 5 секунд'), findsOneWidget);
      expect(find.text('Strt'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'RUN2 search presents an isolated stage instead of a wall of text',
    (tester) async {
      final sipart = guides.singleWhere((g) => g.id == 'sipart');
      await tester.pumpWidget(MaterialApp(home: GuidePage(guide: sipart)));
      await tester.enterText(find.byType(TextField), 'RUN2');
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: find.byType(GuideFieldEntryCard),
          matching: find.text('RUN2'),
        ),
        findsOneWidget,
      );
      expect(find.textContaining('Определение хода'), findsOneWidget);
      expect(find.text('RUN1'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Catalogue search opens the matching stage with its query intact',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(const KipHelperApp());
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'RUN2');
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('SIPART PS2'));
      await tester.tap(find.text('SIPART PS2'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        'RUN2',
      );
      expect(
        find.descendant(
          of: find.byType(GuideFieldEntryCard),
          matching: find.text('RUN2'),
        ),
        findsOneWidget,
      );
      expect(find.text('RUN1'), findsNothing);
    },
  );
  for (final code in ['213', '217']) {
    testWidgets('Protection $code keeps the shared non-setpoint warning', (
      tester,
    ) async {
      final sokrat = guides.singleWhere((g) => g.id == 'sokrat');
      await tester.pumpWidget(
        MaterialApp(
          home: GuidePage(guide: sokrat, initialQuery: code),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Это не рекомендуемые уставки'),
        findsOneWidget,
      );
    });
  }

  testWidgets(
    'Instrument-name search opens its full guide rather than an empty filter',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(const KipHelperApp());
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'СОКРАТ');
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.descendant(of: find.byType(Card), matching: find.text('СОКРАТ')),
      );
      await tester.tap(
        find.descendant(of: find.byType(Card), matching: find.text('СОКРАТ')),
      );
      await tester.pumpAndSettle();
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        isEmpty,
      );
      expect(find.text('Запись закрытого положения'), findsOneWidget);
    },
  );

  testWidgets('Ordinary search cannot bypass the SIPART procedure scope', (
    tester,
  ) async {
    final sipart = guides.singleWhere((g) => g.id == 'sipart');
    await tester.pumpWidget(
      MaterialApp(
        home: GuidePage(guide: sipart, initialQuery: 'Strt'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('удерживайте кнопку «+»'), findsNothing);
    expect(find.text('Настройка по шагам'), findsOneWidget);
  });

  for (final dark in [false, true]) {
    testWidgets(
      'SIPART controls and cancellation fit 320dp at 225%, dark=$dark',
      (tester) async {
        tester.view.physicalSize = const Size(320, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData(
              brightness: dark ? Brightness.dark : Brightness.light,
            ),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: const TextScaler.linear(2.25)),
              child: child!,
            ),
            home: ProcedurePage(procedure: proceduresForGuide('sipart').first),
          ),
        );
        await tester.pumpAndSettle();
        for (final key in [
          'variant-linear',
          'procedure-confirm',
          'procedure-start',
        ]) {
          await tester.ensureVisible(find.byKey(ValueKey(key)));
          await tester.tap(find.byKey(ValueKey(key)));
          await tester.pumpAndSettle();
        }
        expect(find.text('Вход в конфигурацию'), findsOneWidget);
        expect(
          find.byKey(const ValueKey('procedure-next')).hitTestable(),
          findsOneWidget,
        );
        await tester.ensureVisible(find.text('Как прервать на приборе'));
        await tester.tap(find.text('Как прервать на приборе'));
        await tester.pumpAndSettle();
        expect(find.text('Прерывание на самом приборе'), findsOneWidget);
        expect(
          find.textContaining('Только во время незавершённой'),
          findsOneWidget,
        );
        await tester.ensureVisible(find.text('Закрыть памятку'));
        await tester.tap(find.text('Закрыть памятку'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      },
    );
  }
}
