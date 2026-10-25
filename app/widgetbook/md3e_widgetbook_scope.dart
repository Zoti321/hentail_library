import 'package:flutter/material.dart';
import 'package:hentai_library/md3e/theme/md3e_theme.dart';
import 'package:material_expressive/theme.dart';

/// Lab catalog shell: fixed seed, MiSans, [Scaffold] for viewport layout.
class Md3eWidgetbookScope extends StatelessWidget {
  const Md3eWidgetbookScope({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final ExpressiveThemeData expressive = buildMd3eExpressiveThemeData();
    final Brightness brightness = MediaQuery.platformBrightnessOf(context);
    final ThemeData theme = buildMd3eTheme(brightness, expressive: expressive);
    return Md3eThemeScope(
      expressive: expressive,
      child: Theme(
        data: theme,
        child: Scaffold(
          body: child,
        ),
      ),
    );
  }
}
