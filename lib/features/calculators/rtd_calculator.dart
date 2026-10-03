import 'package:flutter/material.dart';
import '../../domain/calculations.dart';
import '../../widgets/calculator_widgets.dart';

class RtdCalculator extends StatefulWidget {
  const RtdCalculator({super.key});
  @override
  State<RtdCalculator> createState() => _RtdCalculatorState();
}

class _RtdCalculatorState extends State<RtdCalculator> {
  final _input = TextEditingController(text: '0');
  final _lower = TextEditingController(text: '0');
  final _upper = TextEditingController(text: '100');
  RtdSensor _sensor = RtdSensor.pt100;
  bool _toResistance = true;
  double get _temperature => _toResistance
      ? parseNumber(_input.text)
      : temperatureFromResistance(parseNumber(_input.text), _sensor);
  double get _resistance => resistanceFromTemperature(_temperature, _sensor);
  void _refresh() => setState(() {});
  @override
  void dispose() {
    _input.dispose();
    _lower.dispose();
    _upper.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => CalculatorScaffold(
    title: 'Термосопротивление',
    children: [
      const HelpNote(
        'Номинальная характеристика датчика. Сопротивление проводов и допуск конкретного термометра в расчёт не входят.',
      ),
      DropdownButtonFormField<RtdSensor>(
        initialValue: _sensor,
        isExpanded: true,
        decoration: const InputDecoration(labelText: 'НСХ датчика'),
        items: [
          for (final sensor in RtdSensor.values)
            DropdownMenuItem(value: sensor, child: Text(sensor.label)),
        ],
        onChanged: (sensor) {
          if (sensor != null) setState(() => _sensor = sensor);
        },
      ),
      SwitchListTile.adaptive(
        contentPadding: EdgeInsets.zero,
        title: Text(
          _toResistance ? 'Ввод: температура' : 'Ввод: сопротивление',
        ),
        value: _toResistance,
        onChanged: (value) => setState(() {
          _toResistance = value;
          _input.text = value ? '0' : _sensor.r0.toString();
        }),
      ),
      NumberInput(
        controller: _input,
        label: _toResistance ? 'Температура' : 'Сопротивление',
        suffix: _toResistance ? '°C' : 'Ом',
        onChanged: _refresh,
      ),
      CalculationResult(
        unit: _toResistance ? 'Ом' : '°C',
        calculate: () => _toResistance ? _resistance : _temperature,
      ),
      Text(
        'Выход преобразователя',
        style: Theme.of(context).textTheme.titleLarge,
      ),
      const HelpNote(
        'Сигнал появляется только при подключении к преобразователю. Задайте его диапазон; ток линейно зависит от температуры, не от сопротивления.',
      ),
      NumberInput(
        controller: _lower,
        label: 'Температура при 4 мА',
        suffix: '°C',
        onChanged: _refresh,
      ),
      NumberInput(
        controller: _upper,
        label: 'Температура при 20 мА',
        suffix: '°C',
        onChanged: _refresh,
      ),
      CalculationResult(
        title: 'Расчётный ток',
        unit: 'мА',
        calculate: () {
          final range = SignalRange(
            parseNumber(_lower.text),
            parseNumber(_upper.text),
          );
          return rtdMilliamps(_temperature, _sensor, range);
        },
      ),
      const HelpNote(
        'Pt: IEC 60751; П и М: ГОСТ 6651–2009, п. 5.2.2–5.2.3. Платина: −200…850 °C, медь: −180…200 °C. Реальный рабочий диапазон датчика может быть уже. Pt100 и 100П — разные НСХ; выбирайте по паспорту.',
      ),
    ],
  );
}
