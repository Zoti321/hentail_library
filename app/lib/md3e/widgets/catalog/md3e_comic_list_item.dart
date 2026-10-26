import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:hentai_library/md3e/motion/md3e_motion.dart';
import 'package:hentai_library/md3e/widgets/menu/md3e_anchored_menu.dart';
import 'package:hentai_library/md3e/widgets/catalog/md3e_cover_read_progress_strip.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// Middle dot between author and page label (e.g. `作者名 · 128 页`).
const String kMd3eComicListItemMetaSeparator = ' · ';

/// Leading thumbnail width (landscape-leaning catalog thumb).
const double kMd3eComicListItemLeadingWidth = 60;

/// Leading thumbnail height (4:3).
const double kMd3eComicListItemLeadingHeight = 45;

/// Vertical inset between leading cover and row bounds.
const double kMd3eComicListItemVerticalInset = 12;

/// Minimum row height (accommodates inset cover + two-line info + progress).
const double kMd3eComicListItemMinHeight = 88;

/// Corner radius on the leading cover clip.
const double kMd3eComicListItemCoverRadius = 8;

/// Min width of the read-progress bar in the info column.
const double kMd3eComicListItemProgressMinWidth = 96;

/// Max width of the read-progress bar in the info column.
const double kMd3eComicListItemProgressMaxWidth = 240;

/// Gap above the info-column progress bar (below meta line).
const double kMd3eComicListItemProgressTopGap = 6;

/// Key for the info-area progress strip in tests.
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

/// Catalog list-row comic item ([M3EListItem] + catalog anatomy).
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
    final double upper = math.min(
      availableWidth,
      kMd3eComicListItemProgressMaxWidth,
    );
    if (upper <= 0) {
      return 0;
    }
    if (upper < kMd3eComicListItemProgressMinWidth) {
      return upper;
    }
    return math.max(kMd3eComicListItemProgressMinWidth, upper);
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
    final M3EColorScheme scheme = M3ETheme.of(context).colorScheme;
    final M3ESpacing spacing = M3ETheme.of(context).spacing;
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
    final bool showInfoProgress = md3eShowsReadProgressStrip(readProgress);
    final double overlayAlpha = _overlayAlphaFor(visualState);

    final BorderRadius coverRadius =
        BorderRadius.circular(kMd3eComicListItemCoverRadius);

    final Widget coverClip = Padding(
      padding: const EdgeInsets.symmetric(
        vertical: kMd3eComicListItemVerticalInset,
      ),
      child: SizedBox(
        width: kMd3eComicListItemLeadingWidth,
        height: kMd3eComicListItemLeadingHeight,
        child: ClipRRect(
          borderRadius: coverRadius,
          child: cover,
        ),
      ),
    );

    final double leadingSlotWidth = effectiveSelectionMode
        ? 48 + spacing.sm + kMd3eComicListItemLeadingWidth
        : kMd3eComicListItemLeadingWidth;

    final Widget leading = SizedBox(
      width: leadingSlotWidth,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (effectiveSelectionMode) ...<Widget>[
            M3ECheckbox(
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
            SizedBox(width: spacing.sm),
          ],
          coverClip,
        ],
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
            size: M3EIconButtonSize.sm,
            tooltip: '更多',
            onPressed: rowEnabled ? open : null,
          );
        },
      );
    }

    const double horizontalPadding = 16;

    Widget row = M3EListItem(
      headline: title,
      supportingText: meta,
      leading: leading,
      trailing: trailingMore,
      selected: effectiveSelected,
      enabled: rowEnabled,
      largeLeading: true,
      onTap: interactive ? _handleTap : null,
    );

    row = SizedBox(
      height: kMd3eComicListItemMinHeight,
      child: Stack(
        fit: StackFit.passthrough,
        children: <Widget>[
          row,
          if (showInfoProgress)
            Positioned(
              left: _infoTextInset(
                selectionMode: effectiveSelectionMode,
                spacing: spacing,
              ),
              right: moreMenuEntries.isNotEmpty ? 52 : horizontalPadding,
              bottom: kMd3eComicListItemVerticalInset,
              child: LayoutBuilder(
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
                      trackColor: scheme.surfaceContainerHighest,
                      duration: motionDuration,
                      curve: stateEnter,
                    ),
                  );
                },
              ),
            ),
          if (overlayAlpha > 0)
            Positioned.fill(
              child: IgnorePointer(
                child: ColoredBox(
                  color: scheme.onSurface.withValues(alpha: overlayAlpha),
                ),
              ),
            ),
        ],
      ),
    );

    return row;
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

  static double _infoTextInset({
    required bool selectionMode,
    required M3ESpacing spacing,
  }) {
    const double horizontalPadding = 16;
    const double checkboxWidth = 48;
    double inset = horizontalPadding +
        kMd3eComicListItemLeadingWidth +
        horizontalPadding;
    if (selectionMode) {
      inset += checkboxWidth + spacing.sm;
    }
    return inset;
  }

  static double _overlayAlphaFor(Md3eComicListItemVisualState? state) {
    switch (state) {
      case Md3eComicListItemVisualState.pressed:
      case Md3eComicListItemVisualState.focused:
        return 0.12;
      case Md3eComicListItemVisualState.hovered:
        return 0.08;
      case Md3eComicListItemVisualState.disabled:
      case Md3eComicListItemVisualState.normal:
      case Md3eComicListItemVisualState.selectionUnselected:
      case Md3eComicListItemVisualState.selectionSelected:
      case null:
        return 0;
    }
  }
}
