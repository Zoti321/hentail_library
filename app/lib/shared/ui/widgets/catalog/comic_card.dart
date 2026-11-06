import 'package:flutter/material.dart';
import 'package:hentai_library/shared/ui/widgets/catalog/comic_catalog_card_shell.dart';
import 'package:hentai_library/shared/ui/widgets/catalog/cover_read_progress_strip.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

export 'package:hentai_library/shared/ui/widgets/catalog/comic_catalog_card_shell.dart'
    show kComicCardRadius;

/// Inset of the selection control from the cover top-left (MASTER 多选稿).
const double kComicCardSelectionInset = 8;

/// Alias of [kCoverReadProgressHeight] for comic card call sites.
const double kComicCardCoverProgressHeight = kCoverReadProgressHeight;

/// Key for the cover progress strip (tests / semantics tooling).
const Key kComicCardCoverProgressKey = Key('_comic_card_cover_progress');

/// Pins M3 elevated-card visuals for catalogs (e.g. Widgetbook); not for production grids.
enum ComicCardVisualState {
  normal,
  hovered,
  focused,
  pressed,
  dragged,
  disabled,
  selectionUnselected,
  selectionSelected,
}

/// Catalog grid comic card ([ComicCatalogCardShell]; props only, no domain types).
///
/// Anatomy: flush [cover] (2:3) + padded title / [subtitle]; progress on cover bottom.
class ComicCard extends StatelessWidget {
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
    final double infoBlock =
        titleLineHeight +
        (hasSubtitle ? titleSubtitleGap + subtitleLineHeight : 0) +
        infoBottomPadding;
    return coverHeight + coverToInfoGap + infoBlock;
  }

  /// Whether the cover progress strip should be built for [readProgress].
  static bool showsCoverReadProgress(double? readProgress) {
    return showsReadProgressStrip(readProgress);
  }

  /// Grid row height when the delegate cell width equals [maxCrossAxisExtent].
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
    ).ceilToDouble();
  }

  const ComicCard({
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
         readProgress == null || (readProgress >= 0 && readProgress <= 1),
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
  final ComicCardVisualState? visualState;
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
        enabled && visualState != ComicCardVisualState.disabled;
    final bool dragged = visualState == ComicCardVisualState.dragged;

    const double titleSubtitleGap = 6;

    final double? coverProgress = readProgress;
    final bool showCoverProgress = showsReadProgressStrip(coverProgress);

    final Widget coverLayer = AspectRatio(
      aspectRatio: 2 / 3,
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
              height: kComicCardCoverProgressHeight,
              child: CoverReadProgressStrip(
                key: kComicCardCoverProgressKey,
                progress: readProgress!,
                activeColor: scheme.primary,
                trackColor: scheme.onSurface.withValues(alpha: 0.24),
              ),
            ),
        ],
      ),
    );

    final Widget body = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        coverLayer,
        Padding(
          padding: EdgeInsets.fromLTRB(
            kComicCatalogContentHorizontalPadding,
            spacing.md,
            kComicCatalogContentHorizontalPadding,
            kComicCatalogContentHorizontalPadding,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: titleSubtitleGap,
            children: <Widget>[
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: comicCatalogTitleStyle(type, scheme),
              ),
              if (subtitle != null)
                Text(
                  subtitle!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: comicCatalogSubtitleStyle(type, scheme),
                ),
            ],
          ),
        ),
      ],
    );

    return ComicCatalogCardShell(
      enabled: cardEnabled,
      dragged: dragged,
      trackHover: visualState == null,
      onPressed: interactive ? _handleTap : null,
      selected: effectiveSelectionMode && effectiveSelected,
      pinnedOverlayAlpha: _pinnedOverlayAlphaFor(visualState),
      semanticLabel: _semanticsLabel(title: title, readProgress: coverProgress),
      child: body,
    );
  }

  bool get _effectiveSelectionMode {
    if (visualState == ComicCardVisualState.selectionUnselected ||
        visualState == ComicCardVisualState.selectionSelected) {
      return true;
    }
    return selectionMode;
  }

  bool get _effectiveSelected {
    if (visualState == ComicCardVisualState.selectionSelected) {
      return true;
    }
    if (visualState == ComicCardVisualState.selectionUnselected) {
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

  static double _pinnedOverlayAlphaFor(ComicCardVisualState? state) {
    switch (state) {
      case ComicCardVisualState.pressed:
      case ComicCardVisualState.focused:
        return kComicCatalogPinnedOverlayAlphaStrong;
      case ComicCardVisualState.hovered:
      case ComicCardVisualState.dragged:
        return kComicCatalogPinnedOverlayAlphaLight;
      case ComicCardVisualState.disabled:
      case ComicCardVisualState.normal:
      case ComicCardVisualState.selectionUnselected:
      case ComicCardVisualState.selectionSelected:
      case null:
        return 0;
    }
  }

  static String _semanticsLabel({
    required String title,
    required double? readProgress,
  }) {
    if (!showsReadProgressStrip(readProgress)) {
      return title;
    }
    final int percent = (readProgress!.clamp(0.0, 1.0) * 100).round();
    return '$title，已读 $percent%';
  }
}
