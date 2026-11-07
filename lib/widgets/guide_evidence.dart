import 'package:flutter/material.dart';
import '../models/guide.dart';
import '../services/open_source.dart';

/// Keep applicability and procedural warnings in the main text, not here.
class GuideEvidenceCard extends StatelessWidget {
  const GuideEvidenceCard({super.key, required this.evidence, this.source});
  final GuideEvidence evidence;
  final GuideSource? source;

  @override
  Widget build(BuildContext context) {
    final label = switch (evidence.state) {
      GuideEvidenceState.verified => 'Источник',
      GuideEvidenceState.workingChecklist =>
        'Рабочий чек-лист · не процедура РЭ',
      GuideEvidenceState.locatorPending => 'Источник · страницу уточнить',
      GuideEvidenceState.needsVisualCheck => 'Скан · нужна визуальная сверка',
    };
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Material(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        child: ExpansionTile(
          dense: true,
          tilePadding: const EdgeInsets.symmetric(horizontal: 12),
          childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          title: Text(label, style: Theme.of(context).textTheme.labelLarge),
          subtitle: Text(
            evidence.locator,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          children: [
            Text(source?.title ?? evidence.sourceKey),
            if (source?.document case final document?) Text(document),
            if (evidence.note case final note?) ...[
              const SizedBox(height: 8),
              Text(note),
            ],
            if (source?.url case final url?)
              TextButton.icon(
                onPressed: () => openSource(context, url),
                icon: const Icon(Icons.open_in_new, size: 18),
                label: const Text('Открыть документ'),
              ),
          ],
        ),
      ),
    );
  }
}

class GuideFieldEntryCard extends StatelessWidget {
  const GuideFieldEntryCard({super.key, required this.entry});
  final GuideFieldEntry entry;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: colors.primary, width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            entry.code,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: colors.primary,
            ),
          ),
          const SizedBox(height: 4),
          SelectableText(entry.meaning, style: const TextStyle(height: 1.4)),
          if (entry.detail case final detail?) ...[
            const SizedBox(height: 6),
            Text(detail),
          ],
        ],
      ),
    );
  }
}
