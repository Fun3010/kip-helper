import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kip_helper/features/manuals/pdf_manual_page.dart';
import 'package:kip_helper/models/local_manual.dart';
import 'package:pdfrx/pdfrx.dart';

void main() {
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
    expect(
      tester
          .widget<TextField>(find.byKey(const ValueKey('manual-search')))
          .decoration!
          .labelText,
      'Поиск',
    );
    expect(
      tester
          .widget<TextField>(find.byKey(const ValueKey('manual-page')))
          .decoration!
          .labelText,
      'Стр.',
    );
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
