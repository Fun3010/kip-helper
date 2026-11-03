import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kip_helper/domain/calculations.dart';
import 'package:kip_helper/domain/rtd_table.dart';
import 'package:kip_helper/features/calculators/rtd_table.dart';

Finder input(String label) => find.byWidgetPredicate(
  (widget) => widget is TextField && widget.decoration?.labelText == label,
);

Future<void> reveal(WidgetTester tester, Finder target, double delta) =>
    tester.scrollUntilVisible(
      target,
      delta,
      scrollable: find.byType(Scrollable).first,
    );

void main() {
  test('fine temperature grid keeps distinct displayed values', () {
    final table = generateRtdTable(
      sensor: RtdSensor.pt100,
      start: 1,
      end: 1.0001,
      step: 0.00001,
    );
    expect(
      formatRtdColumn(
        table.rows.map((r) => r.temperature).toList(),
      ).toSet().length,
      table.rows.length,
    );
  });
  final invalid = throwsA(isA<CalculationException>());

  group('RTD table generation', () {
    test('Pt100 table uses independent reference points', () {
      final table = generateRtdTable(
        sensor: RtdSensor.pt100,
        start: 0,
        end: 100,
        step: 100,
      );
      expect(table.rows.map((row) => row.temperature), [0, 100]);
      expect(table.rows.first.resistance, 100);
      expect(table.rows.last.resistance, closeTo(138.5055, 1e-9));
      expect(table.hasShortFinalStep, isFalse);
    });

    test(
      'GOST platinum and copper retain their independent characteristics',
      () {
        for (final entry in {
          RtdSensor.p100: 139.1059,
          RtdSensor.p50: 69.55295,
          RtdSensor.m100: 142.8,
          RtdSensor.m50: 71.4,
        }.entries) {
          final table = generateRtdTable(
            sensor: entry.key,
            start: 100,
            end: 100,
            step: 1,
          );
          expect(table.rows, hasLength(1));
          expect(table.rows.single.resistance, closeTo(entry.value, 1e-9));
        }
        final copper = generateRtdTable(
          sensor: RtdSensor.m100,
          start: -180,
          end: -100,
          step: 80,
        );
        expect(copper.rows.first.resistance, closeTo(20.53, 0.005));
        expect(copper.rows.last.resistance, closeTo(56.54, 0.005));
      },
    );

    test('includes a final endpoint shorter than a regular step', () {
      final table = generateRtdTable(
        sensor: RtdSensor.pt100,
        start: 0,
        end: 10,
        step: 3,
      );
      expect(table.rows.map((row) => row.temperature), [0, 3, 6, 9, 10]);
      expect(table.hasShortFinalStep, isTrue);
    });

    test('step larger than a tiny interval still includes both endpoints', () {
      final table = generateRtdTable(
        sensor: RtdSensor.pt100,
        start: 0,
        end: 1e-300,
        step: 1e300,
      );
      expect(table.rows.map((row) => row.temperature), [0, 1e-300]);
      expect(table.hasShortFinalStep, isTrue);
    });

    test('decimal grid has no cumulative drift or duplicate endpoint', () {
      final table = generateRtdTable(
        sensor: RtdSensor.pt100,
        start: -0.2,
        end: 0.3,
        step: 0.1,
      );
      expect(table.rows, hasLength(6));
      expect(table.rows.first.temperature, -0.2);
      expect(table.rows.last.temperature, 0.3);
      expect(table.hasShortFinalStep, isFalse);
      for (var index = 1; index < table.rows.length; index++) {
        expect(
          table.rows[index].temperature,
          greaterThan(table.rows[index - 1].temperature),
        );
      }
    });

    test(
      'allows 501 rows but rejects 502 and tiny steps before generation',
      () {
        expect(
          generateRtdTable(
            sensor: RtdSensor.pt100,
            start: 0,
            end: 50,
            step: 0.1,
          ).rows,
          hasLength(501),
        );
        for (final step in [0.0999, 1e-300, 5e-324]) {
          expect(
            () => generateRtdTable(
              sensor: RtdSensor.pt100,
              start: 0,
              end: 50,
              step: step,
            ),
            invalid,
          );
        }
        expect(
          () => generateRtdTable(
            sensor: RtdSensor.pt100,
            start: 0,
            end: 500.01,
            step: 1,
          ),
          invalid,
        );
      },
    );

    for (final sensor in RtdSensor.values) {
      test('${sensor.name} enforces its own inclusive bounds', () {
        final table = generateRtdTable(
          sensor: sensor,
          start: sensor.minTemperature,
          end: sensor.maxTemperature,
          step: 100,
        );
        expect(table.rows.first.temperature, sensor.minTemperature);
        expect(table.rows.last.temperature, sensor.maxTemperature);
        expect(
          () => generateRtdTable(
            sensor: sensor,
            start: sensor.minTemperature - 0.1,
            end: 0,
            step: 10,
          ),
          invalid,
        );
        expect(
          () => generateRtdTable(
            sensor: sensor,
            start: 0,
            end: sensor.maxTemperature + 0.1,
            step: 10,
          ),
          invalid,
        );
      });
    }

    test(
      'rejects reversed range, nonpositive step and every nonfinite input',
      () {
        for (final step in [0.0, -1.0]) {
          expect(
            () => generateRtdTable(
              sensor: RtdSensor.pt100,
              start: 0,
              end: 10,
              step: step,
            ),
            invalid,
          );
        }
        expect(
          () => generateRtdTable(
            sensor: RtdSensor.pt100,
            start: 10,
            end: 0,
            step: 1,
          ),
          invalid,
        );
        for (final value in [
          double.nan,
          double.infinity,
          double.negativeInfinity,
        ]) {
          for (final inputs in [
            [value, 100.0, 1.0],
            [0.0, value, 1.0],
            [0.0, 100.0, value],
          ]) {
            expect(
              () => generateRtdTable(
                sensor: RtdSensor.pt100,
                start: inputs[0],
                end: inputs[1],
                step: inputs[2],
              ),
              invalid,
            );
          }
        }
      },
    );
  });

  testWidgets('comma input generates only on request and clears stale rows', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: RtdTable()));
    expect(find.byKey(const ValueKey('rtd-table-results')), findsNothing);
    await tester.enterText(input('Начальная температура'), '0');
    await reveal(tester, input('Конечная температура'), 150);
    await tester.enterText(input('Конечная температура'), '0,5');
    await reveal(tester, input('Шаг температуры'), 150);
    await tester.enterText(input('Шаг температуры'), '0,25');
    await reveal(tester, find.text('Построить таблицу'), 150);
    await tester.tap(find.text('Построить таблицу'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('rtd-table-results')), findsOneWidget);
    expect(find.text('0,25 °C'), findsOneWidget);
    expect(find.text('0,5 °C'), findsOneWidget);
    await reveal(tester, input('Шаг температуры'), -150);
    await tester.enterText(input('Шаг температуры'), '0');
    await tester.pump();
    expect(find.byKey(const ValueKey('rtd-table-results')), findsNothing);
    await reveal(tester, find.text('Построить таблицу'), 150);
    await tester.tap(find.text('Построить таблицу'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('rtd-table-error')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final dark in [false, true]) {
    testWidgets('320px / 225% table with keyboard, dark=$dark', (tester) async {
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
            ).copyWith(textScaler: TextScaler.linear(2.25)),
            child: child!,
          ),
          home: const RtdTable(),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byType(DropdownButtonFormField<RtdSensor>));
      await tester.pumpAndSettle();
      await tester.dragFrom(const Offset(160, 650), const Offset(0, -500));
      await tester.pumpAndSettle();
      await tester.tap(find.text('100М · α = 0,00428').hitTestable());
      await tester.pumpAndSettle();
      expect(find.text('100М'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await reveal(tester, input('Конечная температура'), 150);
      await tester.enterText(input('Конечная температура'), '3');
      await reveal(tester, input('Шаг температуры'), 150);
      await tester.enterText(input('Шаг температуры'), '2');
      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      addTearDown(tester.view.resetViewInsets);
      await tester.pumpAndSettle();
      await reveal(tester, find.text('Построить таблицу'), 150);
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -180));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Построить таблицу').hitTestable());
      await tester.pumpAndSettle();
      await reveal(tester, find.text('3 °C'), 150);
      await tester.pumpAndSettle();
      expect(find.text('3 °C'), findsOneWidget);
      expect(find.textContaining('Последний шаг'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
