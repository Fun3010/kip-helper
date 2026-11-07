import 'guide.dart';

/// A source-backed reading workflow; UI progress never verifies hardware state.
class GuideProcedure {
  const GuideProcedure({
    required this.id,
    required this.guideId,
    required this.title,
    required this.scope,
    required this.prerequisites,
    required this.variants,
    required this.sources,
  });

  final String id;
  final String guideId;
  final String title;
  final String scope;
  final List<String> prerequisites;
  final List<ProcedureVariant> variants;
  final List<GuideSource> sources;

  GuideSource? sourceByKey(String key) {
    for (final source in sources) {
      if (source.key == key) return source;
    }
    return null;
  }
}

class ProcedureVariant {
  const ProcedureVariant({
    required this.id,
    required this.title,
    required this.scope,
    required this.prerequisites,
    required this.steps,
  });

  final String id;
  final String title;
  final String scope;
  final List<String> prerequisites;
  final List<ProcedureStep> steps;
}

class ProcedureStep {
  const ProcedureStep({
    required this.action,
    required this.expectedResult,
    required this.evidence,
    this.title,
    this.control,
    this.hold,
    this.illustration,
    this.display,
    this.displayAsset,
  });

  final String action;
  final String expectedResult;
  final List<GuideEvidence> evidence;
  final String? title;
  final String? control;
  final String? hold;
  final GuideIllustration? illustration;
  final String? display;
  final String? displayAsset;
}
