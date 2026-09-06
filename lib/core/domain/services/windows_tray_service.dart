import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

class WindowsTrayService with TrayListener, WindowListener {
  static final WindowsTrayService instance = WindowsTrayService._();
  WindowsTrayService._();

  bool _initialized = false;

  Future<void> init({bool startSilent = false}) async {
    if (kIsWeb || !Platform.isWindows || _initialized) return;
    _initialized = true;

    try {
      await windowManager.ensureInitialized();
      trayManager.addListener(this);
      windowManager.addListener(this);

      // Prevent default termination when clicking 'X' button
      await windowManager.setPreventClose(true);

      // Setup system tray icon (visible under taskbar ^ hidden icons)
      await trayManager.setIcon(
        'assets/images/app_icon.png',
      );
      await trayManager.setToolTip('FocusFlow');

      final menu = Menu(
        items: [
          MenuItem(
            key: 'show_window',
            label: 'Open FocusFlow',
          ),
          MenuItem.separator(),
          MenuItem(
            key: 'exit_app',
            label: 'Exit',
          ),
        ],
      );
      await trayManager.setContextMenu(menu);

      // If launched silently (e.g. from Startup), hide the window immediately
      if (startSilent) {
        await windowManager.hide();
      }
    } catch (e) {
      debugPrint('WindowsTrayService init error: $e');
    }
  }

  @override
  void onWindowClose() async {
    // When user clicks 'X', hide the window to system tray instead of killing the app
    final isPreventClose = await windowManager.isPreventClose();
    if (isPreventClose) {
      await windowManager.hide();
    }
  }

  @override
  void onTrayIconMouseDown() async {
    // Left-click on tray icon restores and brings window to focus
    await showApp();
  }

  @override
  void onTrayIconRightMouseDown() async {
    // Right-click opens context menu
    await trayManager.popUpContextMenu();
  }

  @override
  void onTrayMenuItemClick(MenuItem menuItem) async {
    if (menuItem.key == 'show_window') {
      await showApp();
    } else if (menuItem.key == 'exit_app') {
      await exitApp();
    }
  }

  Future<void> showApp() async {
    try {
      final isVisible = await windowManager.isVisible();
      if (!isVisible) {
        await windowManager.show();
      }
      final isMinimized = await windowManager.isMinimized();
      if (isMinimized) {
        await windowManager.restore();
      }
      await windowManager.focus();
    } catch (e) {
      debugPrint('Error showing window: $e');
    }
  }

  Future<void> exitApp() async {
    try {
      await windowManager.setPreventClose(false);
      await windowManager.destroy();
      exit(0);
    } catch (e) {
      debugPrint('Error exiting window: $e');
      exit(0);
    }
  }

  /// Check if Windows startup registry key exists
  static Future<bool> isAutoStartEnabled() async {
    if (kIsWeb || !Platform.isWindows) return false;
    try {
      final res = await Process.run('reg', [
        'query',
        r'HKCU\Software\Microsoft\Windows\CurrentVersion\Run',
        '/v',
        'FocusFlow',
      ]);
      return res.exitCode == 0;
    } catch (_) {
      return false;
    }
  }

  /// Enable or disable Windows auto-start via registry key
  static Future<void> setAutoStart(bool enable) async {
    if (kIsWeb || !Platform.isWindows) return;
    try {
      if (enable) {
        final exePath = Platform.resolvedExecutable;
        await Process.run('reg', [
          'add',
          r'HKCU\Software\Microsoft\Windows\CurrentVersion\Run',
          '/v',
          'FocusFlow',
          '/t',
          'REG_SZ',
          '/d',
          '"$exePath" --silent',
          '/f',
        ]);
        debugPrint('Windows auto-start enabled in registry');
      } else {
        await Process.run('reg', [
          'delete',
          r'HKCU\Software\Microsoft\Windows\CurrentVersion\Run',
          '/v',
          'FocusFlow',
          '/f',
        ]);
        debugPrint('Windows auto-start removed from registry');
      }
    } catch (e) {
      debugPrint('Error modifying auto-start registry: $e');
    }
  }
}
