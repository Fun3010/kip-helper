import 'dart:async';
import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kip_helper/app.dart';
import 'package:kip_helper/features/manuals/manual_library_page.dart';
import 'package:kip_helper/models/local_manual.dart';
import 'package:kip_helper/services/manual_library.dart';
import 'package:kip_helper/services/text_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  for (final dark in [false, true]) {
    for (final confirm in [true, false]) {
      testWidgets(
        'product theme title remains editable at 320px/225% with keyboard, dark=$dark confirm=$confirm',
        (tester) async {
          tester.view.physicalSize = const Size(320, 712);
          tester.view.devicePixelRatio = 1;
          tester.platformDispatcher.textScaleFactorTestValue = 1.5;
          tester.platformDispatcher.platformBrightnessTestValue = dark
              ? Brightness.dark
              : Brightness.light;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          addTearDown(tester.view.resetViewInsets);
          addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
          addTearDown(
            tester.platformDispatcher.clearPlatformBrightnessTestValue,
          );
          SharedPreferences.setMockInitialValues({
            TextSettings.storageKey: 1.5,
          });
          await tester.runAsync(() async {
            final root = await Directory.systemTemp.createTemp(
              'manual-keyboard',
            );
            addTearDown(() => root.delete(recursive: true));
            final source = File('${root.path}/fixture.pdf');
            await source.writeAsString('%PDF-1.4 fixture');
            final library = ObservedLibrary(Directory('${root.path}/library'));
            await tester.pumpWidget(const KipHelperApp());
            await tester.pumpAndSettle();
            Navigator.of(tester.element(find.byType(HomePage))).push(
              MaterialPageRoute<void>(
                builder: (_) => ManualLibraryPage(
                  library: library,
                  pickFile: () async => XFile(source.path),
                ),
              ),
            );
            await tester.pumpAndSettle();
            await library.loaded.future;
            await tester.pumpAndSettle();
            await tester.tap(find.text('Добавить PDF').hitTestable());
            await tester.pumpAndSettle();
            final field = find.descendant(
              of: find.byType(AlertDialog),
              matching: find.byType(TextField),
            );
            expect(
              MediaQuery.textScalerOf(tester.element(field)).scale(16),
              36,
            );
            await tester.tap(field.hitTestable());
            await tester.pump();
            tester.view.viewInsets = const FakeViewPadding(bottom: 300);
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);

            // Reaching and editing the actual field must remain possible after
            // the keyboard reduces the dialog, not merely finding its widget.
            await tester.ensureVisible(field);
            await tester.pumpAndSettle();
            expect(field.hitTestable(), findsOneWidget);
            final editable = find.descendant(
              of: field,
              matching: find.byType(EditableText),
            );
            expect(tester.getSize(editable).height, greaterThan(30));
            expect(tester.getRect(editable).bottom, lessThanOrEqualTo(412));
            await tester.tap(field.hitTestable());
            await tester.enterText(field, 'Исправленный паспорт');
            await tester.pump();
            expect(
              tester.widget<TextField>(field).controller!.text,
              'Исправленный паспорт',
            );
            for (final label in ['Добавить', 'Отмена']) {
              expect(find.text(label).hitTestable(), findsOneWidget);
              expect(
                tester.getRect(find.text(label)).bottom,
                lessThanOrEqualTo(412),
              );
            }
            await tester.tap(
              find.text(confirm ? 'Добавить' : 'Отмена').hitTestable(),
            );
            await tester.pump(const Duration(milliseconds: 1));
            expect(tester.takeException(), isNull);
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
            if (confirm) {
              await library.imported.future;
              await library.refreshed.future;
              expect(
                (await library.list()).single.title,
                'Исправленный паспорт',
              );
            } else {
              expect(await library.list(), isEmpty);
            }
          });
        },
      );
    }
  }

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
