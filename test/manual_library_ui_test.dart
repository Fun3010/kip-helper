import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kip_helper/features/manuals/manual_library_page.dart';
import 'package:kip_helper/services/manual_library.dart';
import 'package:kip_helper/models/local_manual.dart';

class ObservableLibrary extends ManualLibrary {
  ObservableLibrary(Directory directory) : super(directory: directory);
  Completer<void> loaded = Completer<void>();
  @override
  Future<List<LocalManual>> list() async {
    final result = await super.list();
    if (!loaded.isCompleted) loaded.complete();
    return result;
  }
}

void main() {
  testWidgets('existing PDF can be reassigned after confirmation', (
    tester,
  ) async {
    await tester.runAsync(() async {
      final root = await Directory.systemTemp.createTemp('manual-link-ui');
      addTearDown(() => root.delete(recursive: true));
      final source = File('${root.path}/source.pdf');
      await source.writeAsString('%PDF-1.4 fixture');
      final store = ObservableLibrary(Directory('${root.path}/store'));
      final item = await store.importFile(
        source,
        title: 'Паспорт',
        guideId: 'old',
        guideTitle: 'Старый',
      );
      await tester.pumpWidget(
        MaterialApp(
          home: ManualLibraryPage(
            library: store,
            guideId: 'new',
            guideTitle: 'Новый',
          ),
        ),
      );
      await store.loaded.future;
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Связать с этим прибором'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Отмена'));
      await tester.pumpAndSettle();
      expect((await store.list()).single.guideId, 'old');
      await tester.tap(find.byTooltip('Связать с этим прибором'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Связать'));
      await tester.pumpAndSettle();
      final linked = (await store.list()).single;
      expect(linked.guideId, 'new');
      expect(await File(item.path).exists(), isTrue);
    });
  });
  testWidgets(
    'picker cancellation leaves library unchanged at large text scale',
    (tester) async {
      await tester.runAsync(() async {
        final root = await Directory.systemTemp.createTemp('manual-ui');
        addTearDown(() => root.delete(recursive: true));
        tester.view.physicalSize = const Size(320, 800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final store = ObservableLibrary(root);
        await tester.pumpWidget(
          MaterialApp(
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: const TextScaler.linear(2.25)),
              child: child!,
            ),
            home: ManualLibraryPage(library: store, pickFile: () async => null),
          ),
        );
        await store.loaded.future;
        await tester.pumpAndSettle();
        await tester.tap(find.text('Добавить PDF'));
        await tester.pumpAndSettle();
        expect(await store.list(), isEmpty);
        expect(tester.takeException(), isNull);
      });
    },
  );
  testWidgets('removal requires confirmation and preserves original', (
    tester,
  ) async {
    await tester.runAsync(() async {
      final root = await Directory.systemTemp.createTemp('manual-remove-ui');
      addTearDown(() => root.delete(recursive: true));
      final source = File('${root.path}/source.pdf');
      await source.writeAsString('%PDF-1.4 fixture');
      final store = ObservableLibrary(Directory('${root.path}/store'));
      await store.importFile(source, title: 'Руководство');
      await tester.pumpWidget(
        MaterialApp(home: ManualLibraryPage(library: store)),
      );
      await store.loaded.future;
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Удалить'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Отмена'));
      await tester.pumpAndSettle();
      expect((await store.list()).length, 1);
      await tester.tap(find.byTooltip('Удалить'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Удалить').last);
      await store.list();
      await tester.pumpAndSettle();
      expect(await store.list(), isEmpty);
      expect(await source.exists(), isTrue);
    });
  });
}
