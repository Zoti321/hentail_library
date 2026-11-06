import 'package:flutter/material.dart';
import 'package:hentai_library/shared/ui/widgets/settings/settings_section_header.dart';
import 'package:hentai_library/shared/ui/widgets/settings/split_list_group.dart';
import 'package:hentai_library/shared/ui/widgets/settings/tonal_surface.dart';

/// Titled block: header + tonal card or split list group.
class ContentSection extends StatelessWidget {
  const ContentSection({
    super.key,
    required this.title,
    required Widget child,
    this.description,
    this.padding = const EdgeInsets.all(16),
    this.titleTrailing,
    // Single-field ctor: public `child` maps to private storage (API stays `child:`).
    // ignore: prefer_initializing_formals
  }) : _child = child,
       _children = null;

  const ContentSection.group({
    super.key,
    required this.title,
    required List<Widget> children,
    this.description,
    this.titleTrailing,
    // ignore: prefer_initializing_formals
  }) : _children = children,
       _child = null,
       padding = EdgeInsets.zero;

  final String title;
  final String? description;
  final Widget? titleTrailing;
  final EdgeInsetsGeometry padding;
  final Widget? _child;
  final List<Widget>? _children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: SettingsSectionHeader(
            title: Text(title),
            description: description == null ? null : Text(description!),
            trailing: titleTrailing,
          ),
        ),
        if (_children != null)
          SplitListGroup(children: _children)
        else
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TonalSurface(padding: padding, child: _child!),
          ),
      ],
    );
  }
}
