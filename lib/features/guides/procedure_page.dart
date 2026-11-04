import 'package:flutter/material.dart';

import '../../models/guide_procedure.dart';
import '../../services/open_source.dart';

class ProcedurePage extends StatefulWidget {
  const ProcedurePage({super.key, required this.procedure});

  final GuideProcedure procedure;

  @override
  State<ProcedurePage> createState() => _ProcedurePageState();
}

class _ProcedurePageState extends State<ProcedurePage> {
  final _scroll = ScrollController();
  ProcedureVariant? _variant;
  bool _confirmed = false;
  int? _index;
  bool _finished = false;

  @override
  void didUpdateWidget(covariant ProcedurePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.procedure, widget.procedure)) _reset();
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _change(VoidCallback change) {
    setState(change);
    if (_scroll.hasClients) _scroll.jumpTo(0);
  }

  void _reset() {
    _variant = null;
    _confirmed = false;
    _index = null;
    _finished = false;
  }

  static const _progressNotice =
      'Переход между шагами отмечает только просмотр и не подтверждает состояние прибора. '
      'Результат проверяют на самом приборе по руководству.';

  Widget _heading(String text) => Padding(
    padding: const EdgeInsets.only(top: 20, bottom: 8),
    child: Text(text, style: Theme.of(context).textTheme.titleLarge),
  );

  Widget _paragraph(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Text(text, style: const TextStyle(height: 1.45)),
  );

  List<Widget> _preparation() => [
    _heading('Область применения'),
    _paragraph(widget.procedure.scope),
    _heading('Перед началом'),
    for (final prerequisite in widget.procedure.prerequisites)
      _paragraph(prerequisite),
    _heading('Выберите своё исполнение'),
    for (final variant in widget.procedure.variants)
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Semantics(
          selected: _variant == variant,
          child: OutlinedButton(
            key: ValueKey('variant-${variant.id}'),
            onPressed: variant.steps.isEmpty
                ? null
                : () => _change(() {
                    _variant = variant;
                    _confirmed = false;
                  }),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                '${_variant == variant ? 'Выбрано: ' : ''}${variant.title}',
              ),
            ),
          ),
        ),
      ),
    if (_variant != null) ...[
      _heading('Условия выбранного исполнения'),
      _paragraph(_variant!.scope),
      for (final prerequisite in _variant!.prerequisites)
        _paragraph(prerequisite),
    ],
    CheckboxListTile(
      key: const ValueKey('procedure-confirm'),
      value: _confirmed,
      contentPadding: EdgeInsets.zero,
      controlAffinity: ListTileControlAffinity.leading,
      title: const Text('Исполнение совпадает, условия начала проверены'),
      onChanged: _variant == null
          ? null
          : (value) => setState(() {
              _confirmed = value ?? false;
            }),
    ),
    const SizedBox(height: 16),
    FilledButton(
      key: const ValueKey('procedure-start'),
      onPressed: _variant == null || !_confirmed
          ? null
          : () => _change(() {
              _index = 0;
              _finished = false;
            }),
      child: const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Text('Начать просмотр шагов'),
      ),
    ),
  ];

  List<Widget> _stepView() {
    final variant = _variant!;
    final step = variant.steps[_index!];
    return [
      _paragraph(variant.title),
      _paragraph(variant.scope),
      if (_finished) ...[
        _heading('Просмотр шагов завершён'),
        _paragraph(
          'Состояние и результат настройки прибора приложение не измеряет. '
          'Завершение просмотра не разрешает возврат автоматического управления.',
        ),
      ] else ...[
        Text(
          'Шаг ${_index! + 1} из ${variant.steps.length}',
          key: const ValueKey('procedure-step'),
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        _heading('Действие по источнику'),
        _paragraph(step.action),
        _heading('Ожидаемый результат'),
        _paragraph(step.expectedResult),
        _heading('Источник шага'),
        for (final evidence in step.evidence) ...[
          _paragraph('Проверено по источнику · ${evidence.locator}'),
          if (evidence.note != null) _paragraph(evidence.note!),
          if (widget.procedure.sourceByKey(evidence.sourceKey)
              case final source?)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: source.url == null
                  ? _paragraph('${source.title}\n${source.document ?? ''}')
                  : OutlinedButton(
                      onPressed: () => openSource(context, source.url!),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Text('${source.title}\nОткрыть источник'),
                      ),
                    ),
            ),
        ],
      ],
      const SizedBox(height: 16),
      OutlinedButton(
        key: const ValueKey('procedure-back'),
        onPressed: () => _change(() {
          if (_finished) {
            _finished = false;
          } else if (_index! > 0) {
            _index = _index! - 1;
          } else {
            _index = null;
            _confirmed = false;
          }
        }),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(
            _index == 0 && !_finished ? 'К условиям начала' : 'Назад',
          ),
        ),
      ),
      const SizedBox(height: 12),
      if (!_finished)
        FilledButton(
          key: const ValueKey('procedure-next'),
          onPressed: () => _change(() {
            if (_index! < variant.steps.length - 1) {
              _index = _index! + 1;
            } else {
              _finished = true;
            }
          }),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              _index == variant.steps.length - 1
                  ? 'Завершить просмотр'
                  : 'Следующий шаг',
            ),
          ),
        ),
      const SizedBox(height: 12),
      TextButton(
        key: const ValueKey('procedure-reset'),
        onPressed: () => _change(_reset),
        child: const Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: Text('Сбросить просмотр и выбрать исполнение'),
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Пошаговый просмотр')),
    body: SafeArea(
      child: SingleChildScrollView(
        controller: _scroll,
        padding: const EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  widget.procedure.title,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 16),
                _paragraph(_progressNotice),
                if (_index == null) ..._preparation() else ..._stepView(),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
