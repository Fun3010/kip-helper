import 'package:flutter/material.dart';

class SheetMapPoint {
  const SheetMapPoint({
    required this.id,
    required this.label,
    required this.position,
  });
  final String id;
  final String label;

  /// Coordinates normalized to the image, not the viewport.
  final Offset position;
}

/// Displays one image and its anchors in a single transformed scene.
class SheetMapView extends StatelessWidget {
  const SheetMapView({
    super.key,
    required this.image,
    required this.imageSize,
    required this.controller,
    required this.points,
    this.onSelect,
    this.onPointTap,
  });
  final Widget image;
  final Size imageSize;
  final TransformationController controller;
  final List<SheetMapPoint> points;
  final ValueChanged<Offset>? onSelect;
  final ValueChanged<String>? onPointTap;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final viewport = Size(constraints.maxWidth, constraints.maxHeight);
      final fitted = applyBoxFit(
        BoxFit.contain,
        imageSize,
        viewport,
      ).destination;
      final imageRect = Alignment.center.inscribe(
        fitted,
        Offset.zero & viewport,
      );
      return ClipRect(
        child: InteractiveViewer(
          key: const ValueKey('sheet-map-view'),
          transformationController: controller,
          minScale: 1,
          maxScale: 8,
          child: SizedBox(
            width: viewport.width,
            height: viewport.height,
            child: Stack(
              children: [
                Positioned.fromRect(rect: imageRect, child: image),
                Positioned.fill(
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTapUp: onSelect == null
                        ? null
                        : (details) {
                            // This handler is inside the transformed scene: localPosition is already in scene coordinates.
                            final p = details.localPosition;
                            if (!imageRect.contains(p)) return;
                            onSelect!(
                              Offset(
                                (p.dx - imageRect.left) / imageRect.width,
                                (p.dy - imageRect.top) / imageRect.height,
                              ),
                            );
                          },
                  ),
                ),
                for (final p in points) ...[
                  Positioned(
                    left: imageRect.left + p.position.dx * imageRect.width - 5,
                    top: imageRect.top + p.position.dy * imageRect.height - 5,
                    child: IgnorePointer(
                      child: Container(
                        key: ValueKey('anchor-${p.id}'),
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: (imageRect.left + p.position.dx * imageRect.width + 6)
                        .clamp(0.0, viewport.width - 90),
                    top: (imageRect.top + p.position.dy * imageRect.height - 18)
                        .clamp(0.0, viewport.height - 36),
                    width: 90,
                    height: 36,
                    child: TextButton(
                      onPressed: onPointTap == null
                          ? null
                          : () => onPointTap!(p.id),
                      child: Text(
                        p.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    },
  );
}
