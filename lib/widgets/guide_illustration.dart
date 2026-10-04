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

class _IllustrationViewer extends StatelessWidget {
  const _IllustrationViewer({required this.illustration});
  final GuideIllustration illustration;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(illustration.title)),
    body: SafeArea(
      child: Column(
        children: [
          Expanded(
            child: ColoredBox(
              color: Colors.white,
              child: InteractiveViewer(
                minScale: 1,
                maxScale: 6,
                child: Center(
                  child: Image.asset(
                    illustration.asset,
                    fit: BoxFit.contain,
                    semanticLabel: illustration.title,
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              'Разведите пальцы для увеличения.\n${illustration.source}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    ),
  );
}
