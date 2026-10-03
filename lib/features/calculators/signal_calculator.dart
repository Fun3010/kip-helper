import 'package:flutter/material.dart';
import '../../domain/calculations.dart';
import '../../widgets/calculator_widgets.dart';

class SignalCalculator extends StatefulWidget {
  const SignalCalculator({super.key});
  @override
  State<SignalCalculator> createState() => _SignalCalculatorState();
}

class _SignalCalculatorState extends State<SignalCalculator> {
  final _input = TextEditingController(text: '50');
  final _lower = TextEditingController(text: '0');
  final _upper = TextEditingController(text: '100');
  bool _toCurrent = true;
  SignalRange get _range =>
      SignalRange(parseNumber(_lower.text), parseNumber(_upper.text));
  void _refresh() => setState(() {});
  @override
  void dispose() {
    _input.dispose();
    _lower.dispose();
    _upper.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var outside = false;
    try {
      final input = parseNumber(_input.text);
      outside = _toCurrent ? !_range.contains(input) : input < 4 || input > 20;
    } on CalculationException {
      /* Validation is displayed in the result. */
    }
    return CalculatorScaffold(
      title: 'Сигнал 4–20 мА',
      children: [
        const HelpNote(
          'Для линейного преобразователя. Укажите настроенные нижний и верхний пределы в одинаковых единицах: °C, бар, %, мм и т. д.',
        ),
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          title: Text(_toCurrent ? 'Ввод: величина' : 'Ввод: ток'),
          value: _toCurrent,
          onChanged: (value) => setState(() {
            _toCurrent = value;
            _input.text = value ? '50' : '12';
          }),
        ),
        NumberInput(
          controller: _lower,
          label: 'Нижний предел · 4 мА',
          onChanged: _refresh,
        ),
        NumberInput(
          controller: _upper,
          label: 'Верхний предел · 20 мА',
          onChanged: _refresh,
        ),
        NumberInput(
          controller: _input,
          label: _toCurrent ? 'Измеряемая величина' : 'Ток',
          suffix: _toCurrent ? null : 'мА',
          onChanged: _refresh,
        ),
        CalculationResult(
          unit: _toCurrent ? 'мА' : 'ед.',
          calculate: () => _toCurrent
              ? _range.toMilliamps(parseNumber(_input.text))
              : _range.fromMilliamps(parseNumber(_input.text)),
        ),
        if (outside)
          const HelpNote(
            'За пределами 4–20 мА / настроенного диапазона. Показана математическая экстраполяция, а не подтверждённое измерение. Аварийные токи проверяйте по настройкам преобразователя.',
          ),
        const HelpNote(
          'I = 4 + 16 × (X − НП) / (ВП − НП)\nX = НП + (I − 4) / 16 × (ВП − НП)\nДля расходомера с извлечением квадратного корня эта формула неприменима.',
        ),
      ],
    );
  }
}
