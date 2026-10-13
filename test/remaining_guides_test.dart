import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kip_helper/data/guides.dart';
import 'package:kip_helper/features/guides/guide_page.dart';
import 'package:kip_helper/models/guide.dart';
import 'package:kip_helper/widgets/guide_illustration.dart';

void main() {
  test('OPTIFLEX card identifies the supplied 1300C manual', () {
    final matches = guides.where((guide) => guide.id == 'optiflex1300c');
    expect(matches, hasLength(1));
    final guide = matches.single;
    expect(guide.title, 'OPTIFLEX 1300C');
    expect(guide.scope, contains('7.02534.11.00'));
    expect(guide.scope, contains('08/2005'));
    expect(guide.scope, contains('взрывозащиты'));
    expect(guide.matches('optiflex'), isTrue);
    expect(guide.matches('рефлекс'), isTrue);
    expect(guide.illustrations, hasLength(2));
    expect(guide.illustrations.first.source, contains('2.2.1.4'));
    expect(guide.illustrations.first.source, contains('PDF с. 14'));
    expect(guide.illustrations.last.source, contains('3.3.2'));
    expect(guide.illustrations.last.source, contains('PDF с. 35'));
  });

  test('Micro Motion card stays within 1700 and 2700 installation scope', () {
    final matches = guides.where((guide) => guide.id == 'micro_motion');
    expect(matches, hasLength(1));
    final guide = matches.single;
    expect(guide.title, 'Micro Motion 1700 / 2700');
    expect(guide.scope, contains('MMI-20021325'));
    expect(guide.scope, contains('Rev CA'));
    expect(guide.scope, contains('01/2012'));
    expect(guide.scope, contains('1000/2000'));
    expect(guide.scope, contains('калибровки'));
    expect(guide.sources.single.document, 'Micro_motion.pdf');
    expect(guide.sources.single.url, isNull);
    expect(guide.matches('2700'), isTrue);
    expect(guide.matches('1700'), isTrue);
    expect(guide.illustrations, hasLength(2));
    expect(guide.illustrations.first.source, contains('рис. 1-7'));
    expect(guide.illustrations.last.caption, contains('алюминиевый'));
    expect(guide.illustrations.last.source, contains('рис. 3-7'));
    expect(guide.illustrations.last.source, contains('PDF с. 25'));
    for (final source in guide.sources) {
      expect('${source.title} ${source.document}', isNot(contains('20001715')));
    }
  });

  test(
    'Remaining cards resolve evidence and exact illustration provenance',
    () {
      final manifest =
          (jsonDecode(File('docs/illustration-sources.json').readAsStringSync())
                  as List)
              .cast<Map<String, dynamic>>();
      const hashes = {
        'optiflex1300c':
            'c50821cdf7d9a868bc3543ce02b10857731e90f4948299afc68d490ecb407463',
        'micro_motion':
            '786bf06f67ec4e2e6194926709ba59fc2b60b043071c155125f3cb2cc8603335',
      };
      for (final id in hashes.keys) {
        final guide = guides.firstWhere((guide) => guide.id == id);
        expect(guide.sources.single.key, isNotNull);
        expect(guide.sources.single.document, isNotEmpty);
        expect(guide.sources.single.url, isNull);
        for (final section in guide.sections) {
          for (var index = 0; index < section.paragraphs.length; index++) {
            expect(section.evidenceFor(index), isNotEmpty);
            for (final evidence in section.evidenceFor(index)) {
              expect(guide.sourceByKey(evidence.sourceKey), isNotNull);
              expect(evidence.locator, contains('PDF с.'));
              expect(evidence.locator, contains('РЭ с.'));
              expect(
                evidence.state,
                anyOf(
                  GuideEvidenceState.verified,
                  GuideEvidenceState.workingChecklist,
                ),
              );
            }
          }
        }
        for (final illustration in guide.illustrations) {
          expect(File(illustration.asset).existsSync(), isTrue);
          final entries = manifest.where(
            (entry) => entry['asset'] == illustration.asset,
          );
          expect(entries, hasLength(1));
          final entry = entries.single;
          expect(entry['source_sha256'], hashes[id]);
          expect(entry['document_path'], guide.sources.single.document);
          expect(entry['source_url'], isNull);
          expect(entry['asset_sha256'], matches(RegExp(r'^[a-f0-9]{64}$')));
          expect(entry['pdf_page'], greaterThan(0));
          expect(entry['printed_page'], greaterThan(0));
          expect(entry['crop_points'], hasLength(4));
          expect(entry['method'], contains('no redrawing'));
        }
      }
    },
  );

  const figures = [
    (
      'optiflex1300c',
      'патрубок',
      'OPTIFLEX 1300C · присоединительный патрубок',
    ),
    ('optiflex1300c', 'точка к точке', 'OPTIFLEX 1300C · HART точка к точке'),
    ('micro_motion', 'рис. 1-7', 'Micro Motion · код модели и исполнения'),
    (
      'micro_motion',
      'рис. 3-7',
      'Micro Motion · 4-проводное подключение сенсора',
    ),
  ];
  for (final dark in [false, true]) {
    for (final (id, query, title) in figures) {
      testWidgets('Remaining figure search and zoom: $id / $query / $dark', (
        tester,
      ) async {
        tester.view.physicalSize = const Size(320, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final guide = guides.firstWhere((guide) => guide.id == id);
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData(
              useMaterial3: true,
              brightness: dark ? Brightness.dark : Brightness.light,
            ),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: const TextScaler.linear(2.25)),
              child: child!,
            ),
            home: GuidePage(guide: guide),
          ),
        );
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(
          find.byType(TextField),
          200,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.enterText(find.byType(TextField), query);
        await tester.pumpAndSettle();
        final enlarge = find.text('$title · увеличить');
        await tester.scrollUntilVisible(
          enlarge,
          200,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();
        expect(find.byType(GuideIllustrationCard), findsOneWidget);
        expect(enlarge.hitTestable(), findsOneWidget);
        await tester.tap(enlarge);
        await tester.pumpAndSettle();
        expect(find.byType(InteractiveViewer), findsOneWidget);
        expect(find.text(title), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.tap(find.byType(BackButton));
        await tester.pumpAndSettle();
        expect(find.byType(GuideIllustrationCard), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }
}
