import 'package:flutter/material.dart';
import 'package:hentai_library/md3e/widgets/settings/md3e_settings_section_header.dart';
import 'package:hentai_library/md3e/widgets/settings/md3e_split_list_group.dart';
import 'package:hentai_library/md3e/widgets/settings/md3e_tonal_surface.dart';

/// Titled block: header + tonal card or split list group.
class Md3eContentSection extends StatelessWidget {
  const Md3eContentSection({
    super.key,
    required this.title,
    required Widget child,
    this.description,
    this.padding = const EdgeInsets.all(16),
    this.titleTrailing,
    // Single-field ctor: public `child` maps to private storage (API stays `child:`).
    // ignore: prefer_initializing_formals
  })  : _child = child,
        _children = null;

  const Md3eContentSection.group({
    super.key,
    required this.title,
    required List<Widget> children,
    this.description,
    this.titleTrailing,
    // ignore: prefer_initializing_formals
  })  : _children = children,
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
          child: Md3eSettingsSectionHeader(
            title: Text(title),
            description: description == null ? null : Text(description!),
            trailing: titleTrailing,
          ),
        ),
        if (_children != null)
          Md3eSplitListGroup(children: _children)
        else
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Md3eTonalSurface(padding: padding, child: _child!),
          ),
      ],
    );
  }
}
