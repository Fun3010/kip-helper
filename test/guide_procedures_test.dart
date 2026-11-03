import 'package:flutter_test/flutter_test.dart';
import 'package:kip_helper/data/guide_procedures.dart';
import 'package:kip_helper/data/guides.dart';
import 'package:kip_helper/models/guide.dart';

void main() {
  test(
    'Guide lookup excludes unsupported models and preserves source scope',
    () {
      expect(proceduresForGuide('missing'), isEmpty);
      expect(proceduresForGuide('remtek'), isEmpty);
      expect(proceduresForGuide('sokrat'), hasLength(2));
      expect(proceduresForGuide('su1s'), hasLength(2));
      final sipart = proceduresForGuide('sipart').single;
      expect(sipart.variants.map((variant) => variant.id), [
        'linear',
        'rotary',
      ]);
      expect(sipart.variants.first.scope, contains('5.6'));
      expect(sipart.variants.last.scope, contains('5.7'));
      expect(proceduresForGuide('sokrat').first.scope, contains('03.01'));
    },
  );

  test(
    'Every actionable step retains verified resolvable catalogue evidence',
    () {
      final ids = <String>{};
      for (final guideId in ['sokrat', 'su1s', 'sipart']) {
        final guide = guides.singleWhere((item) => item.id == guideId);
        final verified = guide.sections
            .expand((section) => section.evidenceByParagraph.values)
            .expand((items) => items)
            .where((item) => item.state == GuideEvidenceState.verified);
        for (final procedure in proceduresForGuide(guideId)) {
          expect(ids.add(procedure.id), isTrue);
          expect(procedure.guideId, guideId);
          expect(procedure.prerequisites, isNotEmpty);
          expect(procedure.variants, isNotEmpty);
          for (final variant in procedure.variants) {
            expect(variant.scope, isNotEmpty);
            expect(variant.steps, isNotEmpty);
            for (final step in variant.steps) {
              expect(step.action, isNotEmpty);
              expect(
                guide.sections.any(
                  (section) => section.paragraphs.contains(step.action),
                ),
                isTrue,
                reason: 'Actions must retain an existing reviewed paragraph.',
              );
              expect(step.expectedResult, isNotEmpty);
              expect(step.evidence, isNotEmpty);
              for (final evidence in step.evidence) {
                expect(evidence.state, GuideEvidenceState.verified);
                expect(
                  verified.any(
                    (item) =>
                        item.sourceKey == evidence.sourceKey &&
                        item.locator == evidence.locator,
                  ),
                  isTrue,
                  reason: '${procedure.id}: ${evidence.locator}',
                );
                final source = procedure.sourceByKey(evidence.sourceKey);
                expect(source, isNotNull);
                expect(source!.url ?? source.document, isNotEmpty);
              }
            }
          }
        }
      }
    },
  );
}
