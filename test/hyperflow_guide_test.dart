import 'package:flutter_test/flutter_test.dart';
import 'package:kip_helper/data/guides.dart';

void main() {
  test('HyperFlow 3Pm is listed separately from the ultrasonic US', () {
    final guide = guides.singleWhere((g) => g.id == 'hyperflow_3pm');
    expect(guide.matches('гиперфлоу-3пм'), isTrue);
    expect(guide.scope, contains('КРАУ1.456.001-06'));
    expect(guide.sources.single.url, contains('vympel.group'));
    for (final section in guide.sections) {
      for (var i = 0; i < section.paragraphs.length; i++) {
        expect(section.evidenceFor(i), isNotEmpty);
        for (final evidence in section.evidenceFor(i)) {
          expect(guide.sourceByKey(evidence.sourceKey), isNotNull);
        }
      }
    }
  });
  test('HyperFlow US card identifies only the documented variants', () {
    final guide = guides.singleWhere((g) => g.id == 'hyperflow_us');
    expect(guide.matches('гиперфлоу-ус'), isTrue);
    expect(guide.scope, contains('КРАУ1.456.013'));
    expect(guide.scope, contains('«С» и «Т»'));
    expect(guide.scope, contains('«Р»'));
    for (final section in guide.sections) {
      for (var i = 0; i < section.paragraphs.length; i++) {
        expect(section.evidenceFor(i), isNotEmpty);
        for (final evidence in section.evidenceFor(i)) {
          expect(guide.sourceByKey(evidence.sourceKey), isNotNull);
        }
      }
    }
  });
}
