import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:kip_helper/features/manuals/pdf_manual_page.dart';
import 'package:kip_helper/services/guide_notes.dart';
import 'package:kip_helper/services/manual_library.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:shared_preferences/shared_preferences.dart';

// A complete, self-contained two-page PDF with selectable Helvetica text.
List<int> _pdfFixture() {
  final objects = <String>[
    '<< /Type /Catalog /Pages 2 0 R >>',
    '<< /Type /Pages /Kids [3 0 R 4 0 R] /Count 2 >>',
    '<< /Type /Page /Parent 2 0 R /MediaBox [0 0 300 300] /Resources << /Font << /F1 5 0 R >> >> /Contents 6 0 R >>',
    '<< /Type /Page /Parent 2 0 R /MediaBox [0 0 300 300] /Resources << /Font << /F1 5 0 R >> >> /Contents 7 0 R >>',
    '<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>',
    _stream('BT /F1 20 Tf 30 220 Td (First page) Tj ET'),
    _stream('BT /F1 20 Tf 30 220 Td (Acceptance needle) Tj ET'),
  ];
  var data = '%PDF-1.4\n';
  final offsets = <int>[];
  for (var i = 0; i < objects.length; i++) {
    offsets.add(ascii.encode(data).length);
    data += '${i + 1} 0 obj\n${objects[i]}\nendobj\n';
  }
  final xref = ascii.encode(data).length;
  data += 'xref\n0 ${objects.length + 1}\n0000000000 65535 f \n';
  for (final offset in offsets) {
    data += '${offset.toString().padLeft(10, '0')} 00000 n \n';
  }
  data +=
      'trailer\n<< /Size ${objects.length + 1} /Root 1 0 R >>\nstartxref\n$xref\n%%EOF\n';
  return ascii.encode(data);
}

String _stream(String data) =>
    '<< /Length ${ascii.encode(data).length} >>\nstream\n$data\nendstream';

Future<void> _waitFor(
  WidgetTester tester,
  bool Function() predicate,
  String description,
) async {
  for (var i = 0; i < 120; i++) {
    if (predicate()) return;
    await tester.pump(const Duration(milliseconds: 250));
  }
  fail('Timed out waiting for $description');
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'native PDF copy, render, navigation, search and notes persistence',
    (tester) async {
      // A unique directory and key ensure existing user data is never touched.
      final runId = DateTime.now().microsecondsSinceEpoch.toString();
      final root = Directory(
        '${(await getApplicationSupportDirectory()).path}/acceptance-$runId',
      );
      final guideId = 'native-acceptance-$runId';
      final notesKey = SharedPreferencesGuideNotesStore.key(guideId);
      try {
        await root.create(recursive: true);
        final source = File('${root.path}/source.pdf');
        await source.writeAsBytes(_pdfFixture(), flush: true);
        final directory = Directory('${root.path}/library');
        final imported = await ManualLibrary(
          directory: directory,
        ).importFile(source, title: 'Acceptance PDF');
        await source.delete();
        final reopened = (await ManualLibrary(
          directory: directory,
        ).list()).single;
        expect(reopened.id, imported.id);
        expect(reopened.missing, isFalse);
        expect(await File(reopened.path).exists(), isTrue);

        final store = SharedPreferencesGuideNotesStore();
        expect(await store.write(guideId, 'Заметка acceptance'), isTrue);
        expect(
          await SharedPreferencesGuideNotesStore().read(guideId),
          'Заметка acceptance',
        );

        await tester.pumpWidget(
          MaterialApp(home: PdfManualPage(manual: reopened)),
        );
        final viewer = tester.widget<PdfViewer>(find.byType(PdfViewer));
        final controller = viewer.controller!;
        await _waitFor(
          tester,
          () => controller.isReady,
          'PDF engine readiness',
        );
        expect(controller.pageCount, 2);
        await _waitFor(
          tester,
          () => find.text('1 / 2').evaluate().isNotEmpty,
          'first page',
        );

        // Render actual decoded page pixels through PDFium. This catches blank or
        // failed rendering even if the viewer widget itself was constructed.
        final image = await controller.pages[1].render();
        expect(image, isNotNull);
        try {
          expect(image!.width, greaterThan(0));
          expect(image.height, greaterThan(0));
          final pixels = image.pixels;
          var darkPixels = 0;
          for (var i = 0; i + 3 < pixels.length; i += 4) {
            if (pixels[i] < 180 && pixels[i + 1] < 180 && pixels[i + 2] < 180)
              darkPixels++;
          }
          expect(
            darkPixels,
            greaterThan(20),
            reason: 'PDF text must produce visible dark pixels',
          );
        } finally {
          image?.dispose();
        }

        final pageInput = find.byWidgetPredicate(
          (w) =>
              w is TextField &&
              (w.decoration?.labelText?.startsWith('Стр. /') ?? false),
        );
        await tester.enterText(pageInput, '2');
        await tester.tap(find.byTooltip('Перейти к странице'));
        await _waitFor(
          tester,
          () => controller.pageNumber == 2,
          'navigation to page 2',
        );
        expect(find.text('2 / 2'), findsOneWidget);

        final searchInput = find.byWidgetPredicate(
          (w) => w is TextField && w.decoration?.labelText == 'Поиск в PDF',
        );
        await tester.enterText(searchInput, 'Acceptance needle');
        await tester.tap(find.byTooltip('Найти'));
        await _waitFor(
          tester,
          () => find.text('Найдено: 1').evaluate().isNotEmpty,
          'text search result',
        );
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      } finally {
        await (await SharedPreferences.getInstance()).remove(notesKey);
        if (await root.exists()) await root.delete(recursive: true);
      }
    },
  );
}
