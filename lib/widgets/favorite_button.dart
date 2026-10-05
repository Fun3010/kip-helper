import 'package:flutter/material.dart';

import '../models/guide.dart';
import '../services/quick_access.dart';

class FavoriteButton extends StatelessWidget {
  const FavoriteButton({
    super.key,
    required this.guide,
    required this.controller,
  });

  final InstrumentGuide guide;
  final QuickAccessController controller;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) {
      final favorite = controller.isFavorite(guide.id);
      return IconButton(
        tooltip: favorite
            ? 'Удалить ${guide.title} из избранного'
            : 'Добавить ${guide.title} в избранное',
        isSelected: favorite,
        onPressed: () => controller.toggleFavorite(guide.id),
        icon: const Icon(Icons.star_border),
        selectedIcon: const Icon(Icons.star),
        color: Theme.of(context).colorScheme.primary,
      );
    },
  );
}
