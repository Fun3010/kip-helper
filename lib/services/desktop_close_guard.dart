import 'dart:io';
import 'package:window_manager/window_manager.dart';

/// Installed before the Windows window is shown, so even a close during a
/// pending save is routed through the active editor's decision.
class DesktopCloseGuard with WindowListener {
  DesktopCloseGuard._();
  static final instance = DesktopCloseGuard._();
  Future<bool> Function()? confirmClose;
  bool _handling = false;
  bool _allowClose = false;

  Future<void> initialize() async {
    if (!Platform.isWindows) return;
    await windowManager.ensureInitialized();
    windowManager.addListener(this);
    await windowManager.setPreventClose(true);
  }

  @override
  void onWindowClose() async {
    if (_handling || _allowClose) return;
    _handling = true;
    try {
      if (await (confirmClose?.call() ?? Future.value(true))) {
        // Let the runner handle WM_CLOSE/WM_DESTROY in its normal order.
        // window_manager.destroy() posts WM_QUIT while the window is alive.
        _allowClose = true;
        try {
          await windowManager.setPreventClose(false);
          await windowManager.close();
        } catch (error, stack) {
          try {
            await windowManager.setPreventClose(true);
          } catch (_) {
            // Preserve the original close failure if restoring the veto fails.
          }
          _allowClose = false;
          Error.throwWithStackTrace(error, stack);
        }
      }
    } finally {
      _handling = false;
    }
  }
}
