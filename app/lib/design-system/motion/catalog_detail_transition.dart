import 'package:flutter/material.dart';

const Duration kCatalogDetailPageTransitionDuration = Duration(
  milliseconds: 300,
);

/// Fade from the first frame so cover Heroes land on visible content.
class CatalogDetailTransition extends StatelessWidget {
  const CatalogDetailTransition({
    super.key,
    required this.animation,
    required this.child,
  });

  final Animation<double> animation;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return child;
    return FadeTransition(
      opacity: CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      ),
      child: child,
    );
  }
}
