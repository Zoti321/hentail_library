import 'package:flutter/material.dart';

class ComicDetailShell extends StatelessWidget {
  const ComicDetailShell({
    super.key,
    required this.isNarrow,
    required this.child,
  });

  final bool isNarrow;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: isNarrow ? 16 : 24,
        vertical: 24,
      ),
      child: Center(
        child: child,
      ),
    );
  }
}

class ComicDetailCard extends StatelessWidget {
  const ComicDetailCard({
    super.key,
    required this.maxWidth,
    required this.child,
  });

  final double maxWidth;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: Material(
        color: cs.surface,
        elevation: 14,
        shadowColor: Colors.black.withOpacity(0.18),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: cs.outline.withAlpha(70)),
        ),
        clipBehavior: Clip.antiAlias,
        child: child,
      ),
    );
  }
}

