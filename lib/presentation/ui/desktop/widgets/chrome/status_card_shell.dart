import 'package:flutter/material.dart';
import 'package:hentai_library/presentation/theme/theme.dart';

class StatusCardShell extends StatelessWidget {
  const StatusCardShell({
    super.key,
    required this.padding,
    required this.borderRadius,
    required this.child,
  });

  final EdgeInsets padding;
  final double borderRadius;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: theme.colorScheme.hentai.borderSubtle),
      ),
      child: child,
    );
  }
}
