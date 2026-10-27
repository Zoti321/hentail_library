import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:hentai_library/md3e/motion/md3e_motion.dart';
import 'package:hentai_library/md3e/widgets/menu/md3e_anchored_menu.dart';
import 'package:hentai_library/md3e/widgets/catalog/md3e_comic_catalog_card_shell.dart';
import 'package:hentai_library/md3e/widgets/catalog/md3e_comic_card.dart';
import 'package:hentai_library/md3e/widgets/catalog/md3e_cover_read_progress_strip.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// Middle dot between author and page label (e.g. `作者名 · 128 页`).
const String kMd3eComicListItemMetaSeparator = ' · ';

/// List-row cover width (2:3, same media treatment as [Md3eComicCard]).
const double kMd3eComicListItemCoverWidth = 56;

/// Derived list cover height.
double get kMd3eComicListItemCoverHeight =>
    kMd3eComicListItemCoverWidth * 3 / 2;

/// Vertical padding inside the shared catalog card shell.
const double kMd3eComicListItemVerticalPadding = 12;

/// Minimum row height (cover + vertical insets).
double get kMd3eComicListItemMinHeight =>
    kMd3eComicListItemCoverHeight + 2 * kMd3eComicListItemVerticalPadding;

/// Max width of the read-progress bar when shown under meta (list-only layout).
const double kMd3eComicListItemProgressMaxWidth = 160;

/// Gap between meta line and list progress bar.
const double kMd3eComicListItemProgressTopGap = 6;

/// Key for list-row progress strip in tests (under title/meta, not on cover).
const Key kMd3eComicListItemInfoProgressKey =
    Key('md3e_comic_list_item_info_progress');

/// One action in the trailing overflow ([Icons.more_vert]) menu.
class Md3eComicListMoreMenuEntry {
  const Md3eComicListMoreMenuEntry({
    required this.label,
    this.onSelected,
  });

  final String label;
  final VoidCallback? onSelected;
}

/// Pins M3 list-item visuals for Widgetbook; not for production lists.
enum Md3eComicListItemVisualState {
  normal,
  hovered,
  focused,
  pressed,
  disabled,
  selectionUnselected,
  selectionSelected,
}

/// Catalog list comic item: same [Md3eComicCatalogCardShell] as [Md3eComicCard],
/// horizontal cover + text + optional trailing menu.
class Md3eComicListItem extends StatelessWidget {
  const Md3eComicListItem({
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
    this.moreMenuEntries = const <Md3eComicListMoreMenuEntry>[],
  }) : assert(
         readProgress == null ||
             (readProgress >= 0 && readProgress <= 1),
         'readProgress must be between 0 and 1',
       );

  static double itemExtent() => kMd3eComicListItemMinHeight;

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
    return parts.join(kMd3eComicListItemMetaSeparator);
  }

  static double infoProgressWidthFor(double availableWidth) {
    if (availableWidth <= 0) {
      return 0;
    }
    return math.min(availableWidth, kMd3eComicListItemProgressMaxWidth);
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
  final Md3eComicListItemVisualState? visualState;

  final double? readProgress;
  final List<Md3eComicListMoreMenuEntry> moreMenuEntries;

  @override
  Widget build(BuildContext context) {
    final M3EThemeData theme = M3ETheme.of(context);
    final M3EColorScheme scheme = theme.colorScheme;
    final M3ETypeScale type = theme.typeScale;
    final M3ESpacing spacing = theme.spacing;
    final bool reduceMotion = Md3eMotion.reduceMotionOf(context);
    final Duration motionDuration = Md3eMotion.motionDurationOf(
      context,
      Md3eMotion.durationShort,
    );
    final Curve stateEnter = Md3eMotion.curveForStateEnter(
      reduceMotion: reduceMotion,
    );

    final bool effectiveSelectionMode = _effectiveSelectionMode;
    final bool effectiveSelected = _effectiveSelected;
    final bool interactive =
        enabled &&
        visualState == null &&
        (onTap != null || onSelectionChanged != null);
    final bool rowEnabled =
        enabled && visualState != Md3eComicListItemVisualState.disabled;
    final String? meta = metaLine(author: author, pageLabel: pageLabel);
    final bool showListProgress = md3eShowsReadProgressStrip(readProgress);

    final Widget coverLayer = ClipRRect(
      borderRadius: BorderRadius.circular(kMd3eComicCardRadius),
      child: SizedBox(
        width: kMd3eComicListItemCoverWidth,
        height: kMd3eComicListItemCoverHeight,
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            cover,
          if (effectiveSelectionMode)
            Positioned(
              left: kMd3eComicCardSelectionInset,
              top: kMd3eComicCardSelectionInset,
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
      trailingMore = Md3eAnchoredMenu(
        enabled: rowEnabled,
        position: M3EMenuAnchorPosition.bottomEnd,
        children: <M3EMenuEntry>[
          for (final Md3eComicListMoreMenuEntry entry in moreMenuEntries)
            M3EMenuEntry(
              label: entry.label,
              enabled: rowEnabled && entry.onSelected != null,
              onPressed: entry.onSelected,
            ),
        ],
        anchorBuilder: (BuildContext context, VoidCallback open) {
          return M3EIconButton(
            icon: Icon(
              Icons.more_vert,
              color: scheme.onSurfaceVariant,
            ),
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
          style: md3eComicCatalogTitleStyle(type, scheme),
        ),
        if (meta != null) ...<Widget>[
          const SizedBox(height: 4),
          Text(
            meta,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: md3eComicCatalogSubtitleStyle(type, scheme),
          ),
        ],
        if (showListProgress) ...<Widget>[
          SizedBox(height: kMd3eComicListItemProgressTopGap),
          LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final double progressWidth = infoProgressWidthFor(
                constraints.maxWidth,
              );
              return SizedBox(
                width: progressWidth,
                height: kMd3eCoverReadProgressHeight,
                child: Md3eCoverReadProgressStrip(
                  key: kMd3eComicListItemInfoProgressKey,
                  progress: readProgress!,
                  activeColor: scheme.primary,
                  trackColor: scheme.onSurface.withValues(alpha: 0.24),
                  duration: motionDuration,
                  curve: stateEnter,
                ),
              );
            },
          ),
        ],
      ],
    );

    final Widget row = Padding(
      padding: const EdgeInsets.fromLTRB(
        kMd3eComicCatalogContentHorizontalPadding,
        kMd3eComicListItemVerticalPadding,
        kMd3eComicCatalogContentHorizontalPadding - 4,
        kMd3eComicListItemVerticalPadding,
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

    return Md3eComicCatalogCardShell(
      height: kMd3eComicListItemMinHeight,
      width: double.infinity,
      enabled: rowEnabled,
      trackHover: visualState == null,
      onPressed: interactive ? _handleTap : null,
      pinnedOverlayAlpha: _pinnedOverlayAlphaFor(visualState),
      semanticLabel: Md3eComicCard.showsCoverReadProgress(readProgress)
          ? '$title，已读 ${(readProgress!.clamp(0.0, 1.0) * 100).round()}%'
          : title,
      child: row,
    );
  }

  bool get _effectiveSelectionMode {
    if (visualState == Md3eComicListItemVisualState.selectionUnselected ||
        visualState == Md3eComicListItemVisualState.selectionSelected) {
      return true;
    }
    return selectionMode;
  }

  bool get _effectiveSelected {
    if (visualState == Md3eComicListItemVisualState.selectionSelected) {
      return true;
    }
    if (visualState == Md3eComicListItemVisualState.selectionUnselected) {
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

  static double _pinnedOverlayAlphaFor(Md3eComicListItemVisualState? state) {
    switch (state) {
      case Md3eComicListItemVisualState.pressed:
      case Md3eComicListItemVisualState.focused:
        return kMd3eComicCatalogPinnedOverlayAlphaStrong;
      case Md3eComicListItemVisualState.hovered:
        return kMd3eComicCatalogPinnedOverlayAlphaLight;
      case Md3eComicListItemVisualState.disabled:
      case Md3eComicListItemVisualState.normal:
      case Md3eComicListItemVisualState.selectionUnselected:
      case Md3eComicListItemVisualState.selectionSelected:
      case null:
        return 0;
    }
  }
}
