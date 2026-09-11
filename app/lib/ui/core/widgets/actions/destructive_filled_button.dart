import 'package:flutter/material.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';

/// Filled confirm action for delete / remove / clear dialogs.
///
/// Uses [HentaiColorScheme.destructive] / [HentaiColorScheme.onDestructive].
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
    final HentaiColorScheme h = Theme.of(context).colorScheme.hentai;
    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: h.destructive,
        foregroundColor: h.onDestructive,
        disabledBackgroundColor: h.destructive.withAlpha(
          _disabledBackgroundAlpha,
        ),
        disabledForegroundColor: h.onDestructive.withAlpha(
          _disabledForegroundAlpha,
        ),
      ),
      child: child,
    );
  }
}
