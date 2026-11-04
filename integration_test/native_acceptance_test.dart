import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:kip_helper/features/manuals/pdf_manual_page.dart';
import 'package:kip_helper/features/notes/guide_notes_page.dart';
import 'package:kip_helper/services/desktop_close_guard.dart';
import 'package:kip_helper/services/guide_notes.dart';
import 'package:kip_helper/services/manual_library.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';

// A complete, self-contained two-page PDF with selectable Helvetica text.
List<int> _pdfFixture({bool scan = false}) {
  final objects = <String>[
    '<< /Type /Catalog /Pages 2 0 R >>',
    '<< /Type /Pages /Kids [3 0 R 4 0 R] /Count 2 >>',
    '<< /Type /Page /Parent 2 0 R /MediaBox [0 0 300 300] /Resources << /Font << /F1 5 0 R >> >> /Contents 6 0 R >>',
    '<< /Type /Page /Parent 2 0 R /MediaBox [0 0 300 300] /Resources << /Font << /F1 5 0 R >> >> /Contents 7 0 R >>',
    '<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>',
    _stream(
      scan
          ? '0 0 0 rg 30 100 100 100 re f'
          : 'BT /F1 20 Tf 30 220 Td (First page) Tj ET',
    ),
    _stream(
      scan
          ? '0 0 0 rg 50 100 100 100 re f'
          : 'BT /F1 20 Tf 30 220 Td (Acceptance needle) Tj ET',
    ),
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

Future<void> _removeNoteFixture(String guideId) async {
  if (!guideId.startsWith('native-')) throw StateError('Not a QA note');
  await (await SharedPreferences.getInstance()).remove(
    SharedPreferencesGuideNotesStore.key(guideId),
  );
  if (!Platform.isWindows) return;
  final support = await getApplicationSupportDirectory();
  final name = sha256.convert(utf8.encode(guideId));
  for (final suffix in ['', '.bak', '.tmp']) {
    final file = File('${support.path}/notes/$name.json$suffix');
    if (await file.exists()) await file.delete();
  }
}

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

  testWidgets('native PDF copy, render, navigation, search and notes persistence', (
    tester,
  ) async {
    // A unique directory and key ensure existing user data is never touched.
    final runId = DateTime.now().microsecondsSinceEpoch.toString();
    final root = Directory(
      '${(await getApplicationSupportDirectory()).path}/acceptance-$runId',
    );
    final guideId = 'native-acceptance-$runId';
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

      final captureKey = GlobalKey();
      await tester.pumpWidget(
        MaterialApp(
          home: RepaintBoundary(
            key: captureKey,
            child: PdfManualPage(manual: reopened),
          ),
        ),
      );
      await _waitFor(
        tester,
        () => find.byType(PdfViewer).evaluate().isNotEmpty,
        'PDF viewer creation',
      );
      final viewer = tester.widget<PdfViewer>(find.byType(PdfViewer));
      final controller = viewer.controller!;
      await _waitFor(tester, () => controller.isReady, 'PDF engine readiness');
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
          if (pixels[i] < 180 && pixels[i + 1] < 180 && pixels[i + 2] < 180) {
            darkPixels++;
          }
        }
        expect(
          darkPixels,
          greaterThan(20),
          reason: 'PDF text must produce visible dark pixels',
        );
      } finally {
        image?.dispose();
      }

      final pageInput = find.byKey(const ValueKey('manual-page'));
      await tester.enterText(pageInput, '2');
      await tester.tap(find.byTooltip('Перейти к странице'));
      await _waitFor(
        tester,
        () => controller.pageNumber == 2,
        'navigation to page 2',
      );
      await _waitFor(
        tester,
        () => find.text('2 / 2').evaluate().isNotEmpty,
        'page 2 label',
      );

      final searchInput = find.byKey(const ValueKey('manual-search'));
      await tester.enterText(searchInput, 'Acceptance needle');
      await tester.tap(find.byTooltip('Найти'));
      await _waitFor(
        tester,
        () => find.text('Найдено: 1').evaluate().isNotEmpty,
        'text search result',
      );
      expect(tester.takeException(), isNull);
      // Capture the visible Flutter view separately from the PDFium raster test.
      await tester.pump(const Duration(seconds: 1));
      final boundary =
          captureKey.currentContext!.findRenderObject()!
              as RenderRepaintBoundary;
      final capture = await boundary.toImage(pixelRatio: 1);
      try {
        final png = await capture.toByteData(format: ui.ImageByteFormat.png);
        expect(png, isNotNull);
        final artifacts = Directory(
          '${(await getApplicationSupportDirectory()).path}/kip-acceptance-artifacts',
        );
        await artifacts.create(recursive: true);
        final screenshot = File('${artifacts.path}/pdf-view-$runId.png');
        await screenshot.writeAsBytes(
          png!.buffer.asUint8List(png.offsetInBytes, png.lengthInBytes),
          flush: true,
        );
        debugPrint('Acceptance visible-view screenshot: ${screenshot.path}');
      } finally {
        capture.dispose();
      }

      // An actual PDF with painted shapes but no text exercises the scan state.
      final scanSource = File('${root.path}/scan.pdf');
      await scanSource.writeAsBytes(_pdfFixture(scan: true));
      final scan = await ManualLibrary(
        directory: directory,
      ).importFile(scanSource, title: 'Scan');
      await tester.pumpWidget(MaterialApp(home: PdfManualPage(manual: scan)));
      await _waitFor(
        tester,
        () => find
            .text(
              'Текстовый слой не найден: возможно, это скан. Поиск недоступен.',
            )
            .evaluate()
            .isNotEmpty,
        'scan text-layer state',
      );
      expect(tester.takeException(), isNull);

      // The library accepts the PDF header; the native engine must reject its
      // damaged contents and expose a return path.
      final brokenSource = File('${root.path}/broken.pdf');
      await brokenSource.writeAsString('%PDF-1.4\ninvalid');
      final broken = await ManualLibrary(
        directory: directory,
      ).importFile(brokenSource, title: 'Broken');
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => PdfManualPage(manual: broken),
                  ),
                ),
                child: const Text('Open broken PDF'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open broken PDF'));
      await _waitFor(
        tester,
        () => find
            .text(
              'Не удалось открыть PDF. Файл может быть повреждён или защищён паролем.',
            )
            .evaluate()
            .isNotEmpty,
        'corrupt PDF error',
      );
      // Repair the same stored file, then verify the real controller reloads it.
      await File(broken.path).writeAsBytes(_pdfFixture(), flush: true);
      await tester.tap(find.text('Повторить'));
      await tester.pump();
      await _waitFor(
        tester,
        () =>
            find.byType(PdfViewer).evaluate().isNotEmpty &&
            tester
                .widget<PdfViewer>(find.byType(PdfViewer))
                .controller!
                .isReady,
        'repaired PDF reload',
      );
      final repairedController = tester
          .widget<PdfViewer>(find.byType(PdfViewer))
          .controller!;
      expect(repairedController.pageCount, 2);
      await _waitFor(
        tester,
        () => find.text('1 / 2').evaluate().isNotEmpty,
        'repaired PDF first page',
      );
      await tester.pageBack();
      await _waitFor(
        tester,
        () => find.text('Open broken PDF').evaluate().isNotEmpty,
        'return from repaired PDF',
      );
      await tester.pumpWidget(const SizedBox.shrink());
    } finally {
      await _removeNoteFixture(guideId);
      if (await root.exists()) await root.delete(recursive: true);
    }
  });

  testWidgets(
    'Windows close cancellation retains dirty note and normal save persists it',
    (tester) async {
      if (!Platform.isWindows) return;
      await DesktopCloseGuard.instance.initialize();
      final guideId = 'native-close-${DateTime.now().microsecondsSinceEpoch}';
      try {
        await tester.pumpWidget(
          MaterialApp(
            home: GuideNotesPage(guideId: guideId, guideTitle: 'Acceptance'),
          ),
        );
        final editor = find.byType(TextField);
        await _waitFor(
          tester,
          () =>
              editor.evaluate().isNotEmpty &&
              tester.widget<TextField>(editor).enabled == true,
          'note editor',
        );
        await tester.enterText(editor, 'Несохранённая проверочная заметка');
        await _waitFor(
          tester,
          () => find.text('Есть несохранённые изменения').evaluate().isNotEmpty,
          'dirty note status',
        );
        await windowManager.close();
        await _waitFor(
          tester,
          () => find.text('Продолжить редактирование').evaluate().isNotEmpty,
          'native close confirmation',
        );
        await tester.tap(find.text('Продолжить редактирование'));
        await _waitFor(
          tester,
          () => find.text('Продолжить редактирование').evaluate().isEmpty,
          'cancel close',
        );
        expect(await windowManager.isVisible(), isTrue);
        expect(
          tester.widget<TextField>(editor).controller!.text,
          'Несохранённая проверочная заметка',
        );
        await tester.tap(find.text('Сохранить'));
        await _waitFor(
          tester,
          () => find.text('Сохранено').evaluate().isNotEmpty,
          'note save',
        );
        expect(
          await SharedPreferencesGuideNotesStore().read(guideId),
          'Несохранённая проверочная заметка',
        );
        await tester.pumpWidget(const SizedBox.shrink());
      } finally {
        await _removeNoteFixture(guideId);
      }
    },
  );
}
