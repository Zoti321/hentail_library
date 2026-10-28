import 'package:flutter/material.dart';
import 'package:hentai_library/md3e/pages/md3e_management_browse_page.dart';
import 'package:hentai_library/md3e/patterns/management/md3e_management_create_interaction.dart';
import 'package:hentai_library/shared/domain/repositories/named_facet_management_repository.dart';

/// Lab / Widgetbook：preview facet chip 列表 + 新建实体（Dialog / 内联草稿 → 内存列表，不写 FRB）。
class Md3eManagementBrowsePageLabHost extends StatefulWidget {
  const Md3eManagementBrowsePageLabHost({
    super.key,
    this.initialFacet = ManagedNamedFacetKind.author,
    this.initialLabelsByFacet,
    this.createInteractionOverride,
    this.title,
  });

  final ManagedNamedFacetKind initialFacet;
  final Map<ManagedNamedFacetKind, List<String>>? initialLabelsByFacet;
  final Md3eManagementCreateInteraction? createInteractionOverride;
  final String? title;

  @override
  State<Md3eManagementBrowsePageLabHost> createState() =>
      _Md3eManagementBrowsePageLabHostState();
}

class _Md3eManagementBrowsePageLabHostState
    extends State<Md3eManagementBrowsePageLabHost> {
  late ManagedNamedFacetKind _facet = widget.initialFacet;
  late Map<ManagedNamedFacetKind, List<String>> _labelsByFacet =
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
        facet: Md3eManagementBrowsePagePreviewData.sampleChipsFor(facet),
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

    return Md3eManagementBrowsePage(
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
