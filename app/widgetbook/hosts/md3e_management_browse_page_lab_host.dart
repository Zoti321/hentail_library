import 'package:flutter/material.dart';

import '../lab/pages/md3e_management_browse_page.dart';

import 'package:hentai_library/features/named_metadata/public.dart';

/// Lab / Widgetbook：preview facet chip 列表 + 新建实体（Dialog / 内联草稿 → 内存列表，不写 FRB）。
class ManagementBrowsePageLabHost extends StatefulWidget {
  const ManagementBrowsePageLabHost({
    super.key,
    this.initialFacet = ManagedNamedFacetKind.author,
    this.initialLabelsByFacet,
    this.createInteractionOverride,
    this.title,
  });

  final ManagedNamedFacetKind initialFacet;
  final Map<ManagedNamedFacetKind, List<String>>? initialLabelsByFacet;
  final ManagementCreateInteraction? createInteractionOverride;
  final String? title;

  @override
  State<ManagementBrowsePageLabHost> createState() =>
      _Md3eManagementBrowsePageLabHostState();
}

class _Md3eManagementBrowsePageLabHostState
    extends State<ManagementBrowsePageLabHost> {
  late ManagedNamedFacetKind _facet = widget.initialFacet;
  late final Map<ManagedNamedFacetKind, List<String>> _labelsByFacet =
      _copyLabelsByFacet(widget.initialLabelsByFacet);

  static Map<ManagedNamedFacetKind, List<String>> _copyLabelsByFacet(
    Map<ManagedNamedFacetKind, List<String>>? source,
  ) {
    if (source != null) {
      return <ManagedNamedFacetKind, List<String>>{
        for (final MapEntry<ManagedNamedFacetKind, List<String>> entry
            in source.entries)
          entry.key: List<String>.of(entry.value),
      };
    }
    return <ManagedNamedFacetKind, List<String>>{
      for (final ManagedNamedFacetKind facet in kManagedNamedFacetTabOrder)
        facet: ManagementBrowsePagePreviewData.sampleChipsFor(facet),
    };
  }

  void _addPreviewEntity(String name) {
    final List<String> list = _labelsByFacet[_facet]!;
    if (list.contains(name)) {
      return;
    }
    setState(() => list.add(name));
  }

  @override
  Widget build(BuildContext context) {
    final List<String> chips = _labelsByFacet[_facet]!;

    return ManagementBrowsePage(
      facet: _facet,
      facetCount: chips.length,
      chipLabels: chips,
      title: widget.title,
      createInteractionOverride: widget.createInteractionOverride,
      onEntityCreated: _addPreviewEntity,
      onFacetChanged: (ManagedNamedFacetKind value) {
        setState(() => _facet = value);
      },
    );
  }
}
