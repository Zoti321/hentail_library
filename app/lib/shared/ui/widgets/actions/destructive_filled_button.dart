import 'package:flutter/material.dart';

/// Filled confirm action for delete / remove / clear dialogs.
///
/// Uses [ColorScheme.error] / [ColorScheme.onError] (M3E danger maps to error).
/// When disabled (`onPressed == null`), keeps the destructive hue at reduced
/// opacity instead of falling back to the default grey disabled fill.
class DestructiveFilledButton extends StatelessWidget {
  const DestructiveFilledButton({
    super.key,
    required this.onPressed,
    required this.child,
  });

  final VoidCallback? onPressed;
  final Widget child;

  static const int _disabledBackgroundAlpha = 102; // ~0.4
  static const int _disabledForegroundAlpha = 153; // ~0.6

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: cs.error,
        foregroundColor: cs.onError,
        disabledBackgroundColor: cs.error.withAlpha(_disabledBackgroundAlpha),
        disabledForegroundColor: cs.onError.withAlpha(_disabledForegroundAlpha),
      ),
      child: child,
    );
  }
}
