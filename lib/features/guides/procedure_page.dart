import 'package:flutter/material.dart';

import '../../models/guide_procedure.dart';
import '../../widgets/guide_evidence.dart';
import '../../widgets/guide_illustration.dart';
import '../../data/sipart_field.dart';

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

  Future<void> _showSteps() async {
    if (_index == null || _variant == null || !_confirmed) return;
    final selected = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * .75,
          child: ListView(
            children: [
              const ListTile(
                title: Text('Все шаги · переход отмечает просмотр'),
              ),
              for (final (i, step) in _variant!.steps.indexed)
                ListTile(
                  leading: Text('${i + 1}'),
                  title: Text(step.title ?? 'Шаг ${i + 1}'),
                  selected: i == _index,
                  onTap: () => Navigator.pop(context, i),
                ),
            ],
          ),
        ),
      ),
    );
    if (!mounted || selected == null) return;
    _change(() {
      _index = selected;
      _finished = false;
    });
  }

  void _showCancellation() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * .75,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sipartCancel.title!,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                Text(sipartCancel.action),
                const SizedBox(height: 12),
                Text(sipartCancel.expectedResult),
                for (final evidence in sipartCancel.evidence)
                  GuideEvidenceCard(
                    evidence: evidence,
                    source: widget.procedure.sourceByKey(evidence.sourceKey),
                  ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Закрыть памятку'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _stepView() {
    final variant = _variant!;
    final step = variant.steps[_index!];
    return [
      Text(variant.title, style: Theme.of(context).textTheme.labelLarge),
      const SizedBox(height: 8),
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
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(value: (_index! + 1) / variant.steps.length),
        _heading(step.title ?? 'Действие по источнику'),
        _paragraph(step.action),
        if (step.control != null)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    step.control!,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (step.hold != null) ...[
                    const SizedBox(height: 6),
                    Text(step.hold!),
                  ],
                ],
              ),
            ),
          ),
        if (step.illustration != null)
          GuideIllustrationCard(
            illustration: step.illustration!,
            compact: true,
          ),
        _heading('Ожидаемый результат'),
        if (step.display != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              step.display!,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Theme.of(context).colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        if (step.displayAsset != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.all(8),
              child: Image.asset(
                step.displayAsset!,
                height: 105,
                width: double.infinity,
                fit: BoxFit.contain,
                semanticLabel: 'Дисплей из РЭ: ${step.display}',
              ),
            ),
          ),
        _paragraph(step.expectedResult),
        _heading('Источник шага'),
        for (final evidence in step.evidence)
          GuideEvidenceCard(
            evidence: evidence,
            source: widget.procedure.sourceByKey(evidence.sourceKey),
          ),
      ],
      if (widget.procedure.guideId == 'sipart')
        OutlinedButton.icon(
          onPressed: _showCancellation,
          icon: const Icon(Icons.info_outline),
          label: const Text('Как прервать на приборе'),
        ),
      ExpansionTile(
        title: const Text('Исполнение и условия'),
        children: [
          Text(variant.scope),
          for (final p in widget.procedure.prerequisites) _paragraph(p),
          for (final p in variant.prerequisites) _paragraph(p),
        ],
      ),
      const SizedBox(height: 12),
      Text(_progressNotice, style: Theme.of(context).textTheme.bodySmall),
      TextButton(
        key: const ValueKey('procedure-reset'),
        onPressed: () => _change(_reset),
        child: const Text('Сбросить просмотр и выбрать исполнение'),
      ),
    ];
  }

  Widget _navigation() => SafeArea(
    child: ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * .36,
      ),
      child: Material(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: OutlinedButton(
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
                      child: const Text('Назад'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  if (!_finished)
                    Expanded(
                      child: FilledButton(
                        key: const ValueKey('procedure-next'),
                        onPressed: () => _change(() {
                          if (_index! < _variant!.steps.length - 1) {
                            _index = _index! + 1;
                          } else {
                            _finished = true;
                          }
                        }),
                        child: Text(
                          _index == _variant!.steps.length - 1
                              ? 'Завершить'
                              : 'Далее',
                        ),
                      ),
                    ),
                ],
              ),
              TextButton(onPressed: _showSteps, child: const Text('Все шаги')),
            ],
          ),
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(
        widget.procedure.guideId == 'sipart'
            ? 'SIPART PS2 · по шагам'
            : 'Пошаговый просмотр',
      ),
    ),
    bottomNavigationBar: _index == null ? null : _navigation(),
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
                if (_index == null) ...[
                  Text(
                    widget.procedure.title,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 16),
                  _paragraph(_progressNotice),
                  ..._preparation(),
                ] else
                  ..._stepView(),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
