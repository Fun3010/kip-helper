import 'package:flutter_test/flutter_test.dart';
import 'package:kip_helper/data/guides.dart';

void main() {
  test(
    'Requested gas instruments are discoverable with distinct model scopes',
    () {
      final ankat = guides.singleWhere((g) => g.id == 'ankat7664micro04');
      expect(ankat.matches('анкат-7664микро-04'), isTrue);
      expect(ankat.scope, contains('ИБЯЛ.413411.053'));
      expect(ankat.sections.first.paragraphs.first, contains('O₂'));
      expect(ankat.sections.first.paragraphs.first, contains('Ex'));
      final sgg = guides.singleWhere((g) => g.id == 'sgg20n');
      expect(sgg.matches('сгг-20н'), isTrue);
      expect(sgg.scope, contains('ИБЯЛ.413531.009'));
      expect(sgg.scope, contains('20Микро'));
      for (final guide in [ankat, sgg]) {
        for (final section in guide.sections) {
          for (var i = 0; i < section.paragraphs.length; i++) {
            expect(section.evidenceFor(i), isNotEmpty);
            for (final evidence in section.evidenceFor(i)) {
              expect(guide.sourceByKey(evidence.sourceKey), isNotNull);
            }
          }
        }
      }
    },
  );
}
