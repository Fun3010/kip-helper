import 'dart:math' as math;

/// A validation error intended to be shown next to engineering inputs.
class CalculationException implements Exception {
  const CalculationException(this.message);
  final String message;
  @override
  String toString() => message;
}

double parseNumber(String text) {
  final value = double.tryParse(text.trim().replaceAll(',', '.'));
  if (value == null || !value.isFinite) {
    throw const CalculationException('Введите конечное число');
  }
  return value;
}

double _finite(double value) {
  if (!value.isFinite) {
    throw const CalculationException('Число выходит за пределы расчёта');
  }
  return value;
}

String formatNumber(double value) {
  _finite(value);
  if (value == 0) return '0';
  if (value.abs() >= 1e9 || value.abs() < 0.0001) {
    return value.toStringAsExponential(5).replaceAll('.', ',');
  }
  return value
      .toStringAsFixed(4)
      .replaceFirst(RegExp(r'\.?0+$'), '')
      .replaceAll('.', ',');
}

enum TemperatureUnit {
  celsius('°C'),
  fahrenheit('°F'),
  kelvin('K');

  const TemperatureUnit(this.label);
  final String label;
}

double convertTemperature(
  double input,
  TemperatureUnit from,
  TemperatureUnit to,
) {
  _finite(input);
  final celsius = switch (from) {
    TemperatureUnit.celsius => input,
    TemperatureUnit.fahrenheit => (input - 32) / 1.8,
    TemperatureUnit.kelvin => input - 273.15,
  };
  if (celsius < -273.15 - 1e-10) {
    throw const CalculationException('Температура ниже абсолютного нуля');
  }
  return _finite(switch (to) {
    TemperatureUnit.celsius => celsius,
    TemperatureUnit.fahrenheit => celsius * 1.8 + 32,
    TemperatureUnit.kelvin => celsius + 273.15,
  });
}

enum PressureUnit {
  pascal('Па', 1),
  kilopascal('кПа', 1000),
  megapascal('МПа', 1000000),
  bar('бар', 100000),
  atmosphere('атм', 101325),
  mercury('мм рт. ст.', 133.322387415),
  water('мм вод. ст.', 9.80665),
  kgf('кгс/см²', 98066.5);

  const PressureUnit(this.label, this.pascals);
  final String label;
  final double pascals;
}

double convertPressure(double value, PressureUnit from, PressureUnit to) =>
    _finite(_finite(value) * (from.pascals / to.pascals));

/// A linear transmitter range; resistance is not itself a 4–20 mA signal.
class SignalRange {
  SignalRange(this.lower, this.upper) {
    _finite(lower);
    _finite(upper);
    if (upper <= lower || !(upper - lower).isFinite) {
      throw const CalculationException(
        'Верхний предел должен быть больше нижнего',
      );
    }
  }
  final double lower;
  final double upper;
  double toMilliamps(double value) =>
      _finite(4 + 16 * ((_finite(value) - lower) / (upper - lower)));
  double fromMilliamps(double current) =>
      _finite(lower + ((_finite(current) - 4) / 16) * (upper - lower));
  bool contains(double value) => value >= lower && value <= upper;
}

double rtdMilliamps(double temperature, RtdSensor sensor, SignalRange range) {
  resistanceFromTemperature(temperature, sensor);
  if (range.lower < sensor.minTemperature ||
      range.upper > sensor.maxTemperature) {
    throw const CalculationException(
      'Диапазон преобразователя выходит за пределы НСХ',
    );
  }
  // The inverse NSH is numerical; tolerate its sub-nanodegree rounding at endpoints.
  const tolerance = 1e-8;
  if (temperature < range.lower - tolerance ||
      temperature > range.upper + tolerance) {
    throw const CalculationException(
      'Температура вне диапазона преобразователя',
    );
  }
  return range.toMilliamps(temperature.clamp(range.lower, range.upper));
}

/// Nominal characteristics: IEC 60751 and GOST 6651-2009 §5.2.2–5.2.3.
enum RtdSensor {
  pt100('Pt100 · α = 0,00385', 100),
  pt500('Pt500 · α = 0,00385', 500),
  pt1000('Pt1000 · α = 0,00385', 1000),
  p100('100П · α = 0,00391', 100, gostPlatinum: true),
  p50('50П · α = 0,00391', 50, gostPlatinum: true),
  m100('100М · α = 0,00428', 100, copper: true),
  m50('50М · α = 0,00428', 50, copper: true);

  const RtdSensor(
    this.label,
    this.r0, {
    this.gostPlatinum = false,
    this.copper = false,
  });
  final String label;
  final double r0;
  final bool gostPlatinum;
  final bool copper;
  double get minTemperature => copper ? -180 : -200;
  double get maxTemperature => copper ? 200 : 850;
}

double _resistanceRatio(double temperature, RtdSensor sensor) {
  if (sensor.copper) {
    return 1 +
        4.28e-3 * temperature +
        (temperature < 0
            ? -6.2032e-7 * temperature * (temperature + 6.7) +
                  8.5154e-10 * math.pow(temperature, 3)
            : 0);
  }
  final a = sensor.gostPlatinum ? 3.9690e-3 : 3.9083e-3;
  final b = sensor.gostPlatinum ? -5.841e-7 : -5.775e-7;
  final c = sensor.gostPlatinum ? -4.330e-12 : -4.183e-12;
  return 1 +
      a * temperature +
      b * temperature * temperature +
      (temperature < 0
          ? c * (temperature - 100) * math.pow(temperature, 3)
          : 0);
}

double resistanceFromTemperature(double temperature, RtdSensor sensor) {
  _finite(temperature);
  if (temperature < sensor.minTemperature ||
      temperature > sensor.maxTemperature) {
    throw CalculationException(
      'Диапазон НСХ: ${sensor.minTemperature.toInt()}…${sensor.maxTemperature.toInt()} °C',
    );
  }
  return sensor.r0 * _resistanceRatio(temperature, sensor);
}

double temperatureFromResistance(double resistance, RtdSensor sensor) {
  _finite(resistance);
  final minimum = resistanceFromTemperature(sensor.minTemperature, sensor);
  final maximum = resistanceFromTemperature(sensor.maxTemperature, sensor);
  if (resistance < minimum || resistance > maximum) {
    throw CalculationException(
      'Допустимое сопротивление: ${formatNumber(minimum)}…${formatNumber(maximum)} Ом',
    );
  }
  var low = sensor.minTemperature;
  var high = sensor.maxTemperature;
  // Monotonic NSH: bisection also handles the negative-temperature cubic term.
  for (var iteration = 0; iteration < 64; iteration++) {
    final middle = (low + high) / 2;
    if (resistanceFromTemperature(middle, sensor) < resistance) {
      low = middle;
    } else {
      high = middle;
    }
  }
  final result = (low + high) / 2;
  return result.abs() < 1e-10 ? 0 : result;
}
