class GuideSource {
  const GuideSource({required this.title, this.url, this.document});
  final String title;
  final String? url;
  final String? document;
}

class GuideIllustration {
  const GuideIllustration({
    required this.asset,
    required this.title,
    required this.caption,
    required this.source,
  });
  final String asset;
  final String title;
  final String caption;
  final String source;
  bool matches(String query) =>
      '$title $caption $source'.toLowerCase().contains(query);
}

class GuideSection {
  const GuideSection({required this.title, required this.paragraphs});
  final String title;
  final List<String> paragraphs;
  bool matches(String query) =>
      '$title ${paragraphs.join(' ')}'.toLowerCase().contains(query);
}

class InstrumentGuide {
  const InstrumentGuide({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.category,
    required this.scope,
    required this.sections,
    required this.sources,
    this.searchTerms = const [],
    this.illustrations = const [],
    this.thumbnailAsset,
  });
  final String id;
  final String title;
  final String subtitle;
  final String category;
  final String scope;
  final List<GuideSection> sections;
  final List<GuideSource> sources;
  final List<String> searchTerms;
  final List<GuideIllustration> illustrations;
  final String? thumbnailAsset;
  bool matches(String query) =>
      '$id $title $subtitle $category $scope ${searchTerms.join(' ')}'
          .toLowerCase()
          .contains(query) ||
      sections.any((s) => s.matches(query)) ||
      illustrations.any((i) => i.matches(query));
}
