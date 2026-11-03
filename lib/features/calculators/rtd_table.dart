import 'package:flutter/material.dart';

import '../../domain/calculations.dart';
import '../../domain/rtd_table.dart';
import '../../widgets/calculator_widgets.dart';

class RtdTable extends StatefulWidget {
  const RtdTable({super.key});

  @override
  State<RtdTable> createState() => _RtdTableState();
}

class _RtdTableState extends State<RtdTable> {
  final _start = TextEditingController(text: '0');
  final _end = TextEditingController(text: '100');
  final _step = TextEditingController(text: '10');
  RtdSensor _sensor = RtdSensor.pt100;
  RtdTableResult? _table;
  String? _error;

  void _invalidate() => setState(() {
    _table = null;
    _error = null;
  });

  void _generate() {
    FocusScope.of(context).unfocus();
    setState(() {
      _table = null;
      _error = null;
      try {
        _table = generateRtdTable(
          sensor: _sensor,
          start: parseNumber(_start.text),
          end: parseNumber(_end.text),
          step: parseNumber(_step.text),
        );
      } on CalculationException catch (error) {
        _error = error.message;
      }
    });
  }

  @override
  void dispose() {
    _start.dispose();
    _end.dispose();
    _step.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final table = _table;
    final temperatures = table == null
        ? <String>[]
        : formatRtdColumn(table.rows.map((r) => r.temperature).toList());
    final resistances = table == null
        ? <String>[]
        : formatRtdColumn(table.rows.map((r) => r.resistance).toList());
    return CalculatorScaffold(
      title: 'Таблица НСХ',
      children: [
        const HelpNote(
          'Номинальное сопротивление термометра по температуре. Выберите НСХ по паспорту датчика.',
        ),
        DropdownButtonFormField<RtdSensor>(
          initialValue: _sensor,
          isExpanded: true,
          itemHeight: null,
          decoration: const InputDecoration(labelText: 'НСХ датчика'),
          selectedItemBuilder: (context) => [
            for (final sensor in RtdSensor.values)
              Text(sensor.label.split(' ·').first),
          ],
          items: [
            for (final sensor in RtdSensor.values)
              DropdownMenuItem(
                value: sensor,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(sensor.label),
                ),
              ),
          ],
          onChanged: (sensor) {
            if (sensor == null) return;
            setState(() {
              _sensor = sensor;
              _table = null;
              _error = null;
            });
          },
        ),
        HelpNote(
          '${_sensor.label}. Диапазон: ${formatNumber(_sensor.minTemperature)}…${formatNumber(_sensor.maxTemperature)} °C.',
        ),
        NumberInput(
          controller: _start,
          label: 'Начальная температура',
          suffix: '°C',
          onChanged: _invalidate,
        ),
        NumberInput(
          controller: _end,
          label: 'Конечная температура',
          suffix: '°C',
          onChanged: _invalidate,
        ),
        NumberInput(
          controller: _step,
          label: 'Шаг температуры',
          suffix: '°C',
          onChanged: _invalidate,
        ),
        const HelpNote(
          'Начальная и конечная точки включены. Если диапазон не кратен шагу, последний шаг будет короче. Не более 501 строки.',
        ),
        FilledButton(
          onPressed: _generate,
          child: const Text('Построить таблицу'),
        ),
        if (_error != null)
          Semantics(
            liveRegion: true,
            child: Container(
              key: const ValueKey('rtd-table-error'),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colors.errorContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                _error!,
                style: TextStyle(color: colors.onErrorContainer),
              ),
            ),
          ),
        if (table != null)
          Column(
            key: const ValueKey('rtd-table-results'),
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Semantics(
                liveRegion: true,
                child: Text(
                  'Таблица: ${table.rows.length} строк',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              if (table.hasShortFinalStep)
                const Padding(
                  padding: EdgeInsets.only(top: 12),
                  child: HelpNote(
                    'Последний шаг укорочен до конечной температуры.',
                  ),
                ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('Температура, °C · Сопротивление, Ом'),
              ),
              for (var i = 0; i < table.rows.length; i++)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: colors.outlineVariant),
                    ),
                  ),
                  child: Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    spacing: 20,
                    runSpacing: 8,
                    children: [
                      SelectableText('${temperatures[i]} °C'),
                      SelectableText('${resistances[i]} Ом'),
                    ],
                  ),
                ),
              const Padding(
                padding: EdgeInsets.only(top: 20),
                child: HelpNote(
                  'Pt: IEC 60751; П и М: ГОСТ 6651–2009, п. 5.2.2–5.2.3. Допуск датчика и сопротивление проводов не учтены. Рабочий диапазон конкретного датчика может быть уже.',
                ),
              ),
            ],
          ),
      ],
    );
  }
}
