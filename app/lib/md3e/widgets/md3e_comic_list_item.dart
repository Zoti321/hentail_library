import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:hentai_library/md3e/motion/md3e_motion.dart';
import 'package:hentai_library/md3e/widgets/md3e_cover_read_progress_strip.dart';
import 'package:material_expressive/theme.dart';

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

/// Catalog list-row comic item (M3 two-line list + leading; props only).
///
/// Anatomy: optional selection [Checkbox], inset 60×45 (4:3) [cover], info column
/// (title / meta / [readProgress] bar), trailing [Icons.more_vert] menu.
/// Focus uses M3 list **state layer** (12% onSurface), not a side border.
class Md3eComicListItem extends StatefulWidget {
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

  /// Fixed extent for [ListView] / sliver list delegates.
  static double itemExtent() => kMd3eComicListItemMinHeight;

  /// Builds `作者 · 128 页` style supporting text.
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

  /// Clamps info-column progress width between [kMd3eComicListItemProgressMinWidth]
  /// and [kMd3eComicListItemProgressMaxWidth].
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

  /// Read progress in \[0, 1\]. When null or 0, the info progress bar is hidden.
  final double? readProgress;

  /// When non-empty, shows a trailing more menu with these entries.
  final List<Md3eComicListMoreMenuEntry> moreMenuEntries;

  @override
  State<Md3eComicListItem> createState() => _Md3eComicListItemState();
}

class _Md3eComicListItemState extends State<Md3eComicListItem> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  bool get _effectiveSelectionMode {
    if (widget.visualState ==
            Md3eComicListItemVisualState.selectionUnselected ||
        widget.visualState == Md3eComicListItemVisualState.selectionSelected) {
      return true;
    }
    return widget.selectionMode;
  }

  bool get _effectiveSelected {
    if (widget.visualState == Md3eComicListItemVisualState.selectionSelected) {
      return true;
    }
    if (widget.visualState == Md3eComicListItemVisualState.selectionUnselected) {
      return false;
    }
    return widget.selected;
  }

  bool get _interactive =>
      widget.enabled &&
      widget.visualState == null &&
      (widget.onTap != null || widget.onSelectionChanged != null);

  Set<WidgetState> get _states {
    if (widget.visualState != null) {
      return _statesForVisual(widget.visualState!);
    }
    return <WidgetState>{
      if (!widget.enabled) WidgetState.disabled,
      if (_hovered) WidgetState.hovered,
      if (_focused) WidgetState.focused,
      if (_pressed) WidgetState.pressed,
    };
  }

  static Set<WidgetState> _statesForVisual(Md3eComicListItemVisualState state) {
    switch (state) {
      case Md3eComicListItemVisualState.normal:
      case Md3eComicListItemVisualState.selectionUnselected:
      case Md3eComicListItemVisualState.selectionSelected:
        return <WidgetState>{};
      case Md3eComicListItemVisualState.hovered:
        return <WidgetState>{WidgetState.hovered};
      case Md3eComicListItemVisualState.focused:
        return <WidgetState>{WidgetState.focused};
      case Md3eComicListItemVisualState.pressed:
        return <WidgetState>{WidgetState.pressed};
      case Md3eComicListItemVisualState.disabled:
        return <WidgetState>{WidgetState.disabled};
    }
  }

  /// M3 list state-layer opacities (lists/specs).
  static double _overlayAlphaFor(Set<WidgetState> states) {
    if (states.contains(WidgetState.disabled)) {
      return 0;
    }
    if (states.contains(WidgetState.pressed) ||
        states.contains(WidgetState.focused)) {
      return 0.12;
    }
    if (states.contains(WidgetState.hovered)) {
      return 0.08;
    }
    return 0;
  }

  void _handleTap() {
    if (_effectiveSelectionMode && widget.onSelectionChanged != null) {
      widget.onSelectionChanged!(!_effectiveSelected);
      return;
    }
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    final ExpressiveThemeData tokens = ExpressiveThemeProvider.of(context);
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final Set<WidgetState> states = _states;
    final bool disabled = states.contains(WidgetState.disabled);
    final double overlayAlpha = _overlayAlphaFor(states);
    final bool showInfoProgress =
        md3eShowsReadProgressStrip(widget.readProgress);
    final String? metaLine = Md3eComicListItem.metaLine(
      author: widget.author,
      pageLabel: widget.pageLabel,
    );

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

    const double horizontalPadding = 16;
    const double titleMetaGap = 4;

    final BorderRadius coverRadius =
        BorderRadius.circular(kMd3eComicListItemCoverRadius);

    final Widget leadingCover = Padding(
      padding: const EdgeInsets.symmetric(
        vertical: kMd3eComicListItemVerticalInset,
      ),
      child: SizedBox(
        width: kMd3eComicListItemLeadingWidth,
        height: kMd3eComicListItemLeadingHeight,
        child: ClipRRect(
          borderRadius: coverRadius,
          child: widget.cover,
        ),
      ),
    );

    Widget? trailingMore;
    if (widget.moreMenuEntries.isNotEmpty) {
      trailingMore = PopupMenuButton<void>(
        icon: Icon(
          Icons.more_vert,
          color: scheme.onSurfaceVariant,
        ),
        enabled: !disabled,
        tooltip: '更多',
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
        onSelected: (_) {},
        itemBuilder: (BuildContext context) {
          return <PopupMenuEntry<void>>[
            for (final Md3eComicListMoreMenuEntry entry
                in widget.moreMenuEntries)
              PopupMenuItem<void>(
                onTap: entry.onSelected,
                child: Text(entry.label),
              ),
          ];
        },
      );
    }

    Widget row = SizedBox(
      height: kMd3eComicListItemMinHeight,
      child: Padding(
        padding: const EdgeInsets.only(left: horizontalPadding),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            if (_effectiveSelectionMode) ...<Widget>[
              Checkbox(
                value: _effectiveSelected,
                onChanged: disabled
                    ? null
                    : (bool? value) {
                        if (value == null) {
                          return;
                        }
                        widget.onSelectionChanged?.call(value);
                      },
              ),
              SizedBox(width: tokens.spacing.sm),
            ],
            leadingCover,
            SizedBox(width: horizontalPadding),
            Expanded(
              child: LayoutBuilder(
                builder: (BuildContext context, BoxConstraints constraints) {
                  final double progressWidth =
                      Md3eComicListItem.infoProgressWidthFor(
                        constraints.maxWidth,
                      );
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        widget.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: scheme.onSurface,
                        ),
                      ),
                      if (metaLine != null) ...<Widget>[
                        SizedBox(height: titleMetaGap),
                        Text(
                          metaLine,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                      if (showInfoProgress) ...<Widget>[
                        SizedBox(height: kMd3eComicListItemProgressTopGap),
                        SizedBox(
                          width: progressWidth,
                          height: kMd3eCoverReadProgressHeight,
                          child: Md3eCoverReadProgressStrip(
                            key: kMd3eComicListItemInfoProgressKey,
                            progress: widget.readProgress!,
                            activeColor: scheme.primary,
                            trackColor: scheme.surfaceContainerHighest,
                            duration: motionDuration,
                            curve: stateEnter,
                          ),
                        ),
                      ],
                    ],
                  );
                },
              ),
            ),
            ?trailingMore,
            const SizedBox(width: 4),
          ],
        ),
      ),
    );

    row = Stack(
      fit: StackFit.passthrough,
      children: <Widget>[
        row,
        Positioned.fill(
          child: IgnorePointer(
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(end: overlayAlpha),
              duration: motionDuration,
              curve: overlayAlpha > 0 ? stateEnter : stateExit,
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

    row = TweenAnimationBuilder<double>(
      tween: Tween<double>(end: disabled ? 0.38 : 1),
      duration: motionDuration,
      curve: disabled ? stateExit : stateEnter,
      builder: (BuildContext context, double opacity, Widget? child) {
        return Opacity(opacity: opacity, child: child);
      },
      child: row,
    );

    final Widget tile = Material(
      color: Colors.transparent,
      child: row,
    );

    final String semanticsLabel = _semanticsLabel(
      title: widget.title,
      readProgress: widget.readProgress,
      metaLine: metaLine,
    );

    if (!_interactive) {
      return Semantics(
        button: widget.onTap != null || widget.onSelectionChanged != null,
        label: semanticsLabel,
        enabled: !disabled,
        checked: _effectiveSelectionMode ? _effectiveSelected : null,
        child: tile,
      );
    }

    return Semantics(
      button: true,
      label: semanticsLabel,
      checked: _effectiveSelectionMode ? _effectiveSelected : null,
      child: FocusableActionDetector(
        mouseCursor: SystemMouseCursors.click,
        onShowHoverHighlight: (bool value) => setState(() => _hovered = value),
        onShowFocusHighlight: (bool value) => setState(() => _focused = value),
        actions: <Type, Action<Intent>>{
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (ActivateIntent intent) {
              _handleTap();
              return null;
            },
          ),
        },
        child: Listener(
          onPointerDown: (_) => setState(() => _pressed = true),
          onPointerUp: (_) => setState(() => _pressed = false),
          onPointerCancel: (_) => setState(() => _pressed = false),
          child: GestureDetector(
            onTap: _handleTap,
            behavior: HitTestBehavior.opaque,
            child: tile,
          ),
        ),
      ),
    );
  }

  static String _semanticsLabel({
    required String title,
    required double? readProgress,
    required String? metaLine,
  }) {
    final StringBuffer buffer = StringBuffer(title);
    if (metaLine != null) {
      buffer.write('，$metaLine');
    }
    if (md3eShowsReadProgressStrip(readProgress)) {
      final int percent = (readProgress!.clamp(0.0, 1.0) * 100).round();
      buffer.write('，已读 $percent%');
    }
    return buffer.toString();
  }
}
