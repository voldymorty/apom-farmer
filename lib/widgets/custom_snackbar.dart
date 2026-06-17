import 'dart:async';

import 'package:client/global/colortheme.dart';
import 'package:flutter/material.dart';

/// Custom SnackBar for consistent look across the app
///
/// Usage examples:
/// CustomSnackBar.show(context, "Success message", isSuccess: true);
/// CustomSnackBar.show(context, "Error occurred", isError: true);
/// CustomSnackBar.show(context, "Info text", duration: const Duration(seconds: 4));
class CustomSnackBar {
  static OverlayEntry? _currentEntry;
  static Timer? _dismissTimer;

  static void show(
    BuildContext context,
    String message, {
    bool isSuccess = false,
    bool isError = false,
    bool isInfo = false,
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
  }) {
    Color backgroundColor = AppColors.textSecondary; // default neutral
    IconData? icon;

    if (isSuccess) {
      backgroundColor = AppColors.primaryGreen;
      icon = Icons.check_circle_outline_rounded;
    } else if (isError) {
      backgroundColor = AppColors.error;
      icon = Icons.error_outline_rounded;
    } else if (isInfo) {
      backgroundColor = AppColors.primaryGreen.withValues(alpha: 0.9);
      icon = Icons.info_outline_rounded;
    }

    if (!context.mounted) return;

    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;

    _removeCurrent();

    final topOffset = MediaQuery.of(context).viewPadding.top + 12;
    _currentEntry = OverlayEntry(
      builder:
          (_) => _TopSnackBarBanner(
            message: message,
            icon: icon,
            backgroundColor: backgroundColor,
            action: action,
            topOffset: topOffset,
            onDismissed: _removeCurrent,
          ),
    );

    overlay.insert(_currentEntry!);
    _dismissTimer = Timer(duration, _removeCurrent);
  }

  static void _removeCurrent() {
    _dismissTimer?.cancel();
    _dismissTimer = null;
    _currentEntry?.remove();
    _currentEntry = null;
  }

  // Quick success helper
  static void success(
    BuildContext context,
    String message, {
    Duration? duration,
  }) {
    show(
      context,
      message,
      isSuccess: true,
      duration: duration ?? const Duration(seconds: 3),
    );
  }

  // Quick error helper
  static void error(
    BuildContext context,
    String message, {
    Duration? duration,
  }) {
    show(
      context,
      message,
      isError: true,
      duration: duration ?? const Duration(seconds: 4),
    );
  }

  // Quick info helper
  static void info(
    BuildContext context,
    String message, {
    Duration? duration,
    SnackBarAction? action,
  }) {
    show(
      context,
      message,
      isInfo: true,
      duration: duration ?? const Duration(seconds: 3),
      action: action,
    );
  }
}

class _TopSnackBarBanner extends StatelessWidget {
  final String message;
  final IconData? icon;
  final Color backgroundColor;
  final SnackBarAction? action;
  final double topOffset;
  final VoidCallback onDismissed;

  const _TopSnackBarBanner({
    required this.message,
    required this.icon,
    required this.backgroundColor,
    required this.action,
    required this.topOffset,
    required this.onDismissed,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: topOffset,
      left: 16,
      right: 16,
      child: Material(
        color: Colors.transparent,
        child: Dismissible(
          key: ValueKey('${message}_${DateTime.now().microsecondsSinceEpoch}'),
          direction: DismissDirection.horizontal,
          onDismissed: (_) => onDismissed(),
          child: Container(
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x26000000),
                  blurRadius: 12,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, color: Colors.white, size: 24),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Text(
                    message,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                if (action != null)
                  TextButton(
                    onPressed: () {
                      action!.onPressed();
                      onDismissed();
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: action!.textColor ?? Colors.white,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    child: Text(
                      action!.label,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
