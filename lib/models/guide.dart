enum GuideEvidenceState {
  verified,
  locatorPending,
  workingChecklist,
  needsVisualCheck,
}

class GuideEvidence {
  const GuideEvidence({
    required this.sourceKey,
    required this.locator,
    this.state = GuideEvidenceState.verified,
    this.note,
  });

  final String sourceKey;
  final String locator;
  final GuideEvidenceState state;
  final String? note;

  bool matches(String query) =>
      '$sourceKey $locator ${note ?? ''}'.toLowerCase().contains(query);
}

class GuideSource {
  const GuideSource({required this.title, this.key, this.url, this.document});

  final String title;
  final String? key;
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
  const GuideSection({
    required this.title,
    required this.paragraphs,
    this.evidenceByParagraph = const {},
  });

  final String title;
  final List<String> paragraphs;
  final Map<int, List<GuideEvidence>> evidenceByParagraph;

  List<GuideEvidence> evidenceFor(int paragraphIndex) =>
      evidenceByParagraph[paragraphIndex] ?? const [];

  bool matches(String query) =>
      '$title ${paragraphs.join(' ')}'.toLowerCase().contains(query) ||
      evidenceByParagraph.values
          .expand((items) => items)
          .any((evidence) => evidence.matches(query));
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

  GuideSource? sourceByKey(String key) {
    for (final source in sources) {
      if (source.key == key) return source;
    }
    return null;
  }

  bool matches(String query) =>
      '$id $title $subtitle $category $scope ${searchTerms.join(' ')}'
          .toLowerCase()
          .contains(query) ||
      sections.any((s) => s.matches(query)) ||
      illustrations.any((i) => i.matches(query));
}
