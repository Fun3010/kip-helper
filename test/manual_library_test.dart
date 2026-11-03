import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:kip_helper/features/manuals/pdf_manual_page.dart';
import 'package:kip_helper/services/manual_library.dart';

void main() {
  late Directory root;
  late ManualLibrary store;
  late File source;
  setUp(() async {
    root = await Directory.systemTemp.createTemp('manual-test');
    source = File('${root.path}/source.pdf');
    await source.writeAsBytes('%PDF-1.4\nfixture'.codeUnits);
    store = ManualLibrary(directory: Directory('${root.path}/store'));
  });
  tearDown(() async => root.delete(recursive: true));
  test('imports a PDF copy and persists its user association', () async {
    final item = await store.importFile(
      source,
      title: 'Паспорт',
      guideId: 'g',
      guideTitle: 'Прибор',
    );
    await source.delete();
    final reloaded = await ManualLibrary(
      directory: Directory('${root.path}/store'),
    ).list();
    expect(reloaded.single.title, 'Паспорт');
    expect(reloaded.single.guideId, 'g');
    expect(reloaded.single.guideTitle, 'Прибор');
    expect(reloaded.single.size, greaterThan(0));
    expect(await File(item.path).exists(), isTrue);
  });
  test(
    'rejects identical content and non PDF without changing originals',
    () async {
      await store.importFile(source, title: 'Первый');
      await expectLater(
        store.importFile(source, title: 'Копия'),
        throwsA(isA<ManualLibraryException>()),
      );
      final other = File('${root.path}/other.pdf');
      await other.writeAsString('not pdf');
      await expectLater(
        store.importFile(other, title: 'Ошибка'),
        throwsA(isA<ManualLibraryException>()),
      );
      expect(await other.readAsString(), 'not pdf');
      expect((await store.list()).length, 1);
    },
  );
  test('missing copies remain visible and can be removed', () async {
    final item = await store.importFile(source, title: 'Документ');
    await File(item.path).delete();
    expect((await store.list()).single.missing, isTrue);
    await store.remove(item);
    expect(await store.list(), isEmpty);
    expect(await source.exists(), isTrue);
  });
  test('corrupt metadata reports error without deleting files', () async {
    final item = await store.importFile(source, title: 'Документ');
    await File('${root.path}/store/index.json').writeAsString('{broken');
    await expectLater(store.list(), throwsA(isA<ManualLibraryException>()));
    expect(await File(item.path).exists(), isTrue);
  });
  test('page numbers are one based and bounded', () {
    expect(validManualPage('1', 4), 1);
    expect(validManualPage('4', 4), 4);
    expect(validManualPage('0', 4), isNull);
    expect(validManualPage('5', 4), isNull);
    expect(validManualPage('abc', 4), isNull);
  });
}
