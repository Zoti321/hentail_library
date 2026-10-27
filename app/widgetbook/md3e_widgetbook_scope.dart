import 'package:flutter/material.dart';
import 'package:hentai_library/md3e/patterns/desktop/md3e_desktop_shell_surfaces.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// Viewport chrome for MD3E Widgetbook use cases (theme comes from [md3eWidgetbookAppBuilder]).
class Md3eWidgetbookScope extends StatelessWidget {
  const Md3eWidgetbookScope({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final M3EColorScheme scheme = M3ETheme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: md3eLabBrowseCanvasColor(scheme),
      body: child,
    );
  }
}
