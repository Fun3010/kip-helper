import 'package:flutter/material.dart';
import '../../services/text_settings.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key, required this.settings});
  final TextSettings settings;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: settings,
    builder: (context, _) => Scaffold(
      appBar: AppBar(title: const Text('Настройки')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'Размер текста',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            const Text(
              'Подберите удобный размер для этого устройства. Системный размер текста также учитывается.',
            ),
            const SizedBox(height: 16),
            Text(
              '${(settings.scale * 100).round()}%',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            Slider(
              value: settings.scale,
              min: 1,
              max: 1.5,
              divisions: 10,
              label: '${(settings.scale * 100).round()}%',
              semanticFormatterCallback: (value) =>
                  '${(value * 100).round()} процентов',
              onChanged: settings.ready ? settings.select : null,
            ),
            const Text(
              'Пример: проверьте исполнение прибора и руководство перед настройкой.',
              style: TextStyle(height: 1.5),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: settings.ready ? () => settings.select(1) : null,
              child: const Text('Сбросить к 100%'),
            ),
            if (settings.saveFailed) ...[
              const SizedBox(height: 16),
              const Text(
                'Не удалось сохранить размер текста. Он действует в текущем сеансе; попробуйте выбрать его ещё раз.',
              ),
            ],
          ],
        ),
      ),
    ),
  );
}
