import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

Future<void> openSource(BuildContext context, String url) async {
  final uri = Uri.tryParse(url);
  try {
    if (uri != null &&
        uri.scheme == 'https' &&
        await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      return;
    }
  } catch (_) {
    // Native URL handlers can be unavailable on a device.
  }
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text(
        'Не удалось открыть документ. Проверьте браузер и подключение к интернету.',
      ),
    ),
  );
}
