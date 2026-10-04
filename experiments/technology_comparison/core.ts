type GuideModule = Readonly<{ id: string; title: string; sections: readonly string[] }>;
const modules: readonly GuideModule[] = [
  { id: 'signal', title: '4–20 мА', sections: ['Расчёт', 'Диапазон'] },
  { id: 'sipart', title: 'SIPART PS2', sections: ['Документация'] },
];

function signal(value: number, lower: number, upper: number): number {
  if (![value, lower, upper].every(Number.isFinite) || upper <= lower) {
    throw new RangeError('Invalid range or value');
  }
  if (value < lower || value > upper) throw new RangeError('Outside range');
  return 4 + 16 * (value - lower) / (upper - lower);
}

const cases = [[0, 0, 100, 4], [50, 0, 100, 12], [100, 0, 100, 20], [-25, -50, 50, 8]];
for (const [value, lower, upper, expected] of cases) {
  if (Math.abs(signal(value, lower, upper) - expected) > 1e-9) throw Error('Wrong result');
}
for (const values of [[0, 0, 0], [0, 100, 0], [101, 0, 100], [NaN, 0, 100], [0, 0, Infinity]]) {
  let rejected = false;
  try { signal(values[0], values[1], values[2]); } catch { rejected = true; }
  if (!rejected) throw Error('Invalid input accepted');
}
if (new Set(modules.map(module => module.id)).size !== modules.length) throw Error('Duplicate module');
console.log('TypeScript: 10 checks passed');
