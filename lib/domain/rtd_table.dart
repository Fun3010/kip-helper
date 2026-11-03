import 'calculations.dart';

/// One nominal RTD point: temperature in °C and resistance in ohms.
class RtdTablePoint {
  const RtdTablePoint(this.temperature, this.resistance);

  final double temperature;
  final double resistance;
}

class RtdTableResult {
  RtdTableResult({
    required List<RtdTablePoint> rows,
    required this.hasShortFinalStep,
  }) : rows = List.unmodifiable(rows);

  final List<RtdTablePoint> rows;
  final bool hasShortFinalStep;
}

/// Includes both endpoints; a non-multiple end produces a shorter final step.
/// The count is checked before allocation, and points use integer indices rather
/// than cumulative floating-point addition. All NSХ coefficients live in the
/// existing resistanceFromTemperature function.
RtdTableResult generateRtdTable({
  required RtdSensor sensor,
  required double start,
  required double end,
  required double step,
}) {
  if (!start.isFinite || !end.isFinite || !step.isFinite) {
    throw const CalculationException('Введите конечные числа');
  }
  if (step <= 0) {
    throw const CalculationException('Шаг должен быть больше нуля');
  }
  if (end < start) {
    throw const CalculationException('Конечная температура меньше начальной');
  }
  // Validate using the existing characteristic, including family-specific bounds.
  final firstResistance = resistanceFromTemperature(start, sensor);
  resistanceFromTemperature(end, sensor);
  if (end == start) {
    return RtdTableResult(
      rows: [RtdTablePoint(start, firstResistance)],
      hasShortFinalStep: false,
    );
  }

  final ratio = (end - start) / step;
  const maximumIntervals = 500;
  // Permit only machine-rounding noise around an integer (e.g. 0.3 / 0.1).
  // The cap is applied before round/ceil so an overflowing ratio is harmless.
  const ratioTolerance = 4e-12;
  if (!ratio.isFinite || ratio > maximumIntervals + ratioTolerance) {
    throw const CalculationException(
      'Не более 501 строки. Увеличьте шаг или сократите диапазон',
    );
  }
  final nearest = ratio.round();
  final exactMultiple =
      nearest >= 1 && (ratio - nearest).abs() <= 8e-15 * ratio.abs();
  final intervals = exactMultiple ? nearest : (ratio < 1 ? 1 : ratio.ceil());
  if (intervals > maximumIntervals) {
    throw const CalculationException(
      'Не более 501 строки. Увеличьте шаг или сократите диапазон',
    );
  }
  final rows = <RtdTablePoint>[RtdTablePoint(start, firstResistance)];
  for (var index = 1; index <= intervals; index++) {
    final temperature = index == intervals ? end : start + index * step;
    if (temperature <= rows.last.temperature ||
        (index < intervals && temperature >= end)) {
      throw const CalculationException(
        'Шаг слишком мал для точного представления. Увеличьте шаг',
      );
    }
    rows.add(
      RtdTablePoint(
        temperature,
        resistanceFromTemperature(temperature, sensor),
      ),
    );
  }
  return RtdTableResult(rows: rows, hasShortFinalStep: !exactMultiple);
}
