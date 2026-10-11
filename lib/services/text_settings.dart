import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TextSettings extends ChangeNotifier {
  static const storageKey = 'kip.textScale.v1';
  double scale = 1;
  bool ready = false;
  bool saveFailed = false;
  bool _disposed = false;
  Future<void> _writes = Future.value();

  Future<void> load() async {
    try {
      final stored = (await SharedPreferences.getInstance()).get(storageKey);
      if (stored is double && stored.isFinite && stored >= 1 && stored <= 1.5) {
        scale = stored;
      }
    } catch (_) {
      saveFailed = true;
    }
    ready = true;
    _notify();
  }

  void select(double value) {
    if (!ready || !value.isFinite || value < 1 || value > 1.5) return;
    scale = value;
    _notify();
    _writes = _writes.then((_) async {
      try {
        final prefs = await SharedPreferences.getInstance();
        saveFailed = !await prefs.setDouble(storageKey, value);
      } catch (_) {
        saveFailed = true;
      }
      _notify();
    });
  }

  TextScaler apply(TextScaler system) =>
      scale == 1 ? system : _CombinedTextScaler(system, scale);

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

class _CombinedTextScaler extends TextScaler {
  const _CombinedTextScaler(this.system, this.factor);
  final TextScaler system;
  final double factor;
  @override
  double scale(double fontSize) => system.scale(fontSize) * factor;
  @override
  double get textScaleFactor => scale(14) / 14;
}

class TextSettingsScope extends InheritedNotifier<TextSettings> {
  const TextSettingsScope({
    super.key,
    required TextSettings settings,
    required super.child,
  }) : super(notifier: settings);
  static TextSettings of(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<TextSettingsScope>()!
      .notifier!;
}
