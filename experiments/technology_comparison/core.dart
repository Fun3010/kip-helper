// ignore_for_file: avoid_print

class GuideModule {
  final String id;
  final String title;
  final List<String> sections;
  const GuideModule(this.id, this.title, this.sections);
}

const modules = [
  GuideModule('signal', '4–20 мА', ['Расчёт', 'Диапазон']),
  GuideModule('sipart', 'SIPART PS2', ['Документация']),
];

double signal(double value, double lower, double upper) {
  if (![value, lower, upper].every((v) => v.isFinite) || upper <= lower) {
    throw ArgumentError('Invalid range or value');
  }
  if (value < lower || value > upper) throw ArgumentError('Outside range');
  return 4 + 16 * (value - lower) / (upper - lower);
}

void main() {
  for (final c in <List<double>>[
    [0, 0, 100, 4],
    [50, 0, 100, 12],
    [100, 0, 100, 20],
    [-25, -50, 50, 8],
  ]) {
    if ((signal(c[0], c[1], c[2]) - c[3]).abs() > 1e-9) {
      throw StateError('Wrong result');
    }
  }
  for (final c in <List<double>>[
    [0, 0, 0],
    [0, 100, 0],
    [101, 0, 100],
    [double.nan, 0, 100],
    [0, 0, double.infinity],
  ]) {
    var rejected = false;
    try {
      signal(c[0], c[1], c[2]);
    } on ArgumentError {
      rejected = true;
    }
    if (!rejected) throw StateError('Invalid input accepted');
  }
  if (modules.map((m) => m.id).toSet().length != modules.length) {
    throw StateError('Duplicate module');
  }
  print('Dart: 10 checks passed');
}
