import 'package:flutter_test/flutter_test.dart';
import 'package:kip_helper/data/guides.dart';

void main() {
  test(
    'KOLION 1V-06 distinguishes mixture response and calibration substance',
    () {
      final g = guides.singleWhere((g) => g.id == 'kolion1v06');
      expect(g.matches('колион-1в-06'), isTrue);
      expect(g.scope, contains('ЯРКГ'));
      expect(
        g.sections.expand((s) => s.paragraphs).join(' '),
        contains('смеси'),
      );
      expect(
        g.sections.expand((s) => s.paragraphs).join(' '),
        contains('паспорте'),
      );
      for (final section in g.sections) {
        for (var i = 0; i < section.paragraphs.length; i++) {
          expect(section.evidenceFor(i), isNotEmpty);
          for (final evidence in section.evidenceFor(i)) {
            expect(g.sourceByKey(evidence.sourceKey), isNotNull);
          }
        }
      }
    },
  );
  test('STM-30-50 points to part one and separates other variants', () {
    final g = guides.singleWhere((g) => g.id == 'stm30');
    final section = g.sections.singleWhere(
      (s) => s.title.contains('СТМ-30-50'),
    );
    expect(section.paragraphs.join(' '), contains('часть 1'));
    expect(section.paragraphs.join(' '), contains('часть 2'));
    final evidence = section.evidenceFor(0).single;
    expect(g.sourceByKey(evidence.sourceKey)?.url, contains('ch1.pdf'));
  });
}
