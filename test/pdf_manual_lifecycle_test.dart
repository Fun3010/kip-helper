import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kip_helper/features/manuals/pdf_manual_page.dart';
import 'package:kip_helper/models/local_manual.dart';

void main() {
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
