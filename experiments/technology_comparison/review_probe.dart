// ignore_for_file: avoid_print

import 'package:kip_helper/domain/calculations.dart';

void main() {
  for (final sensor in RtdSensor.values) {
    final resistance = resistanceFromTemperature(100, sensor);
    final temperature = temperatureFromResistance(resistance, sensor);
    print(
      '${sensor.name}: 100 C -> $resistance ohm -> $temperature C; '
      'within 100..200: ${SignalRange(100, 200).contains(temperature)}',
    );
  }
}
