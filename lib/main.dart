import 'package:flutter/material.dart';
import 'app.dart';
import 'services/desktop_close_guard.dart';

export 'app.dart' show KipHelperApp;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DesktopCloseGuard.instance.initialize();
  runApp(const KipHelperApp());
}
