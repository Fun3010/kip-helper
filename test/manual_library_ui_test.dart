import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kip_helper/features/manuals/manual_library_page.dart';
import 'package:kip_helper/services/manual_library.dart';

void main() {
  testWidgets(
    'picker cancellation leaves library unchanged at large text scale',
    (tester) async {
      final root = await Directory.systemTemp.createTemp('manual-ui');
      addTearDown(() => root.delete(recursive: true));
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final store = ManualLibrary(directory: root);
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
      await tester.pumpAndSettle();
      await tester.tap(find.text('Добавить PDF'));
      await tester.pumpAndSettle();
      expect(await store.list(), isEmpty);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('removal requires confirmation and preserves original', (
    tester,
  ) async {
    final root = await Directory.systemTemp.createTemp('manual-remove-ui');
    addTearDown(() => root.delete(recursive: true));
    final source = File('${root.path}/source.pdf');
    await source.writeAsString('%PDF-1.4 fixture');
    final store = ManualLibrary(directory: Directory('${root.path}/store'));
    await store.importFile(source, title: 'Руководство');
    await tester.pumpWidget(
      MaterialApp(home: ManualLibraryPage(library: store)),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Удалить'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Отмена'));
    await tester.pumpAndSettle();
    expect((await store.list()).length, 1);
    await tester.tap(find.byTooltip('Удалить'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Удалить').last);
    await tester.pumpAndSettle();
    expect(await store.list(), isEmpty);
    expect(await source.exists(), isTrue);
  });
}
