import 'package:flutter_test/flutter_test.dart';
import 'package:kip_helper/data/guides.dart';
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
  test('Search covers model scopes, codes and empty results', () {
    expect(guides.where((g) => g.matches('ргау.407834.006')).single.id, 'su1s');
    expect(guides.where((g) => g.matches('a01')).single.id, 'sokrat');
    expect(guides.where((g) => g.matches('sipart')).single.id, 'sipart');
    expect(guides.where((g) => g.matches('unknown-model-xyz')), isEmpty);
    expect(guides.where((g) => g.matches('')).length, guides.length);
  });
}
