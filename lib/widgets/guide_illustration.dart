import 'package:flutter/material.dart';
import '../models/guide.dart';

class GuideIllustrationCard extends StatelessWidget {
  const GuideIllustrationCard({super.key, required this.illustration});
  final GuideIllustration illustration;

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 16),
    clipBehavior: Clip.antiAlias,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => _IllustrationViewer(illustration: illustration),
            ),
          ),
          child: Column(
            children: [
              Container(
                color: Colors.white,
                height: 200,
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                child: Image.asset(
                  illustration.asset,
                  fit: BoxFit.contain,
                  semanticLabel: illustration.title,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    const Icon(Icons.zoom_in),
                    const SizedBox(width: 8),
                    Expanded(child: Text('${illustration.title} · увеличить')),
                  ],
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SelectableText(illustration.caption),
              const SizedBox(height: 8),
              Text(
                illustration.source,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _IllustrationViewer extends StatefulWidget {
  const _IllustrationViewer({required this.illustration});
  final GuideIllustration illustration;

  @override
  State<_IllustrationViewer> createState() => _IllustrationViewerState();
}

class _IllustrationViewerState extends State<_IllustrationViewer> {
  final _transform = TransformationController();
  @override
  void dispose() {
    _transform.dispose();
    super.dispose();
  }

  void _zoom(double factor) {
    final current = _transform.value.getMaxScaleOnAxis();
    final next = (current * factor).clamp(1.0, 6.0);
    if (next == 1) {
      _transform.value = Matrix4.identity();
      return;
    }
    _transform.value = _transform.value.clone()
      ..scaleByDouble(next / current, next / current, 1, 1);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(widget.illustration.title)),
    body: SafeArea(
      child: Column(
        children: [
          Expanded(
            child: ColoredBox(
              color: Colors.white,
              child: InteractiveViewer(
                transformationController: _transform,
                minScale: 1,
                maxScale: 6,
                child: Center(
                  child: Image.asset(
                    widget.illustration.asset,
                    fit: BoxFit.contain,
                    semanticLabel: widget.illustration.title,
                  ),
                ),
              ),
            ),
          ),
          Wrap(
            alignment: WrapAlignment.center,
            children: [
              IconButton(
                tooltip: 'Уменьшить',
                onPressed: () => _zoom(1 / 1.5),
                icon: const Icon(Icons.zoom_out),
              ),
              IconButton(
                tooltip: 'Увеличить',
                onPressed: () => _zoom(1.5),
                icon: const Icon(Icons.zoom_in),
              ),
              IconButton(
                tooltip: 'Вернуть исходный масштаб',
                onPressed: () => _transform.value = Matrix4.identity(),
                icon: const Icon(Icons.fit_screen),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              'Используйте кнопки масштаба или жесты для увеличения.\n${widget.illustration.source}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    ),
  );
}
