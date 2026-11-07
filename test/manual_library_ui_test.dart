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
  final associated = Completer<void>();
  @override
  Future<List<LocalManual>> list() async {
    final result = await super.list();
    if (!loaded.isCompleted) loaded.complete();
    return result;
  }

  @override
  Future<void> associate(
    LocalManual item,
    String guideId,
    String guideTitle,
  ) async {
    await super.associate(item, guideId, guideTitle);
    associated.complete();
  }
}

// Only storage I/O is replaced; loading, recovery, scrolling and dialogs use
// the real page. A retry that stays in the error state cannot pass these tests.
class MemoryLibrary extends ManualLibrary {
  MemoryLibrary(this.items, {this.failNextLoad = false});
  final List<LocalManual> items;
  bool failNextLoad;

  @override
  Future<List<LocalManual>> list() async {
    if (failNextLoad) {
      failNextLoad = false;
      throw const FileSystemException('private storage detail', 'private-path');
    }
    return List.of(items);
  }
}

LocalManual manualFixture(int number) => LocalManual(
  id: number.toRadixString(16).padLeft(64, '0'),
  title: 'Руководство $number по подключению прибора',
  size: 1048576,
  path: 'unused-$number.pdf',
);

Widget libraryAtLargeText(ManualLibrary library, {required bool dark}) =>
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
      home: ManualLibraryPage(library: library, pickFile: () async => null),
    );

void main() {
  testWidgets('A guide library puts its own manuals before unrelated files', (
    tester,
  ) async {
    final other = manualFixture(1);
    final linked = LocalManual(
      id: '2'.padLeft(64, '0'),
      title: 'РЭ позиционера',
      size: 50,
      path: 'unused.pdf',
      guideId: 'sipart',
      guideTitle: 'SIPART PS2',
    );
    await tester.pumpWidget(
      MaterialApp(
        home: ManualLibraryPage(
          guideId: 'sipart',
          guideTitle: 'SIPART PS2',
          library: MemoryLibrary([other, linked]),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('PDF этого прибора · 1'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text(linked.title)).dy,
      lessThan(tester.getTopLeft(find.text(other.title)).dy),
    );
  });
  for (final dark in [false, true]) {
    testWidgets('library failure retries into usable list, dark=$dark', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final item = manualFixture(1);
      await tester.pumpWidget(
        libraryAtLargeText(
          MemoryLibrary([item], failNextLoad: true),
          dark: dark,
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Не удалось загрузить библиотеку'),
        findsOneWidget,
      );
      expect(find.textContaining('private'), findsNothing);
      expect(find.text(item.title), findsNothing);
      expect(
        tester
            .widget<FloatingActionButton>(find.byType(FloatingActionButton))
            .onPressed,
        isNull,
      );
      await tester.tap(find.text('Повторить').hitTestable());
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Не удалось загрузить библиотеку'),
        findsNothing,
      );
      expect(find.text(item.title), findsOneWidget);
      expect(
        tester
            .widget<FloatingActionButton>(find.byType(FloatingActionButton))
            .onPressed,
        isNotNull,
      );
      await tester.tap(find.text('Добавить PDF').hitTestable());
      await tester.pumpAndSettle();
      expect(find.text(item.title), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('last PDF delete stays above FAB at 320px/225%, dark=$dark', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final items = List.generate(15, (i) => manualFixture(i + 1));
      await tester.pumpWidget(
        libraryAtLargeText(MemoryLibrary(items), dark: dark),
      );
      await tester.pumpAndSettle();
      final lastTitle = find.text(items.last.title);
      await tester.scrollUntilVisible(
        lastTitle,
        250,
        scrollable: find.byType(Scrollable).first,
        maxScrolls: 60,
      );
      await tester.drag(find.byType(ListView), const Offset(0, -400));
      await tester.pumpAndSettle();
      final lastRow = find.ancestor(
        of: lastTitle,
        matching: find.byType(ListTile),
      );
      final delete = find.descendant(
        of: lastRow,
        matching: find.byTooltip('Удалить'),
      );
      final fab = tester.getRect(find.byType(FloatingActionButton));
      expect(tester.getRect(lastRow).bottom, lessThanOrEqualTo(fab.top));
      expect(delete.hitTestable(), findsOneWidget);
      await tester.tap(delete.hitTestable());
      await tester.pumpAndSettle();
      expect(find.text('Удалить документ?'), findsOneWidget);
      expect(find.textContaining('«${items.last.title}»'), findsOneWidget);
      await tester.tap(find.text('Отмена').hitTestable());
      await tester.pumpAndSettle();
      expect(lastTitle, findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

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
      // Pumping frames does not await the real filesystem transaction.
      await store.associated.future.timeout(const Duration(seconds: 5));
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
