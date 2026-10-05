import 'package:flutter/material.dart';

import '../services/quick_access.dart';

class QuickAccessNotice extends StatelessWidget {
  const QuickAccessNotice({super.key, required this.controller});

  final QuickAccessController controller;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) => controller.saveFailed
        ? Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Semantics(
              liveRegion: true,
              child: const Text(
                'Не удалось сохранить быстрый доступ. Изменения могут потеряться после закрытия приложения.',
              ),
            ),
          )
        : const SizedBox.shrink(),
  );
}
