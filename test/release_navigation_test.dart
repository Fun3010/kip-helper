import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kip_helper/app.dart';
import 'package:kip_helper/data/guides.dart';
import 'package:kip_helper/features/calculators/rtd_table.dart';
import 'package:kip_helper/features/guides/guide_page.dart';
import 'package:kip_helper/features/manuals/manual_library_page.dart';
import 'package:kip_helper/features/notes/guide_notes_page.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('Full PDF library is reachable from the home page', (
    tester,
  ) async {
    await tester.pumpWidget(const KipHelperApp());
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Мои PDF'));
    await tester.pumpAndSettle();
    expect(find.byType(ManualLibraryPage), findsOneWidget);
  });

  testWidgets('RTD table is reachable from calculations', (tester) async {
    await tester.pumpWidget(const KipHelperApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Расчёты'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Таблица НСХ'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Таблица НСХ'));
    await tester.pumpAndSettle();
    expect(find.byType(RtdTable), findsOneWidget);
  });

  for (final entry in ['Личные заметки', 'PDF этого прибора']) {
    testWidgets('Guide action opens the correct page: $entry', (tester) async {
      final guide = guides.firstWhere((item) => item.id == 'su1s');
      await tester.pumpWidget(MaterialApp(home: GuidePage(guide: guide)));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Дополнительные действия'));
      await tester.pumpAndSettle();
      await tester.tap(find.text(entry));
      await tester.pumpAndSettle();
      if (entry == 'Личные заметки') {
        expect(find.byType(GuideNotesPage), findsOneWidget);
      } else {
        expect(find.byType(ManualLibraryPage), findsOneWidget);
        expect(
          tester
              .widget<ManualLibraryPage>(find.byType(ManualLibraryPage))
              .guideId,
          guide.id,
        );
      }
    });
  }
}
