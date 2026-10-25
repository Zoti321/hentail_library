import 'package:flutter/material.dart';
import 'package:hentai_library/md3e/interaction/md3e_pointer_target.dart';

/// MD3E-styled primary action (Material 3 [FilledButton] with min touch target).
class Md3eFilledButton extends StatelessWidget {
  const Md3eFilledButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final Widget button = icon == null
        ? FilledButton(onPressed: onPressed, child: Text(label))
        : FilledButton.icon(
            onPressed: onPressed,
            icon: Icon(icon),
            label: Text(label),
          );
    return Md3ePointerTarget(child: button);
  }
}
