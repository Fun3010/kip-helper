import 'dart:async';
import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kip_helper/features/manuals/manual_library_page.dart';
import 'package:kip_helper/models/local_manual.dart';
import 'package:kip_helper/services/manual_library.dart';

class ObservedLibrary extends ManualLibrary {
  ObservedLibrary(Directory directory) : super(directory: directory);
  final loaded = Completer<void>();
  final refreshed = Completer<void>();
  final imported = Completer<void>();

  @override
  Future<List<LocalManual>> list() async {
    final result = await super.list();
    if (!loaded.isCompleted) {
      loaded.complete();
    } else if (!refreshed.isCompleted) {
      refreshed.complete();
    }
    return result;
  }

  @override
  Future<LocalManual> importFile(
    File source, {
    required String title,
    String? guideId,
    String? guideTitle,
  }) async {
    final result = await super.importFile(
      source,
      title: title,
      guideId: guideId,
      guideTitle: guideTitle,
    );
    imported.complete();
    return result;
  }
}

void main() {
  for (final confirm in [true, false]) {
    testWidgets(
      'PDF title dialog ${confirm ? 'confirms' : 'cancels'} without errors during exit animation',
      (tester) async {
        await tester.runAsync(() async {
          final root = await Directory.systemTemp.createTemp('manual-dialog');
          addTearDown(() => root.delete(recursive: true));
          final source = File('${root.path}/fixture.pdf');
          await source.writeAsString('%PDF-1.4 fixture');
          final library = ObservedLibrary(Directory('${root.path}/library'));
          await tester.pumpWidget(
            MaterialApp(
              home: ManualLibraryPage(
                library: library,
                pickFile: () async => XFile(source.path),
              ),
            ),
          );
          await library.loaded.future;
          await tester.pumpAndSettle();
          await tester.tap(find.text('Добавить PDF'));
          await tester.pumpAndSettle();
          expect(find.text('Название документа'), findsOneWidget);
          await tester.enterText(find.byType(TextField), 'Паспорт');
          await tester.pump();
          await tester.tap(find.text(confirm ? 'Добавить' : 'Отмена'));
          await tester.pump(const Duration(milliseconds: 1));
          expect(tester.takeException(), isNull);
          await tester.pump(const Duration(milliseconds: 100));
          expect(tester.takeException(), isNull);
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          if (confirm) {
            await library.imported.future;
            await library.refreshed.future;
            await tester.pumpAndSettle();
            expect(find.text('Паспорт'), findsOneWidget);
            final entries = await library.list();
            expect(entries.single.title, 'Паспорт');
            expect(await File(entries.single.path).exists(), isTrue);
          } else {
            expect(await library.list(), isEmpty);
          }
        });
      },
    );
  }
}
