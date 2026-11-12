import 'package:flutter/material.dart';

export 'package:hentai_library/shared/ui/widgets/settings/settings_section.dart';

/// Scrollable detail column with optional max width (Kazumi-style ~1000dp).
class SettingsList extends StatelessWidget {
  const SettingsList({
    super.key,
    required this.sections,
    this.maxWidth = 1000,
    this.padding = const EdgeInsets.symmetric(vertical: 12),
  });

  final List<Widget> sections;
  final double maxWidth;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: padding,
      itemCount: sections.length,
      itemBuilder: (BuildContext context, int index) {
        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: sections[index],
          ),
        );
      },
    );
  }
}
