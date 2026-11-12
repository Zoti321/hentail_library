import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:hentai_library/design-system/components/menu/anchored_menu.dart';
import 'package:hentai_library/shared/ui/widgets/catalog/comic_catalog_card_shell.dart';
import 'package:hentai_library/shared/ui/widgets/catalog/comic_card.dart';
import 'package:hentai_library/shared/ui/widgets/catalog/cover_read_progress_strip.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// Middle dot between author and page label (e.g. `作者名 · 128 页`).
const String kComicListItemMetaSeparator = ' · ';

/// List-row cover width (2:3, same media treatment as [ComicCard]).
const double kComicListItemCoverWidth = 80;

/// Derived list cover height.
double get kComicListItemCoverHeight => kComicListItemCoverWidth * 3 / 2;

/// Vertical padding inside the shared catalog card shell.
const double kComicListItemVerticalPadding = 10;

/// Minimum row height (cover + vertical insets).
double get kComicListItemMinHeight =>
    kComicListItemCoverHeight + kComicListItemVerticalPadding * 2;

/// Max width of the read-progress bar when shown under meta (list-only layout).
const double kComicListItemProgressMaxWidth = 160;

/// Gap between meta line and list progress bar.
const double kComicListItemProgressTopGap = 6;

/// Key for list-row progress strip in tests (under title/meta, not on cover).
const Key kComicListItemInfoProgressKey = Key('_comic_list_item_info_progress');

/// One action in the trailing overflow ([Icons.more_vert]) menu.
class ComicListMoreMenuEntry {
  const ComicListMoreMenuEntry({required this.label, this.onSelected});

  final String label;
  final VoidCallback? onSelected;
}

/// Pins M3 list-item visuals for Widgetbook; not for production lists.
enum ComicListItemVisualState {
  normal,
  hovered,
  focused,
  pressed,
  disabled,
  selectionUnselected,
  selectionSelected,
}

/// Catalog list comic item: same [ComicCatalogCardShell] as [ComicCard],
/// horizontal cover + text + optional trailing menu.
class ComicListItem extends StatelessWidget {
  const ComicListItem({
    super.key,
    required this.title,
    required this.cover,
    this.author,
    this.pageLabel,
    this.onTap,
    this.enabled = true,
    this.visualState,
    this.selectionMode = false,
    this.selected = false,
    this.onSelectionChanged,
    this.readProgress,
    this.moreMenuEntries = const <ComicListMoreMenuEntry>[],
  }) : assert(
         readProgress == null || (readProgress >= 0 && readProgress <= 1),
         'readProgress must be between 0 and 1',
       );

  static double itemExtent() => kComicListItemMinHeight;

  static String? metaLine({String? author, String? pageLabel}) {
    final List<String> parts = <String>[];
    final String? trimmedAuthor = author?.trim();
    final String? trimmedPage = pageLabel?.trim();
    if (trimmedAuthor != null && trimmedAuthor.isNotEmpty) {
      parts.add(trimmedAuthor);
    }
    if (trimmedPage != null && trimmedPage.isNotEmpty) {
      parts.add(trimmedPage);
    }
    if (parts.isEmpty) {
      return null;
    }
    return parts.join(kComicListItemMetaSeparator);
  }

  static double infoProgressWidthFor(double availableWidth) {
    if (availableWidth <= 0) {
      return 0;
    }
    return math.min(availableWidth, kComicListItemProgressMaxWidth);
  }

  final String title;
  final String? author;
  final String? pageLabel;
  final Widget cover;
  final VoidCallback? onTap;

  final bool selectionMode;
  final bool selected;
  final ValueChanged<bool>? onSelectionChanged;

  final bool enabled;
  final ComicListItemVisualState? visualState;

  final double? readProgress;
  final List<ComicListMoreMenuEntry> moreMenuEntries;

  @override
  Widget build(BuildContext context) {
    final M3EThemeData theme = M3ETheme.of(context);
    final M3EColorScheme scheme = theme.colorScheme;
    final M3ETypeScale type = theme.typeScale;
    final M3ESpacing spacing = theme.spacing;

    final bool effectiveSelectionMode = _effectiveSelectionMode;
    final bool effectiveSelected = _effectiveSelected;
    final bool interactive =
        enabled &&
        visualState == null &&
        (onTap != null || onSelectionChanged != null);
    final bool rowEnabled =
        enabled && visualState != ComicListItemVisualState.disabled;
    final String? meta = metaLine(author: author, pageLabel: pageLabel);
    final bool showListProgress = showsReadProgressStrip(readProgress);

    final Widget coverLayer = ClipRRect(
      borderRadius: const BorderRadius.all(Radius.circular(kComicCardRadius)),
      child: SizedBox(
        width: kComicListItemCoverWidth,
        height: kComicListItemCoverHeight,
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            cover,
            if (effectiveSelectionMode)
              Positioned(
                left: kComicCardSelectionInset,
                top: kComicCardSelectionInset,
                child: M3ECheckbox(
                  value: effectiveSelected,
                  onChanged: rowEnabled && onSelectionChanged != null
                      ? (bool? value) {
                          if (value == null) {
                            return;
                          }
                          onSelectionChanged!.call(value);
                        }
                      : null,
                ),
              ),
          ],
        ),
      ),
    );

    Widget? trailingMore;
    if (moreMenuEntries.isNotEmpty) {
      trailingMore = AnchoredMenu(
        enabled: rowEnabled,
        position: M3EMenuAnchorPosition.bottomEnd,
        children: <M3EMenuEntry>[
          for (final ComicListMoreMenuEntry entry in moreMenuEntries)
            M3EMenuEntry(
              label: entry.label,
              enabled: rowEnabled && entry.onSelected != null,
              onPressed: entry.onSelected,
            ),
        ],
        anchorBuilder: (BuildContext context, VoidCallback open) {
          return M3EIconButton(
            icon: Icon(Icons.more_vert, color: scheme.onSurfaceVariant),
            variant: M3EIconButtonVariant.standard,
            size: M3EIconButtonSize.md,
            tooltip: '更多',
            onPressed: rowEnabled ? open : null,
          );
        },
      );
    }

    final Widget infoColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: comicCatalogTitleStyle(type, scheme),
        ),
        if (meta != null) ...<Widget>[
          const SizedBox(height: 4),
          Text(
            meta,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: comicCatalogSubtitleStyle(type, scheme),
          ),
        ],
        if (showListProgress) ...<Widget>[
          SizedBox(height: kComicListItemProgressTopGap),
          LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final double progressWidth = infoProgressWidthFor(
                constraints.maxWidth,
              );
              return SizedBox(
                width: progressWidth,
                height: kCoverReadProgressHeight,
                child: CoverReadProgressStrip(
                  key: kComicListItemInfoProgressKey,
                  progress: readProgress!,
                  activeColor: scheme.primary,
                  trackColor: scheme.onSurface.withValues(alpha: 0.24),
                ),
              );
            },
          ),
        ],
      ],
    );

    final Widget row = Padding(
      padding: const EdgeInsets.fromLTRB(
        kComicCatalogContentHorizontalPadding,
        kComicListItemVerticalPadding,
        kComicCatalogContentHorizontalPadding - 4,
        kComicListItemVerticalPadding,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          coverLayer,
          SizedBox(width: spacing.md),
          Expanded(child: infoColumn),
          if (trailingMore != null) ...<Widget>[
            const SizedBox(width: 4),
            trailingMore,
          ],
        ],
      ),
    );

    return ComicCatalogCardShell(
      height: kComicListItemMinHeight,
      width: double.infinity,
      enabled: rowEnabled,
      trackHover: visualState == null,
      onPressed: interactive ? _handleTap : null,
      selected: effectiveSelectionMode && effectiveSelected,
      pinnedOverlayAlpha: _pinnedOverlayAlphaFor(visualState),
      semanticLabel: ComicCard.showsCoverReadProgress(readProgress)
          ? '$title，已读 ${(readProgress!.clamp(0.0, 1.0) * 100).round()}%'
          : title,
      child: row,
    );
  }

  bool get _effectiveSelectionMode {
    if (visualState == ComicListItemVisualState.selectionUnselected ||
        visualState == ComicListItemVisualState.selectionSelected) {
      return true;
    }
    return selectionMode;
  }

  bool get _effectiveSelected {
    if (visualState == ComicListItemVisualState.selectionSelected) {
      return true;
    }
    if (visualState == ComicListItemVisualState.selectionUnselected) {
      return false;
    }
    return selected;
  }

  void _handleTap() {
    if (_effectiveSelectionMode && onSelectionChanged != null) {
      onSelectionChanged!(!_effectiveSelected);
      return;
    }
    onTap?.call();
  }

  static double _pinnedOverlayAlphaFor(ComicListItemVisualState? state) {
    switch (state) {
      case ComicListItemVisualState.pressed:
      case ComicListItemVisualState.focused:
        return kComicCatalogPinnedOverlayAlphaStrong;
      case ComicListItemVisualState.hovered:
        return kComicCatalogPinnedOverlayAlphaLight;
      case ComicListItemVisualState.disabled:
      case ComicListItemVisualState.normal:
      case ComicListItemVisualState.selectionUnselected:
      case ComicListItemVisualState.selectionSelected:
      case null:
        return 0;
    }
  }
}
