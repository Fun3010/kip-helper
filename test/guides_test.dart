import 'package:flutter_test/flutter_test.dart';
import 'package:kip_helper/data/guides.dart';
import 'package:kip_helper/models/guide.dart';
import 'dart:io';

void main() {
  test('Illustrations have actual assets and traceable source pages', () {
    final illustrations = guides.expand((g) => g.illustrations).toList();
    expect(illustrations.length, greaterThanOrEqualTo(4));
    for (final item in illustrations) {
      expect(File(item.asset).existsSync(), isTrue, reason: item.asset);
      expect(item.source, contains('PDF с.'));
      expect(item.caption, isNotEmpty);
    }
    for (final guide in guides.where((g) => g.thumbnailAsset != null)) {
      expect(File(guide.thumbnailAsset!).existsSync(), isTrue);
    }
    expect(guides.where((g) => g.matches('дтр-см')).single.id, 'iva8');
    expect(guides.where((g) => g.matches('xt2')).single.id, 'sokrat');
  });
  test('Catalogue entries are unique, scoped and have usable sources', () {
    expect(guides.map((g) => g.id).toSet().length, guides.length);
    for (final guide in guides) {
      expect(guide.title, isNotEmpty);
      expect(guide.scope, isNotEmpty);
      expect(guide.sections, isNotEmpty);
      expect(guide.sources, isNotEmpty, reason: guide.id);
      expect(
        guide.sections.map((s) => s.title).toSet().length,
        guide.sections.length,
      );
      for (final section in guide.sections) {
        expect(section.paragraphs, isNotEmpty);
      }
      for (final source in guide.sources) {
        expect(source.url != null || source.document != null, isTrue);
        if (source.url != null) {
          final uri = Uri.parse(source.url!);
          expect(uri.scheme, 'https');
          expect(uri.host, isNotEmpty);
        } else {
          expect(source.document, isNotEmpty);
        }
      }
    }
  });
  test('Exemplar guides trace every paragraph to explicit evidence', () {
    const exemplarIds = {'sipart', 'sokrat', 'su1s', 'stm10'};
    final exemplars = guides.where((g) => exemplarIds.contains(g.id)).toList();

    expect(exemplars.length, exemplarIds.length);
    for (final guide in exemplars) {
      final keyedSources = guide.sources.where((source) => source.key != null);
      expect(
        keyedSources.map((source) => source.key).toSet().length,
        guide.sources.length,
        reason: '${guide.id}: every exemplar source needs a unique key',
      );

      for (final section in guide.sections) {
        for (
          var paragraphIndex = 0;
          paragraphIndex < section.paragraphs.length;
          paragraphIndex++
        ) {
          final evidence = section.evidenceFor(paragraphIndex);
          expect(
            evidence,
            isNotEmpty,
            reason:
                '${guide.id} / ${section.title} / paragraph $paragraphIndex',
          );
          for (final item in evidence) {
            expect(item.locator.trim(), isNotEmpty);
            expect(
              guide.sourceByKey(item.sourceKey),
              isNotNull,
              reason: '${guide.id}: missing source key ${item.sourceKey}',
            );
          }
        }
      }
    }

    final sokrat = guides.firstWhere((g) => g.id == 'sokrat');
    final sokratEvidence = sokrat.sections
        .expand((section) => section.evidenceByParagraph.values)
        .expand((items) => items)
        .toList();
    expect(
      sokratEvidence.any(
        (item) =>
            item.state == GuideEvidenceState.verified &&
            item.locator.contains('РЭ с. 58') &&
            item.locator.contains('с. 59'),
      ),
      isTrue,
    );
    expect(
      sokratEvidence.any(
        (item) =>
            item.state == GuideEvidenceState.verified &&
            item.locator.contains('РЭ с. 23') &&
            item.locator.contains('с. 24'),
      ),
      isTrue,
    );

    final su1s = guides.firstWhere((g) => g.id == 'su1s');
    final su1sVerified = su1s.sections
        .expand((section) => section.evidenceByParagraph.values)
        .expand((items) => items)
        .where((item) => item.state == GuideEvidenceState.verified)
        .map((item) => item.locator)
        .join(' ');
    for (final page in ['с. 7', 'с. 13', 'с. 27', 'с. 38']) {
      expect(su1sVerified, contains(page));
    }

    final sipart = guides.firstWhere((g) => g.id == 'sipart');
    final sipartEvidence = sipart.sections
        .expand((section) => section.evidenceByParagraph.values)
        .expand((items) => items)
        .toList();
    expect(
      sipartEvidence.any(
        (item) =>
            item.state == GuideEvidenceState.verified &&
            item.locator.contains('РЭ с. 74'),
      ),
      isTrue,
    );
    expect(
      sipartEvidence.any(
        (item) =>
            item.state == GuideEvidenceState.verified &&
            item.locator.contains('РЭ с. 210') &&
            item.locator.contains('RUN1/RUN2/RUN3'),
      ),
      isTrue,
    );

    final stm10 = guides.firstWhere((g) => g.id == 'stm10');
    final stm10States = stm10.sections
        .expand((section) => section.evidenceByParagraph.values)
        .expand((items) => items)
        .map((item) => item.state)
        .toSet();
    expect(stm10States, contains(GuideEvidenceState.verified));
    expect(stm10States, contains(GuideEvidenceState.needsVisualCheck));
    expect(stm10States, contains(GuideEvidenceState.workingChecklist));
    expect(
      stm10.sections
          .expand((section) => section.evidenceByParagraph.values)
          .expand((items) => items)
          .any(
            (item) =>
                item.state == GuideEvidenceState.verified &&
                item.locator.contains('РЭ с. 4'),
          ),
      isTrue,
    );
  });

  test('Evidence participates in catalogue search', () {
    expect(
      guides.where((g) => g.matches('визуальной сверки')).single.id,
      'stm10',
    );
    expect(guides.where((g) => g.matches('рэ с. 51–52')).single.id, 'sokrat');
  });

  test('Search covers model scopes, codes and empty results', () {
    expect(guides.where((g) => g.matches('ргау.407834.006')).single.id, 'su1s');
    expect(guides.where((g) => g.matches('a01')).single.id, 'sokrat');
    expect(guides.where((g) => g.matches('sipart')).single.id, 'sipart');
    expect(guides.where((g) => g.matches('unknown-model-xyz')), isEmpty);
    expect(guides.where((g) => g.matches('')).length, guides.length);
  });
}
