import 'package:flutter/material.dart';
import '../domain/calculations.dart';

class NumberInput extends StatelessWidget {
  const NumberInput({
    super.key,
    required this.controller,
    required this.label,
    required this.onChanged,
    this.suffix,
  });
  final TextEditingController controller;
  final String label;
  final VoidCallback onChanged;
  final String? suffix;
  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    keyboardType: const TextInputType.numberWithOptions(
      decimal: true,
      signed: true,
    ),
    decoration: InputDecoration(labelText: label, suffixText: suffix),
    onChanged: (_) => onChanged(),
  );
}

class CalculationResult extends StatelessWidget {
  const CalculationResult({
    super.key,
    required this.calculate,
    required this.unit,
    this.title = 'Результат',
  });
  final double Function() calculate;
  final String unit;
  final String title;
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    String value;
    var invalid = false;
    try {
      value = formatNumber(calculate());
    } on CalculationException catch (error) {
      value = error.message;
      invalid = true;
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: invalid ? colors.errorContainer : colors.primaryContainer,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: invalid
                  ? colors.onErrorContainer
                  : colors.onPrimaryContainer,
            ),
          ),
          const SizedBox(height: 12),
          Semantics(
            liveRegion: true,
            child: SelectableText(
              invalid ? value : '$value $unit',
              style: TextStyle(
                fontSize: invalid ? 17 : 32,
                fontWeight: FontWeight.w700,
                color: invalid
                    ? colors.onErrorContainer
                    : colors.onPrimaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CalculatorScaffold extends StatelessWidget {
  const CalculatorScaffold({
    super.key,
    required this.title,
    required this.children,
  });
  final String title;
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(title)),
    body: SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            children: [
              for (final child in children)
                Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: child,
                ),
            ],
          ),
        ),
      ),
    ),
  );
}

class HelpNote extends StatelessWidget {
  const HelpNote(this.text, {super.key});
  final String text;
  @override
  Widget build(BuildContext context) => Text(
    text,
    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
      color: Theme.of(context).colorScheme.onSurfaceVariant,
      height: 1.5,
    ),
  );
}
