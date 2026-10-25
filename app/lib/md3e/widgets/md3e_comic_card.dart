import 'package:flutter/material.dart';
import 'package:hentai_library/md3e/motion/md3e_motion.dart';
import 'package:material_expressive/theme.dart';

/// Corner radius for [Md3eComicCard] (M3 elevated card / MASTER 书库卡).
const double kMd3eComicCardRadius = 12;

/// Inset of the selection control from the cover top-left (MASTER 多选稿).
const double kMd3eComicCardSelectionInset = 8;

/// Full-width read-progress strip along the bottom edge of the cover (2dp).
const double kMd3eComicCardCoverProgressHeight = 2;

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

/// Catalog grid comic card (MD3E elevated card; props only, no domain types).
///
/// Anatomy: flush [cover] (2:3) + padded title / [subtitle].
/// Interaction overlays apply to the **info block only**; cover stays unchanged
/// except an optional full-width [readProgress] strip on the cover bottom.
/// State transitions use [Md3eMotion] durations and M3 emphasized curves.
class Md3eComicCard extends StatefulWidget {
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
  ///
  /// `null` and `0` (and negative values, if passed) do not render the strip.
  static bool showsCoverReadProgress(double? readProgress) {
    return readProgress != null && readProgress > 0;
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

  /// When true, shows a [Checkbox] on the cover; [selected] drives checked state.
  final bool selectionMode;
  final bool selected;
  final ValueChanged<bool>? onSelectionChanged;

  final bool enabled;

  /// When set, interaction is disabled and the card renders a fixed M3 state.
  final Md3eComicCardVisualState? visualState;

  /// Read progress in \[0, 1\]. When null or 0, the cover progress strip is hidden.
  final double? readProgress;

  @override
  State<Md3eComicCard> createState() => _Md3eComicCardState();
}

class _Md3eComicCardState extends State<Md3eComicCard> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  bool get _effectiveSelectionMode {
    if (widget.visualState == Md3eComicCardVisualState.selectionUnselected ||
        widget.visualState == Md3eComicCardVisualState.selectionSelected) {
      return true;
    }
    return widget.selectionMode;
  }

  bool get _effectiveSelected {
    if (widget.visualState == Md3eComicCardVisualState.selectionSelected) {
      return true;
    }
    if (widget.visualState == Md3eComicCardVisualState.selectionUnselected) {
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

  static Set<WidgetState> _statesForVisual(Md3eComicCardVisualState state) {
    switch (state) {
      case Md3eComicCardVisualState.normal:
      case Md3eComicCardVisualState.selectionUnselected:
      case Md3eComicCardVisualState.selectionSelected:
        return <WidgetState>{};
      case Md3eComicCardVisualState.hovered:
        return <WidgetState>{WidgetState.hovered};
      case Md3eComicCardVisualState.focused:
        return <WidgetState>{WidgetState.focused};
      case Md3eComicCardVisualState.pressed:
        return <WidgetState>{WidgetState.pressed};
      case Md3eComicCardVisualState.dragged:
        return <WidgetState>{WidgetState.dragged};
      case Md3eComicCardVisualState.disabled:
        return <WidgetState>{WidgetState.disabled};
    }
  }

  static double _elevationFor(Set<WidgetState> states) {
    if (states.contains(WidgetState.disabled)) {
      return 0;
    }
    if (states.contains(WidgetState.dragged)) {
      return 6;
    }
    return 1;
  }

  static double _infoOverlayAlphaFor(Set<WidgetState> states) {
    if (states.contains(WidgetState.disabled)) {
      return 0;
    }
    if (states.contains(WidgetState.pressed)) {
      return 0.12;
    }
    if (states.contains(WidgetState.hovered) ||
        states.contains(WidgetState.focused) ||
        states.contains(WidgetState.dragged)) {
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
    final BorderRadius radius = BorderRadius.circular(kMd3eComicCardRadius);
    final double elevation = _elevationFor(states);
    final double infoOverlayAlpha = _infoOverlayAlphaFor(states);
    final bool showFocusRing = states.contains(WidgetState.focused);

    final bool reduceMotion = Md3eMotion.reduceMotionOf(context);
    final Duration motionDuration = Md3eMotion.motionDurationOf(
      context,
      Md3eMotion.durationShort,
    );
    final Duration elevationDuration = Md3eMotion.motionDurationOf(
      context,
      states.contains(WidgetState.dragged)
          ? Md3eMotion.durationMedium
          : Md3eMotion.durationShort,
    );
    final Curve stateEnter = Md3eMotion.curveForStateEnter(
      reduceMotion: reduceMotion,
    );
    final Curve stateExit = Md3eMotion.curveForStateExit(
      reduceMotion: reduceMotion,
    );

    const double contentHorizontalPadding = 12;
    const double titleSubtitleGap = 6;

    final double? coverProgress = widget.readProgress;
    final bool showCoverProgress =
        Md3eComicCard.showsCoverReadProgress(coverProgress);

    final Widget coverLayer = AspectRatio(
      aspectRatio: 2 / 3,
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          widget.cover,
          if (_effectiveSelectionMode)
            Positioned(
              left: kMd3eComicCardSelectionInset,
              top: kMd3eComicCardSelectionInset,
              child: Checkbox(
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
            ),
          if (showCoverProgress)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: kMd3eComicCardCoverProgressHeight,
              child: _Md3eComicCardCoverProgress(
                key: kMd3eComicCardCoverProgressKey,
                progress: widget.readProgress!,
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
        tokens.spacing.md,
        contentHorizontalPadding,
        contentHorizontalPadding,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: titleSubtitleGap,
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
          if (widget.subtitle != null)
            Text(
              widget.subtitle!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
        ],
      ),
    );

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

    Widget content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        coverLayer,
        infoBlock,
      ],
    );

    content = TweenAnimationBuilder<double>(
      tween: Tween<double>(end: disabled ? 0.38 : 1),
      duration: motionDuration,
      curve: disabled ? stateExit : stateEnter,
      builder: (BuildContext context, double opacity, Widget? child) {
        return Opacity(opacity: opacity, child: child);
      },
      child: content,
    );

    Widget card = AnimatedContainer(
      duration: motionDuration,
      curve: showFocusRing ? stateEnter : stateExit,
      decoration: BoxDecoration(
        borderRadius: radius,
        border: Border.all(
          color: showFocusRing ? scheme.primary : Colors.transparent,
          width: showFocusRing ? 2 : 0,
        ),
      ),
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(end: elevation),
        duration: elevationDuration,
        curve: elevation > 1 ? stateEnter : stateExit,
        builder: (BuildContext context, double animatedElevation, Widget? _) {
          return Material(
            color: scheme.surfaceContainerLow,
            elevation: animatedElevation,
            shadowColor: scheme.shadow,
            surfaceTintColor: scheme.surfaceTint,
            shape: RoundedRectangleBorder(borderRadius: radius),
            clipBehavior: Clip.antiAlias,
            child: content,
          );
        },
      ),
    );

    final String semanticsLabel = _semanticsLabel(
      title: widget.title,
      readProgress: coverProgress,
    );

    if (!_interactive) {
      return Semantics(
        button: widget.onTap != null || widget.onSelectionChanged != null,
        label: semanticsLabel,
        enabled: !disabled,
        checked: _effectiveSelectionMode ? _effectiveSelected : null,
        child: card,
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
            child: card,
          ),
        ),
      ),
    );
  }

  static String _semanticsLabel({
    required String title,
    required double? readProgress,
  }) {
    if (readProgress == null || readProgress <= 0) {
      return title;
    }
    final int percent = (readProgress.clamp(0.0, 1.0) * 100).round();
    return '$title，已读 $percent%';
  }
}

class _Md3eComicCardCoverProgress extends StatelessWidget {
  const _Md3eComicCardCoverProgress({
    super.key,
    required this.progress,
    required this.activeColor,
    required this.trackColor,
    required this.duration,
    required this.curve,
  });

  final double progress;
  final Color activeColor;
  final Color trackColor;
  final Duration duration;
  final Curve curve;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '阅读进度 ${(progress.clamp(0.0, 1.0) * 100).round()}%',
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final double maxWidth = constraints.maxWidth;
          return Stack(
            fit: StackFit.expand,
            children: <Widget>[
              ColoredBox(color: trackColor),
              TweenAnimationBuilder<double>(
                tween: Tween<double>(end: progress.clamp(0.0, 1.0)),
                duration: duration,
                curve: curve,
                builder: (
                  BuildContext context,
                  double value,
                  Widget? child,
                ) {
                  return Align(
                    alignment: Alignment.centerLeft,
                    child: SizedBox(
                      width: maxWidth * value,
                      height: kMd3eComicCardCoverProgressHeight,
                      child: ColoredBox(color: activeColor),
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
