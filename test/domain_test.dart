import 'package:flutter_test/flutter_test.dart';
import 'package:kip_helper/domain/calculations.dart';

void main() {
  final invalid = throwsA(isA<CalculationException>());
  const nonfinite = [double.nan, double.infinity, double.negativeInfinity];

  group('Number input and display', () {
    test('accepts decimal comma, whitespace, signs and exponent', () {
      for (final entry in {
        ' 12,5 ': 12.5,
        '-0,25': -0.25,
        '+42': 42.0,
        '1e3': 1000.0,
        '0': 0.0,
        '.5': 0.5,
        '1,25e-2': 0.0125,
        '-2.5E+2': -250.0,
      }.entries) {
        expect(parseNumber(entry.key), entry.value);
      }
    });
    test('rejects malformed and nonfinite numbers', () {
      for (final input in [
        '',
        ' ',
        '-',
        'abc',
        '1,2,3',
        '1.2.3',
        'NaN',
        'Infinity',
        '-Infinity',
        '1e999',
        '12 V',
        '.',
        ',',
        '+',
        '1e',
        '1e-',
        '1e+',
        'e2',
        '1 e2',
        '1e2e3',
      ]) {
        expect(() => parseNumber(input), invalid, reason: input);
      }
    });
    test('formats zero, decimals and extreme magnitudes', () {
      expect(formatNumber(-0.0), '0');
      expect(formatNumber(100), '100');
      expect(formatNumber(12.5), '12,5');
      expect(formatNumber(-12.34567), '-12,3457');
      for (final value in [1e10, -1e-8]) {
        expect(
          parseNumber(formatNumber(value)),
          closeTo(value, value.abs() * 1e-5),
        );
      }
      for (final value in nonfinite) {
        expect(() => formatNumber(value), invalid);
      }
    });
  });

  group('Temperature', () {
    test('known fixed points', () {
      expect(
        convertTemperature(
          0,
          TemperatureUnit.celsius,
          TemperatureUnit.fahrenheit,
        ),
        32,
      );
      expect(
        convertTemperature(
          100,
          TemperatureUnit.celsius,
          TemperatureUnit.fahrenheit,
        ),
        212,
      );
      expect(
        convertTemperature(
          -40,
          TemperatureUnit.celsius,
          TemperatureUnit.fahrenheit,
        ),
        -40,
      );
      expect(
        convertTemperature(0, TemperatureUnit.celsius, TemperatureUnit.kelvin),
        273.15,
      );
    });
    for (final from in TemperatureUnit.values) {
      for (final to in TemperatureUnit.values) {
        test('${from.name} to ${to.name} roundtrips', () {
          for (final celsius in [-273.15, -100.0, 0.0, 37.5, 100.0, 850.0]) {
            final input = convertTemperature(
              celsius,
              TemperatureUnit.celsius,
              from,
            );
            final output = convertTemperature(input, from, to);
            expect(convertTemperature(output, to, from), closeTo(input, 1e-9));
          }
        });
      }
      test('${from.name} rejects below absolute zero and nonfinite values', () {
        final absoluteZero = convertTemperature(
          -273.15,
          TemperatureUnit.celsius,
          from,
        );
        expect(
          convertTemperature(absoluteZero, from, TemperatureUnit.kelvin),
          closeTo(0, 1e-10),
        );
        expect(
          () => convertTemperature(
            absoluteZero - 0.001,
            from,
            TemperatureUnit.kelvin,
          ),
          invalid,
        );
        for (final value in nonfinite) {
          expect(() => convertTemperature(value, from, from), invalid);
        }
      });
    }
  });

  group('Pressure', () {
    test('independent reference conversions', () {
      expect(convertPressure(1, PressureUnit.bar, PressureUnit.pascal), 100000);
      expect(
        convertPressure(1, PressureUnit.atmosphere, PressureUnit.pascal),
        101325,
      );
      expect(
        convertPressure(1, PressureUnit.kgf, PressureUnit.pascal),
        98066.5,
      );
      expect(
        convertPressure(1, PressureUnit.water, PressureUnit.pascal),
        9.80665,
      );
    });
    for (final from in PressureUnit.values) {
      for (final to in PressureUnit.values) {
        test(
          '${from.name} to ${to.name} roundtrips including gauge vacuum',
          () {
            for (final input in [-1.0, 0.0, 0.001, 1.0, 12345.67]) {
              final output = convertPressure(input, from, to);
              expect(
                convertPressure(output, to, from),
                closeTo(input, input.abs() * 1e-12 + 1e-12),
              );
            }
          },
        );
      }
    }
    test('rejects nonfinite inputs and overflow', () {
      for (final value in nonfinite) {
        expect(
          () => convertPressure(value, PressureUnit.bar, PressureUnit.pascal),
          invalid,
        );
      }
      expect(
        () => convertPressure(
          1e308,
          PressureUnit.megapascal,
          PressureUnit.pascal,
        ),
        invalid,
      );
    });
  });

  group('4–20 mA transmitter', () {
    test('boundaries, midpoint and inverse conversion', () {
      final range = SignalRange(-50, 150);
      expect(range.toMilliamps(-50), 4);
      expect(range.toMilliamps(50), 12);
      expect(range.toMilliamps(150), 20);
      expect(range.fromMilliamps(4), -50);
      expect(range.fromMilliamps(12), 50);
      expect(range.fromMilliamps(20), 150);
      for (final value in [-50.0, -12.5, 0.0, 66.6, 150.0]) {
        expect(
          range.fromMilliamps(range.toMilliamps(value)),
          closeTo(value, 1e-10),
        );
      }
    });
    test('reports inclusive limits and preserves extrapolation', () {
      final range = SignalRange(0, 100);
      expect(range.contains(0), isTrue);
      expect(range.contains(100), isTrue);
      expect(range.contains(-0.001), isFalse);
      expect(range.contains(100.001), isFalse);
      expect(range.contains(double.nan), isFalse);
      expect(range.toMilliamps(-25), 0);
      expect(range.toMilliamps(125), 24);
      expect(range.fromMilliamps(0), -25);
      expect(range.fromMilliamps(24), 125);
    });
    test('rejects reversed, zero-width, overflow and nonfinite ranges', () {
      expect(() => SignalRange(100, 0), invalid);
      expect(() => SignalRange(1, 1), invalid);
      expect(() => SignalRange(-1e308, 1e308), invalid);
      for (final value in nonfinite) {
        expect(() => SignalRange(value, 100), invalid);
        expect(() => SignalRange(0, value), invalid);
        expect(() => SignalRange(0, 100).toMilliamps(value), invalid);
        expect(() => SignalRange(0, 100).fromMilliamps(value), invalid);
      }
      expect(() => SignalRange(0, 1).toMilliamps(1e308), invalid);
      expect(() => SignalRange(0, 1e308).fromMilliamps(1000), invalid);
    });
  });

  group('RTD characteristics', () {
    test('GOST platinum and copper positive reference points', () {
      expect(
        resistanceFromTemperature(100, RtdSensor.p100),
        closeTo(139.1059, 1e-9),
      );
      expect(
        resistanceFromTemperature(100, RtdSensor.p50),
        closeTo(69.55295, 1e-9),
      );
      expect(
        resistanceFromTemperature(100, RtdSensor.m100),
        closeTo(142.8, 1e-9),
      );
      expect(
        resistanceFromTemperature(100, RtdSensor.m50),
        closeTo(71.4, 1e-9),
      );
    });
    test('Copper agrees with independent negative GOST table values', () {
      // GOST 6651-2009, table A.3, printed p. 19 (PDF page 23):
      // https://temperatures.ru/pdf/GOST/gost6651-2009.pdf
      // The source rounds R to 0.01 ohm; tolerance reflects that rounding.
      for (final entry in <double, double>{
        -180: 20.53,
        -100: 56.54,
        -50: 78.46,
        -10: 95.72,
      }.entries) {
        expect(
          resistanceFromTemperature(entry.key, RtdSensor.m100),
          closeTo(entry.value, 0.005),
        );
        expect(
          resistanceFromTemperature(entry.key, RtdSensor.m50),
          closeTo(entry.value / 2, 0.0025),
        );
        // The rounded minimum may fall just below the exact NSH boundary.
        if (entry.key > RtdSensor.m100.minTemperature) {
          expect(
            temperatureFromResistance(entry.value, RtdSensor.m100),
            closeTo(entry.key, 0.012),
          );
        }
      }
    });
    for (final sensor in RtdSensor.values) {
      test(
        '${sensor.name} inverse RTD transmitter endpoints tolerate roundoff',
        () {
          final range = SignalRange(100, 200);
          for (final point in <double, double>{100: 4, 200: 20}.entries) {
            final resistance = resistanceFromTemperature(point.key, sensor);
            final recovered = temperatureFromResistance(resistance, sensor);
            expect(
              rtdMilliamps(recovered, sensor, range),
              closeTo(point.value, 1e-10),
            );
          }
        },
      );
      test('${sensor.name} transmitter rejects actual out-of-range values', () {
        expect(
          () => rtdMilliamps(100 - 1e-5, sensor, SignalRange(100, 200)),
          invalid,
        );
        expect(
          () => rtdMilliamps(200 + 1e-5, sensor, SignalRange(100, 200)),
          invalid,
        );
        expect(
          () => rtdMilliamps(
            0,
            sensor,
            SignalRange(sensor.minTemperature - 1, 100),
          ),
          invalid,
        );
        expect(
          () => rtdMilliamps(
            0,
            sensor,
            SignalRange(0, sensor.maxTemperature + 1),
          ),
          invalid,
        );
        for (final value in nonfinite) {
          expect(
            () => rtdMilliamps(value, sensor, SignalRange(0, 100)),
            invalid,
          );
        }
      });
    }
    test('Pt100 independent CVD reference values', () {
      expect(resistanceFromTemperature(0, RtdSensor.pt100), 100);
      expect(
        resistanceFromTemperature(100, RtdSensor.pt100),
        closeTo(138.5055, 1e-9),
      );
      expect(
        resistanceFromTemperature(-100, RtdSensor.pt100),
        closeTo(60.25584, 1e-8),
      );
      expect(
        temperatureFromResistance(138.5055, RtdSensor.pt100),
        closeTo(100, 1e-8),
      );
    });
    for (final sensor in RtdSensor.values) {
      test(
        '${sensor.name} roundtrips endpoints, negative and positive temperatures',
        () {
          final points =
              {
                    sensor.minTemperature,
                    sensor.maxTemperature,
                    sensor.minTemperature / 2,
                    0.0,
                    50.0,
                    100.0,
                    sensor.maxTemperature / 2,
                  }
                  .where(
                    (t) =>
                        t >= sensor.minTemperature &&
                        t <= sensor.maxTemperature,
                  )
                  .toList()
                ..sort();
          var previous = double.negativeInfinity;
          for (final temperature in points) {
            final resistance = resistanceFromTemperature(temperature, sensor);
            expect(resistance, greaterThan(previous));
            expect(
              temperatureFromResistance(resistance, sensor),
              closeTo(temperature, 1e-7),
            );
            previous = resistance;
          }
          expect(resistanceFromTemperature(0, sensor), sensor.r0);
        },
      );
      test('${sensor.name} rejects values outside its own characteristic', () {
        expect(
          () => resistanceFromTemperature(sensor.minTemperature - 0.01, sensor),
          invalid,
        );
        expect(
          () => resistanceFromTemperature(sensor.maxTemperature + 0.01, sensor),
          invalid,
        );
        final minimum = resistanceFromTemperature(
          sensor.minTemperature,
          sensor,
        );
        final maximum = resistanceFromTemperature(
          sensor.maxTemperature,
          sensor,
        );
        expect(
          () => temperatureFromResistance(minimum - 0.001, sensor),
          invalid,
        );
        expect(
          () => temperatureFromResistance(maximum + 0.001, sensor),
          invalid,
        );
        expect(() => temperatureFromResistance(-1, sensor), invalid);
        for (final value in nonfinite) {
          expect(() => resistanceFromTemperature(value, sensor), invalid);
          expect(() => temperatureFromResistance(value, sensor), invalid);
        }
      });
    }
  });
}
