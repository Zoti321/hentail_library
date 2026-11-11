import 'dart:math' as math;

import 'package:hentai_library/shared/domain/models/value_objects/author_ref.dart';

import 'package:flutter/material.dart';
import 'package:hentai_library/design-system/design_system.dart';
import 'package:hentai_library/shared/ui/layout/comic_detail_page_metrics.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/features/comic/presentation/views/comic_detail/comic_detail_view_object.dart';
import 'package:hentai_library/features/comic/presentation/patterns/comic_detail/comic_detail_info_row.dart';
import 'package:hentai_library/shared/ui/patterns/shared/detail_metadata_chip_rows.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_symbols_icons/symbols.dart';

/// 元数据区：Parody → Author → Character → Tag + 可折叠资源 KV 行。
class ComicDetailMetadataSection extends StatelessWidget {
  const ComicDetailMetadataSection({
    super.key,
    required this.entry,
    this.onChipTap,
    this.onAuthorTap,
  });

  final ComicDetailViewObject entry;
  final ValueChanged<String>? onChipTap;
  final ValueChanged<AuthorRef>? onAuthorTap;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final WindowSizeClass sizeClass = windowSizeClassOf(context);

    final Widget chipBlock = DetailMetadataChipRows(
      parodies: entry.parodies,
      authors: entry.authors,
      characters: entry.characters,
      tags: entry.tags,
      onChipTap: onChipTap,
      onAuthorTap: onAuthorTap,
    );

    final List<Widget> infoRows = <Widget>[
      ComicDetailInfoRow(
        label: l10n.comicDetailResourceFormat,
        value: entry.resourceFormat,
      ),
      ComicDetailInfoRow(
        label: l10n.comicDetailResourceSize,
        value: entry.resourceSizeLabel,
      ),
      ComicDetailInfoRow(
        label: l10n.comicDetailResourcePath,
        value: entry.resourcePath,
        tooltip: entry.resourcePath,
      ),
      if (entry.addedAtLabel != null)
        ComicDetailInfoRow(
          label: l10n.comicDetailAddedAt,
          value: entry.addedAtLabel!,
        ),
      if (entry.updatedAtLabel != null)
        ComicDetailInfoRow(
          label: l10n.comicDetailUpdatedAt,
          value: entry.updatedAtLabel!,
        ),
    ];

    final double tagsToResourceGap =
        ComicDetailPageMetrics.metadataTagsToResourceSpacing(sizeClass);
    final bool hasChips =
        entry.parodies.isNotEmpty ||
        entry.authors.isNotEmpty ||
        entry.characters.isNotEmpty ||
        entry.tags.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        chipBlock,
        if (hasChips && infoRows.isNotEmpty)
          SizedBox(height: tagsToResourceGap),
        if (infoRows.isNotEmpty)
          _ComicDetailResourceInfoExpansion(rows: infoRows),
      ],
    );
  }
}

class _ComicDetailResourceInfoExpansion extends StatefulWidget {
  const _ComicDetailResourceInfoExpansion({required this.rows});

  final List<Widget> rows;

  @override
  State<_ComicDetailResourceInfoExpansion> createState() =>
      _ComicDetailResourceInfoExpansionState();
}

class _ComicDetailResourceInfoExpansionState
    extends State<_ComicDetailResourceInfoExpansion> {
  bool _expanded = false;

  void _toggle() {
    setState(() => _expanded = !_expanded);
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final M3EThemeData theme = M3ETheme.of(context);
    final M3EColorScheme scheme = theme.colorScheme;
    final M3ETypeScale type = theme.typeScale;
    final M3ESpacing spacing = theme.spacing;
    final Color foreground = scheme.onSurfaceVariant;
    final String title = l10n.comicDetailResourceInfo;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Semantics(
          button: true,
          expanded: _expanded,
          label: title,
          child: M3ETappable(
            onTap: _toggle,
            trackHover: true,
            semanticLabel: null,
            builder: (BuildContext context, M3EInteractionState state) {
              return Padding(
                padding: EdgeInsets.symmetric(vertical: spacing.sm),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: type.labelLarge.copyWith(
                          fontWeight: FontWeight.w600,
                          color: foreground,
                        ),
                      ),
                    ),
                    SpringValue(
                      value: _expanded ? 0.5 : 0,
                      builder:
                          (BuildContext context, double turns, Widget? child) {
                            return Transform.rotate(
                              angle: turns * 2 * math.pi,
                              child: child,
                            );
                          },
                      child: Icon(
                        Symbols.expand_more,
                        size: 24,
                        color: foreground,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        SpringSize(
          expanded: _expanded,
          child: Padding(
            padding: EdgeInsets.only(top: spacing.xs),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: spacing.md,
              children: widget.rows,
            ),
          ),
        ),
      ],
    );
  }
}
