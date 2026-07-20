import 'package:flutter/material.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';

class MetadataPanelListCard extends StatelessWidget {
  const MetadataPanelListCard({
    required this.radius,
    required this.child,
    super.key,
  });

  final double radius;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: colorScheme.hentai.borderSubtle),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: child,
      ),
    );
  }
}
