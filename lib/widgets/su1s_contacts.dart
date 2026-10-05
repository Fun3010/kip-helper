import 'package:flutter/material.dart';

/// Logical contact states from RGAU.407834.006, not physical terminal placement.
class Su1sContacts extends StatefulWidget {
  const Su1sContacts({super.key});
  @override
  State<Su1sContacts> createState() => _Su1sContactsState();
}

class _Su1sContactsState extends State<Su1sContacts> {
  bool _wet = false;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const Text(
        'Логическая схема исправного прибора с питанием. Номера соответствуют РГАУ.407834.006 РЭ; физическое расположение смотрите на крышке.',
        style: TextStyle(height: 1.5),
      ),
      SwitchListTile.adaptive(
        contentPadding: EdgeInsets.zero,
        title: Text(_wet ? 'Среда достигла уровня' : 'Среда ниже уровня'),
        subtitle: const Text('Переключатель иллюстрирует состояние контактов'),
        value: _wet,
        onChanged: (value) => setState(() => _wet = value),
      ),
      Semantics(
        label: _wet
            ? 'Контакты 1 и 2 замкнуты, 1 и 3 разомкнуты'
            : 'Контакты 1 и 3 замкнуты, 1 и 2 разомкнуты',
        child: SizedBox(
          height: 120,
          child: Row(
            children: [
              const Text('1\nОбщий', textAlign: TextAlign.center),
              Expanded(
                child: CustomPaint(
                  painter: _RelayPainter(
                    wet: _wet,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  size: const Size(double.infinity, 120),
                ),
              ),
              const Column(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [Text('2 · НР'), Text('3 · НЗ')],
              ),
            ],
          ),
        ),
      ),
      const Divider(height: 28),
      _contact(context, '4 — 5', 'Исправность · замкнуты'),
      _contact(context, '6 / 7', '+24 В / минус питания'),
      _contact(context, '8 / 9', 'Внутреннее заземление'),
      _contact(context, '10 / 11', 'Обогрев · питание по РЭ'),
      const SizedBox(height: 8),
      const Text(
        'Прозвонка контактов — при отсутствии внешнего напряжения в измеряемой цепи.',
        style: TextStyle(height: 1.5),
      ),
    ],
  );
  Widget _contact(BuildContext context, String number, String label) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 70,
          child: Text(
            number,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
        Expanded(child: Text(label)),
      ],
    ),
  );
}

class _RelayPainter extends CustomPainter {
  const _RelayPainter({required this.wet, required this.color});
  final bool wet;
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;
    final pivot = Offset(size.width * .3, 60);
    final upper = Offset(size.width * .72, 30);
    final lower = Offset(size.width * .72, 90);
    canvas.drawLine(const Offset(8, 60), pivot, paint);
    canvas.drawLine(upper, Offset(size.width - 8, 30), paint);
    canvas.drawLine(lower, Offset(size.width - 8, 90), paint);
    canvas.drawLine(pivot, wet ? upper : lower, paint);
    for (final point in [pivot, upper, lower]) {
      canvas.drawCircle(point, 4, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _RelayPainter oldDelegate) =>
      wet != oldDelegate.wet || color != oldDelegate.color;
}
