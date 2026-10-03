import 'package:flutter/material.dart';
import '../../domain/calculations.dart';
import '../../widgets/calculator_widgets.dart';

class UnitConverter extends StatefulWidget {
  const UnitConverter({super.key, required this.pressure});
  final bool pressure;
  @override
  State<UnitConverter> createState() => _UnitConverterState();
}

class _UnitConverterState extends State<UnitConverter> {
  final _input = TextEditingController(text: '0');
  late int _from = widget.pressure ? PressureUnit.bar.index : 0;
  late int _to = widget.pressure ? PressureUnit.kgf.index : 1;
  List<String> get labels => widget.pressure
      ? PressureUnit.values.map((u) => u.label).toList()
      : TemperatureUnit.values.map((u) => u.label).toList();
  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  void _refresh() => setState(() {});
  @override
  Widget build(BuildContext context) => CalculatorScaffold(
    title: widget.pressure ? 'Давление' : 'Температура',
    children: [
      HelpNote(
        widget.pressure
            ? 'Пересчёт единиц давления. Тип давления (абсолютное или избыточное) при пересчёте не меняется.'
            : 'Пересчёт между шкалами Цельсия, Фаренгейта и Кельвина.',
      ),
      NumberInput(
        controller: _input,
        label: 'Значение',
        suffix: labels[_from],
        onChanged: _refresh,
      ),
      _unitField('Из', _from, (value) => setState(() => _from = value)),
      Center(
        child: IconButton.filledTonal(
          tooltip: 'Поменять единицы местами',
          onPressed: () => setState(() {
            final previous = _from;
            _from = _to;
            _to = previous;
          }),
          icon: const Icon(Icons.swap_vert),
        ),
      ),
      _unitField('В', _to, (value) => setState(() => _to = value)),
      CalculationResult(
        unit: labels[_to],
        calculate: () => widget.pressure
            ? convertPressure(
                parseNumber(_input.text),
                PressureUnit.values[_from],
                PressureUnit.values[_to],
              )
            : convertTemperature(
                parseNumber(_input.text),
                TemperatureUnit.values[_from],
                TemperatureUnit.values[_to],
              ),
      ),
    ],
  );
  Widget _unitField(String label, int selected, ValueChanged<int> onChanged) =>
      DropdownButtonFormField<int>(
        key: ValueKey('$label-$selected'),
        initialValue: selected,
        isExpanded: true,
        decoration: InputDecoration(labelText: label),
        items: [
          for (var index = 0; index < labels.length; index++)
            DropdownMenuItem(value: index, child: Text(labels[index])),
        ],
        onChanged: (value) {
          if (value != null) onChanged(value);
        },
      );
}
