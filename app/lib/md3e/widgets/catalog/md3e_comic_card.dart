import 'package:flutter/material.dart';
import 'package:hentai_library/md3e/motion/md3e_motion.dart';
import 'package:hentai_library/md3e/widgets/md3e_cover_read_progress_strip.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// Corner radius for [Md3eComicCard] (M3 elevated card / MASTER 书库卡).
const double kMd3eComicCardRadius = 12;

/// Inset of the selection control from the cover top-left (MASTER 多选稿).
const double kMd3eComicCardSelectionInset = 8;

/// Alias of [kMd3eCoverReadProgressHeight] for comic card call sites.
const double kMd3eComicCardCoverProgressHeight = kMd3eCoverReadProgressHeight;

/// Key for the cover progress strip (tests / semantics tooling).
const Key kMd3eComicCardCoverProgressKey = Key('md3e_comic_card_cover_progress');

/// Pins M3 elevated-card visuals for catalogs (e.g. Widgetbook); not for production grids.
enum Md3eComicCardVisualState {
  normal,
  hovered,
  focused,
  pressed,
  dragged,
  disabled,
  selectionUnselected,
  selectionSelected,
}

/// Catalog grid comic card ([M3ECard] elevated; props only, no domain types).
///
/// Anatomy: flush [cover] (2:3) + padded title / [subtitle].
/// Interaction uses M3E card state layers on the info block overlay when pinned
/// for Widgetbook; otherwise [M3ECard] handles hover, focus, and press.
class Md3eComicCard extends StatelessWidget {
  /// Main-axis height for a flush-cover card at [cardWidth] (grid delegate).
  static double layoutMainAxisExtent({
    required double cardWidth,
    required double coverToInfoGap,
    required double infoBottomPadding,
    bool hasSubtitle = true,
  }) {
    final double coverHeight = cardWidth * 3 / 2;
    const double titleLineHeight = 20;
    const double titleSubtitleGap = 6;
    const double subtitleLineHeight = 16;
    final double infoBlock = titleLineHeight +
        (hasSubtitle ? titleSubtitleGap + subtitleLineHeight : 0) +
        infoBottomPadding;
    return coverHeight + coverToInfoGap + infoBlock;
  }

  /// Whether the cover progress strip should be built for [readProgress].
  static bool showsCoverReadProgress(double? readProgress) {
    return md3eShowsReadProgressStrip(readProgress);
  }

  /// Grid row height at [maxCrossAxisExtent] (matches Baseline catalog formula).
  static double gridMainAxisExtent({
    required double maxCrossAxisExtent,
    required double coverToInfoGap,
    required double infoBottomPadding,
    bool hasSubtitle = true,
  }) {
    return layoutMainAxisExtent(
      cardWidth: maxCrossAxisExtent,
      coverToInfoGap: coverToInfoGap,
      infoBottomPadding: infoBottomPadding,
      hasSubtitle: hasSubtitle,
    ).ceil() +
        16;
  }

  const Md3eComicCard({
    super.key,
    required this.title,
    required this.cover,
    this.subtitle,
    this.onTap,
    this.enabled = true,
    this.visualState,
    this.selectionMode = false,
    this.selected = false,
    this.onSelectionChanged,
    this.readProgress,
  }) : assert(
         readProgress == null ||
             (readProgress >= 0 && readProgress <= 1),
         'readProgress must be between 0 and 1',
       );

  final String title;
  final String? subtitle;
  final Widget cover;
  final VoidCallback? onTap;

  final bool selectionMode;
  final bool selected;
  final ValueChanged<bool>? onSelectionChanged;

  final bool enabled;
  final Md3eComicCardVisualState? visualState;
  final double? readProgress;

  @override
  Widget build(BuildContext context) {
    final M3EThemeData theme = M3ETheme.of(context);
    final M3EColorScheme scheme = theme.colorScheme;
    final M3ESpacing spacing = theme.spacing;
    final M3ETypeScale type = theme.typeScale;

    final bool effectiveSelectionMode = _effectiveSelectionMode;
    final bool effectiveSelected = _effectiveSelected;
    final bool interactive =
        enabled &&
        visualState == null &&
        (onTap != null || onSelectionChanged != null);
    final bool cardEnabled =
        enabled && visualState != Md3eComicCardVisualState.disabled;
    final bool dragged = visualState == Md3eComicCardVisualState.dragged;
    final double infoOverlayAlpha = _infoOverlayAlphaFor(visualState);

    final bool reduceMotion = Md3eMotion.reduceMotionOf(context);
    final Duration motionDuration = Md3eMotion.motionDurationOf(
      context,
      Md3eMotion.durationShort,
    );
    final Curve stateEnter = Md3eMotion.curveForStateEnter(
      reduceMotion: reduceMotion,
    );
    final Curve stateExit = Md3eMotion.curveForStateExit(
      reduceMotion: reduceMotion,
    );

    const double contentHorizontalPadding = 12;
    const double titleSubtitleGap = 6;

    final double? coverProgress = readProgress;
    final bool showCoverProgress = md3eShowsReadProgressStrip(coverProgress);

    final Widget coverLayer = AspectRatio(
      aspectRatio: 2 / 3,
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
                onChanged: cardEnabled && onSelectionChanged != null
                    ? (bool? value) {
                        if (value == null) {
                          return;
                        }
                        onSelectionChanged!.call(value);
                      }
                    : null,
              ),
            ),
          if (showCoverProgress)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: kMd3eComicCardCoverProgressHeight,
              child: Md3eCoverReadProgressStrip(
                key: kMd3eComicCardCoverProgressKey,
                progress: readProgress!,
                activeColor: scheme.primary,
                trackColor: scheme.onSurface.withValues(alpha: 0.24),
                duration: motionDuration,
                curve: stateEnter,
              ),
            ),
        ],
      ),
    );

    Widget infoBlock = Padding(
      padding: EdgeInsets.fromLTRB(
        contentHorizontalPadding,
        spacing.md,
        contentHorizontalPadding,
        contentHorizontalPadding,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: titleSubtitleGap,
        children: <Widget>[
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: type.titleSmall.copyWith(
              fontWeight: FontWeight.w600,
              color: scheme.onSurface,
            ),
          ),
          if (subtitle != null)
            Text(
              subtitle!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: type.labelSmall.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
        ],
      ),
    );

    if (infoOverlayAlpha > 0) {
      infoBlock = Stack(
        fit: StackFit.passthrough,
        children: <Widget>[
          infoBlock,
          Positioned.fill(
            child: IgnorePointer(
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(end: infoOverlayAlpha),
                duration: motionDuration,
                curve: infoOverlayAlpha > 0 ? stateEnter : stateExit,
                builder: (BuildContext context, double alpha, Widget? child) {
                  if (alpha <= 0) {
                    return const SizedBox.shrink();
                  }
                  return ColoredBox(
                    color: scheme.onSurface.withValues(alpha: alpha),
                  );
                },
              ),
            ),
          ),
        ],
      );
    }

    return M3ECard(
      variant: M3ECardVariant.elevated,
      padding: EdgeInsets.zero,
      borderRadius: BorderRadius.circular(kMd3eComicCardRadius),
      enabled: cardEnabled,
      dragged: dragged,
      trackHover: visualState == null,
      onPressed: interactive ? _handleTap : null,
      semanticLabel: _semanticsLabel(
        title: title,
        readProgress: coverProgress,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          coverLayer,
          infoBlock,
        ],
      ),
    );
  }

  bool get _effectiveSelectionMode {
    if (visualState == Md3eComicCardVisualState.selectionUnselected ||
        visualState == Md3eComicCardVisualState.selectionSelected) {
      return true;
    }
    return selectionMode;
  }

  bool get _effectiveSelected {
    if (visualState == Md3eComicCardVisualState.selectionSelected) {
      return true;
    }
    if (visualState == Md3eComicCardVisualState.selectionUnselected) {
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

  static double _infoOverlayAlphaFor(Md3eComicCardVisualState? state) {
    switch (state) {
      case Md3eComicCardVisualState.pressed:
        return 0.12;
      case Md3eComicCardVisualState.hovered:
      case Md3eComicCardVisualState.focused:
      case Md3eComicCardVisualState.dragged:
        return 0.08;
      case Md3eComicCardVisualState.disabled:
      case Md3eComicCardVisualState.normal:
      case Md3eComicCardVisualState.selectionUnselected:
      case Md3eComicCardVisualState.selectionSelected:
      case null:
        return 0;
    }
  }

  static String _semanticsLabel({
    required String title,
    required double? readProgress,
  }) {
    if (!md3eShowsReadProgressStrip(readProgress)) {
      return title;
    }
    final int percent = (readProgress!.clamp(0.0, 1.0) * 100).round();
    return '$title，已读 $percent%';
  }
}
