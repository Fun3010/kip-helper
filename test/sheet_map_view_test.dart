import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kip_helper/features/positions/sheet_map_view.dart';

void main() {
  testWidgets(
    'synthetic sheet ignores margins and maps taps after zoom and pan',
    (tester) async {
      tester.view.physicalSize = const Size(400, 400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final controller = TransformationController();
      addTearDown(controller.dispose);
      Offset? selected;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 300,
                height: 300,
                child: SheetMapView(
                  image: const ColoredBox(color: Colors.amber),
                  imageSize: const Size(1000, 600),
                  controller: controller,
                  points: const [
                    SheetMapPoint(
                      id: 'synthetic',
                      label: 'A',
                      position: Offset(.1, .15),
                    ),
                  ],
                  onSelect: (value) => selected = value,
                ),
              ),
            ),
          ),
        ),
      );
      final view = find.byKey(const ValueKey('sheet-map-view'));
      final origin = tester.getTopLeft(view);
      await tester.tapAt(origin + const Offset(100, 20));
      await tester.pump();
      expect(selected, isNull);
      controller.value = Matrix4.identity()
        ..translateByDouble(-50, -30, 0, 1)
        ..scaleByDouble(2, 2, 1, 1);
      await tester.pump();
      // Image fits into 300 x 180, centred vertically: scene target (100, 130).
      await tester.tapAt(origin + const Offset(150, 230));
      await tester.pump();
      expect(selected!.dx, closeTo(1 / 3, .01));
      expect(selected!.dy, closeTo(70 / 180, .01));
    },
  );
  testWidgets(
    'edge anchor keeps its exact image coordinate after viewport resize',
    (tester) async {
      final controller = TransformationController();
      addTearDown(controller.dispose);
      Widget scene(double width, double height) => MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: width,
              height: height,
              child: SheetMapView(
                image: const ColoredBox(color: Colors.blue),
                imageSize: const Size(1000, 600),
                controller: controller,
                points: const [
                  SheetMapPoint(
                    id: 'edge',
                    label: 'Edge',
                    position: Offset(1, 1),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpWidget(scene(300, 300));
      var origin = tester.getTopLeft(
        find.byKey(const ValueKey('sheet-map-view')),
      );
      var center = tester.getCenter(find.byKey(const ValueKey('anchor-edge')));
      expect(center.dx - origin.dx, closeTo(300, .01));
      expect(center.dy - origin.dy, closeTo(240, .01));
      await tester.pumpWidget(scene(240, 300));
      await tester.pump();
      origin = tester.getTopLeft(find.byKey(const ValueKey('sheet-map-view')));
      center = tester.getCenter(find.byKey(const ValueKey('anchor-edge')));
      expect(center.dx - origin.dx, closeTo(240, .01));
      expect(center.dy - origin.dy, closeTo(222, .01));
    },
  );
}
