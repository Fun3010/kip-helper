import 'dart:io';
import 'package:window_manager/window_manager.dart';

/// Installed before the Windows window is shown, so even a close during a
/// pending save is routed through the active editor's decision.
class DesktopCloseGuard with WindowListener {
  DesktopCloseGuard._();
  static final instance = DesktopCloseGuard._();
  Future<bool> Function()? confirmClose;
  bool _handling = false;

  Future<void> initialize() async {
    if (!Platform.isWindows) return;
    await windowManager.ensureInitialized();
    windowManager.addListener(this);
    await windowManager.setPreventClose(true);
  }

  @override
  void onWindowClose() async {
    if (_handling) return;
    _handling = true;
    try {
      if (await (confirmClose?.call() ?? Future.value(true))) {
        await windowManager.destroy();
      }
    } finally {
      _handling = false;
    }
  }
}
