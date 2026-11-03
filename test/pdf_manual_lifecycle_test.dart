import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kip_helper/features/manuals/pdf_manual_page.dart';
import 'package:kip_helper/models/local_manual.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:kip_helper/app.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets(
    'PDF labels stay visible in product theme with large text and keyboard',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      tester.view.physicalSize = const Size(320, 844);
      tester.view.devicePixelRatio = 1;
      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetViewInsets);
      const manual = LocalManual(
        id: 'fixture',
        title: 'PDF',
        size: 0,
        path: 'unopened.pdf',
      );
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(
            size: Size(320, 844),
            textScaler: TextScaler.linear(2.25),
            viewInsets: EdgeInsets.only(bottom: 300),
          ),
          child: const KipHelperApp(),
        ),
      );
      await tester.pumpAndSettle();
      Navigator.of(tester.element(find.byType(HomePage))).push(
        MaterialPageRoute<void>(
          builder: (_) => const PdfManualPage(manual: manual),
        ),
      );
      await tester.pumpAndSettle();
      final search = find.byKey(const ValueKey('manual-search'));
      final page = find.byKey(const ValueKey('manual-page'));
      final fieldContext = tester.element(search);
      expect(MediaQuery.textScalerOf(fieldContext).scale(10), 22.5);
      expect(
        MediaQuery.viewInsetsOf(
          tester.element(find.byType(Scaffold).last),
        ).bottom,
        300,
      );
      expect(
        Theme.of(fieldContext).inputDecorationTheme.contentPadding,
        const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      );
      final viewport = find
          .ancestor(of: search, matching: find.byType(SingleChildScrollView))
          .first;
      final bounds = tester.getRect(viewport);
      void expectVisibleLabel(String label, Finder field) {
        final text = find.text(label);
        expect(text, findsOneWidget);
        final rect = tester.getRect(text);
        final fieldRect = tester.getRect(field);
        expect(
          rect.top,
          greaterThanOrEqualTo(bounds.top),
          reason: '$label is clipped at the toolbar top',
        );
        expect(
          rect.bottom,
          lessThanOrEqualTo(bounds.bottom),
          reason: '$label is clipped at the toolbar bottom',
        );
        expect(rect.left, greaterThanOrEqualTo(bounds.left));
        expect(
          rect.right,
          lessThanOrEqualTo(fieldRect.right),
          reason: '$label is clipped by its field',
        );
        expect(rect.width, greaterThan(10));
        expect(
          (tester.renderObject(text) as RenderParagraph).didExceedMaxLines,
          isFalse,
        );
      }

      expectVisibleLabel('Стр.', page);
      await tester.tap(search);
      await tester.pumpAndSettle();
      expectVisibleLabel('Поиск', search);
      await tester.ensureVisible(page);
      await tester.tap(page);
      await tester.pumpAndSettle();
      expectVisibleLabel('Стр.', page);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('PDF error controls remain reachable at 320px and 225%', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    const manual = LocalManual(
      id: 'fixture',
      title: 'PDF',
      size: 0,
      path: 'unopened.pdf',
    );
    final navigator = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigator,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(2.25)),
          child: child!,
        ),
        home: const PdfManualPage(manual: manual),
      ),
    );
    expect(find.text('Поиск'), findsOneWidget);
    expect(find.text('Стр.'), findsOneWidget);
    final viewer = tester.widget<PdfViewer>(find.byType(PdfViewer));
    final banner = viewer.params.errorBannerBuilder!;
    navigator.currentState!.push(
      PageRouteBuilder<void>(
        pageBuilder: (context, _, _) => Material(
          child: Center(
            child: SizedBox(
              width: 320,
              height: 286.5,
              child: banner(context, Exception(), null, viewer.documentRef),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.scrollUntilVisible(
      find.text('Повторить'),
      100,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('Повторить').hitTestable(), findsOneWidget);
    await tester.tap(find.text('Повторить').hitTestable());
    await tester.pump();
    await tester.scrollUntilVisible(
      find.text('Назад'),
      100,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('Назад').hitTestable(), findsOneWidget);
    await tester.tap(find.text('Назад').hitTestable());
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
  testWidgets('PDF page builds and disposes before a document is ready', (
    tester,
  ) async {
    const manual = LocalManual(
      id: 'fixture',
      title: 'PDF',
      size: 0,
      path: 'unopened.pdf',
    );
    await tester.pumpWidget(
      const MaterialApp(home: PdfManualPage(manual: manual)),
    );
    expect(tester.takeException(), isNull);
    expect(
      tester
          .widget<IconButton>(
            find.byWidgetPredicate(
              (widget) => widget is IconButton && widget.tooltip == 'Найти',
            ),
          )
          .onPressed,
      isNull,
    );
    await tester.pumpWidget(const SizedBox());
    expect(tester.takeException(), isNull);
  });
}
