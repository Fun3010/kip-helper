import 'dart:io';
import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kip_helper/app.dart';
import 'package:kip_helper/data/guides.dart';
import 'package:kip_helper/domain/calculations.dart';
import 'package:kip_helper/features/calculators/rtd_calculator.dart';
import 'package:kip_helper/features/calculators/signal_calculator.dart';
import 'package:kip_helper/features/calculators/unit_converter.dart';
import 'package:kip_helper/features/guides/guide_page.dart';
import 'package:kip_helper/services/open_source.dart';
import 'package:kip_helper/widgets/su1s_contacts.dart';
import 'package:kip_helper/widgets/guide_illustration.dart';

void phone(WidgetTester tester, {double width = 390}) {
  tester.view.physicalSize = Size(width, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Widget screen(Widget child, {bool dark = false, double scale = 1}) =>
    MaterialApp(
      theme: ThemeData(
        useMaterial3: true,
        brightness: dark ? Brightness.dark : Brightness.light,
      ),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(scale)),
        child: child!,
      ),
      home: child,
    );

void main() {
  for (final brightness in Brightness.values) {
    testWidgets('Catalogue fits 320px at large text in $brightness', (
      tester,
    ) async {
      phone(tester, width: 320);
      tester.platformDispatcher.platformBrightnessTestValue = brightness;
      tester.platformDispatcher.textScaleFactorTestValue = 1.5;
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await tester.pumpWidget(const KipHelperApp());
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.drag(find.byType(ListView), const Offset(0, -600));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets('Guide illustrations expand with the global expand action', (
    tester,
  ) async {
    phone(tester);
    await tester.pumpWidget(
      screen(GuidePage(guide: guides.firstWhere((g) => g.id == 'iva8'))),
    );
    await tester.pumpAndSettle();
    expect(find.byType(GuideIllustrationCard), findsNothing);
    await tester.tap(find.byTooltip('Развернуть всё'));
    await tester.pumpAndSettle();
    expect(find.byType(GuideIllustrationCard), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('Fact evidence exposes verification state on the guide page', (
    tester,
  ) async {
    phone(tester, width: 320);
    await tester.pumpWidget(
      screen(
        GuidePage(guide: guides.firstWhere((g) => g.id == 'stm10')),
        scale: 1.5,
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Развернуть всё'));
    await tester.pumpAndSettle();
    expect(find.text('Скан · нужна визуальная сверка'), findsWidgets);
    expect(
      find.text('Рабочий чек-лист · не дословная процедура'),
      findsWidgets,
    );
    expect(find.textContaining('АПИ2.840.069 РЭ'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Category filter combines with search and resets', (
    tester,
  ) async {
    phone(tester);
    await tester.pumpWidget(const KipHelperApp());
    await tester.tap(find.widgetWithText(ChoiceChip, 'Влажность'));
    await tester.pumpAndSettle();
    expect(find.text('ИВА-8'), findsOneWidget);
    expect(find.text('SIPART PS2'), findsNothing);
    await tester.enterText(find.byType(TextField), 'SIPART');
    await tester.pumpAndSettle();
    expect(find.textContaining('Ничего не найдено'), findsOneWidget);
    await tester.tap(find.widgetWithText(ChoiceChip, 'Все'));
    await tester.pumpAndSettle();
    expect(find.text('SIPART PS2'), findsOneWidget);
    expect(find.text('ИВА-8'), findsNothing);
  });
  testWidgets('Offline illustration opens zoom viewer and returns', (
    tester,
  ) async {
    phone(tester, width: 320);
    final item = guides.firstWhere((g) => g.id == 'iva8').illustrations.single;
    await tester.pumpWidget(
      screen(
        Scaffold(
          body: SingleChildScrollView(
            child: GuideIllustrationCard(illustration: item),
          ),
        ),
        dark: true,
        scale: 1.5,
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('${item.title} · увеличить'));
    await tester.pumpAndSettle();
    expect(find.byType(InteractiveViewer), findsOneWidget);
    expect(find.textContaining('Разведите пальцы'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.byType(InteractiveViewer), findsNothing);
    expect(find.byType(GuideIllustrationCard), findsOneWidget);
  });
  setUpAll(() async {
    final configFile = File('.dart_tool/package_config.json');
    final config =
        jsonDecode(await configFile.readAsString()) as Map<String, dynamic>;
    final flutter = (config['packages'] as List)
        .cast<Map<String, dynamic>>()
        .firstWhere((p) => p['name'] == 'flutter');
    final sdk = Directory.fromUri(
      configFile.absolute.uri.resolve(flutter['rootUri'] as String),
    ).parent.parent;
    final fonts = Directory('${sdk.path}/bin/cache/artifacts/material_fonts');
    for (final family in ['Roboto', 'Ahem']) {
      final loader = FontLoader(family)
        ..addFont(
          File(
            '${fonts.path}/Roboto-Regular.ttf',
          ).readAsBytes().then((bytes) => ByteData.sublistView(bytes)),
        );
      await loader.load();
    }
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });
  testWidgets('Navigate library, search, calculator and back on a phone', (
    tester,
  ) async {
    phone(tester);
    await tester.pumpWidget(const KipHelperApp());
    await tester.enterText(find.byType(TextField), 'A01');
    await tester.pumpAndSettle();
    expect(find.text('СОКРАТ'), findsOneWidget);
    expect(find.text('SIPART PS2'), findsNothing);
    await tester.tap(find.text('СОКРАТ'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'zz-not-found');
    await tester.pumpAndSettle();
    expect(find.textContaining('Ничего не найдено'), findsOneWidget);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Расчёты'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Термосопротивление'));
    await tester.pumpAndSettle();
    expect(find.text('100 Ом'), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, '100');
    await tester.pump();
    expect(find.text('138,5055 Ом'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Units accept decimal comma, negatives, swaps and invalid input',
    (tester) async {
      phone(tester);
      await tester.pumpWidget(screen(const UnitConverter(pressure: false)));
      await tester.enterText(find.byType(TextField), '-40');
      await tester.pump();
      expect(find.text('-40 °F'), findsOneWidget);
      await tester.tap(find.byTooltip('Поменять единицы местами'));
      await tester.pumpAndSettle();
      expect(find.text('-40 °C'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'NaN');
      await tester.pump();
      expect(find.text('Введите конечное число'), findsOneWidget);
      await tester.enterText(find.byType(TextField), '32,0');
      await tester.pump();
      expect(find.text('0 °C'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Signal range validation and reverse conversion', (tester) async {
    phone(tester);
    await tester.pumpWidget(screen(const SignalCalculator()));
    await tester.ensureVisible(find.text('12 мА'));
    expect(find.text('12 мА'), findsOneWidget);
    await tester.enterText(find.byType(TextField).at(1), '0');
    await tester.pump();
    expect(
      find.text('Верхний предел должен быть больше нижнего'),
      findsOneWidget,
    );
    await tester.enterText(find.byType(TextField).at(1), '100');
    await tester.ensureVisible(find.byType(Switch));
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('50 ед.'));
    expect(find.text('50 ед.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Unavailable URL handler is reported without an exception', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => openSource(context, 'invalid://url'),
              child: const Text('Источник'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Источник'));
    await tester.pump();
    expect(find.textContaining('Не удалось открыть документ'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final dark in [false, true]) {
    for (final entry in <String, Widget>{
      'temperature': const UnitConverter(pressure: false),
      'pressure': const UnitConverter(pressure: true),
      'rtd': const RtdCalculator(),
      'signal': const SignalCalculator(),
      for (final guide in guides) guide.id: GuidePage(guide: guide),
    }.entries) {
      testWidgets('${entry.key}: narrow display and large text, dark=$dark', (
        tester,
      ) async {
        phone(tester, width: 320);
        await tester.pumpWidget(screen(entry.value, dark: dark, scale: 1.5));
        await tester.pumpAndSettle();
        if (entry.value is GuidePage) {
          await tester.tap(find.byTooltip('Развернуть всё'));
          await tester.pumpAndSettle();
        }
        expect(tester.takeException(), isNull);
        final scroll = find.byType(Scrollable).first;
        for (var n = 0; n < 5; n++) {
          await tester.drag(scroll, const Offset(0, -480));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        }
        await tester.pumpWidget(const SizedBox());
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('Sensor dropdown fits narrow screens and changes NSH', (
    tester,
  ) async {
    phone(tester, width: 320);
    await tester.pumpWidget(screen(const RtdCalculator(), scale: 1.5));
    await tester.tap(find.byType(DropdownButtonFormField<RtdSensor>));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('100П · α = 0,00391').last);
    await tester.tap(find.text('100П · α = 0,00391').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, '100');
    await tester.pump();
    expect(find.text('139,1059 Ом'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Contact diagram changes state and retains healthy relay meaning',
    (tester) async {
      phone(tester, width: 320);
      await tester.pumpWidget(
        screen(
          const Scaffold(
            body: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Su1sContacts(),
              ),
            ),
          ),
          dark: true,
          scale: 1.5,
        ),
      );
      expect(find.text('Среда ниже уровня'), findsOneWidget);
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();
      expect(find.text('Среда достигла уровня'), findsOneWidget);
      expect(find.text('Исправность · замкнуты'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Capture phone previews for visual inspection', (tester) async {
    phone(tester);
    final boundary = GlobalKey();
    await tester.pumpWidget(
      RepaintBoundary(key: boundary, child: const KipHelperApp()),
    );
    await tester.pumpAndSettle();
    Future<void> capture(String name) async {
      final render =
          boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      await tester.runAsync(() async {
        final image = await render.toImage(pixelRatio: 2);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        final file = File('build/qa/$name.png');
        await file.parent.create(recursive: true);
        await file.writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      });
    }

    await capture('library');
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    await tester.pumpAndSettle();
    await capture('library-dark');
    tester.platformDispatcher.clearPlatformBrightnessTestValue();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Расчёты'));
    await tester.pumpAndSettle();
    await capture('calculators');
    await tester.tap(find.text('Термосопротивление'));
    await tester.pumpAndSettle();
    await capture('rtd');
    await tester.pumpWidget(
      RepaintBoundary(
        key: boundary,
        child: screen(
          const Scaffold(
            body: SafeArea(
              child: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Su1sContacts(),
                ),
              ),
            ),
          ),
          dark: true,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await capture('su1s-contacts-dark');
    await tester.pumpWidget(
      RepaintBoundary(
        key: boundary,
        child: screen(
          GuidePage(guide: guides.firstWhere((g) => g.id == 'iva8')),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await capture('iva8-guide');
    await tester.pumpWidget(
      RepaintBoundary(
        key: boundary,
        child: screen(
          Scaffold(
            body: SingleChildScrollView(
              child: GuideIllustrationCard(
                illustration: guides
                    .firstWhere((g) => g.id == 'sokrat')
                    .illustrations
                    .last,
              ),
            ),
          ),
          dark: true,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await capture('sokrat-wiring');
  });
}
