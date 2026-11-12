import 'package:flutter/material.dart';
import 'package:hentai_library/design-system/design_system.dart';
import 'package:hentai_library/shared/ui/widgets/selection/segmented_capsule_bar_metrics.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// One mutually exclusive segment in [SegmentedCapsuleBar].
class SegmentedCapsuleSegment {
  const SegmentedCapsuleSegment({required this.label, this.semanticLabel});

  final String label;
  final String? semanticLabel;
}

/// Kazumi-style horizontal **segmented control**: spaced text pills with a single
/// sliding selection block ([SpringPositioned]).
class SegmentedCapsuleBar extends StatefulWidget {
  const SegmentedCapsuleBar({
    super.key,
    required this.segments,
    required this.selectedIndex,
    required this.onSelected,
  }) : assert(segments.length > 0),
       assert(selectedIndex >= 0 && selectedIndex < segments.length);

  final List<SegmentedCapsuleSegment> segments;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  State<SegmentedCapsuleBar> createState() => _SegmentedCapsuleBarState();
}

class _SegmentedCapsuleBarState extends State<SegmentedCapsuleBar> {
  final GlobalKey _stackKey = GlobalKey();
  late List<GlobalKey> _segmentKeys;

  double _indicatorLeft = 0;
  double _indicatorWidth = 0;

  @override
  void initState() {
    super.initState();
    _segmentKeys = _keysForLength(widget.segments.length);
    WidgetsBinding.instance.addPostFrameCallback(_measureIndicator);
  }

  @override
  void didUpdateWidget(covariant SegmentedCapsuleBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.segments.length != widget.segments.length) {
      _segmentKeys = _keysForLength(widget.segments.length);
    }
    if (oldWidget.selectedIndex != widget.selectedIndex ||
        oldWidget.segments.length != widget.segments.length) {
      WidgetsBinding.instance.addPostFrameCallback(_measureIndicator);
    }
  }

  List<GlobalKey> _keysForLength(int length) {
    return List<GlobalKey>.generate(length, (_) => GlobalKey());
  }

  void _measureIndicator(Duration _) {
    if (!mounted) {
      return;
    }
    final RenderBox? stackBox =
        _stackKey.currentContext?.findRenderObject() as RenderBox?;
    final BuildContext? segmentContext =
        _segmentKeys[widget.selectedIndex].currentContext;
    final RenderBox? segmentBox =
        segmentContext?.findRenderObject() as RenderBox?;
    if (stackBox == null || segmentBox == null || !segmentBox.hasSize) {
      return;
    }
    final Offset topLeft = segmentBox.localToGlobal(
      Offset.zero,
      ancestor: stackBox,
    );
    final double left = topLeft.dx;
    final double width = segmentBox.size.width;
    if (left == _indicatorLeft && width == _indicatorWidth) {
      return;
    }
    setState(() {
      _indicatorLeft = left;
      _indicatorWidth = width;
    });
  }

  @override
  Widget build(BuildContext context) {
    final M3EThemeData theme = M3ETheme.of(context);
    final M3EColorScheme scheme = theme.colorScheme;
    final M3ETypeScale type = theme.typeScale;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        height: SegmentedCapsuleBarMetrics.barHeight,
        child: Stack(
          key: _stackKey,
          clipBehavior: Clip.none,
          alignment: Alignment.centerLeft,
          children: <Widget>[
            if (_indicatorWidth > 0)
              SpringPositioned(
                rect: Rect.fromLTWH(
                  _indicatorLeft,
                  0,
                  _indicatorWidth,
                  SegmentedCapsuleBarMetrics.barHeight,
                ),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: scheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(
                      SegmentedCapsuleBarMetrics.pillBorderRadius(),
                    ),
                  ),
                ),
              ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                for (int i = 0; i < widget.segments.length; i++)
                  Padding(
                    padding: EdgeInsets.only(
                      right: i < widget.segments.length - 1
                          ? SegmentedCapsuleBarMetrics.segmentGap
                          : 0,
                    ),
                    child: _SegmentTapTarget(
                      key: _segmentKeys[i],
                      selected: i == widget.selectedIndex,
                      label: widget.segments[i].label,
                      semanticLabel:
                          widget.segments[i].semanticLabel ??
                          widget.segments[i].label,
                      selectedStyle: type.labelLarge.copyWith(
                        fontWeight: FontWeight.w600,
                        color: scheme.onSecondaryContainer,
                      ),
                      unselectedStyle: type.labelLarge.copyWith(
                        fontWeight: FontWeight.w500,
                        color: scheme.onSurfaceVariant,
                      ),
                      onTap: () {
                        if (i == widget.selectedIndex) {
                          return;
                        }
                        widget.onSelected(i);
                      },
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SegmentTapTarget extends StatelessWidget {
  const _SegmentTapTarget({
    super.key,
    required this.selected,
    required this.label,
    required this.semanticLabel,
    required this.selectedStyle,
    required this.unselectedStyle,
    required this.onTap,
  });

  final bool selected;
  final String label;
  final String semanticLabel;
  final TextStyle selectedStyle;
  final TextStyle unselectedStyle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final M3EColorScheme scheme = M3ETheme.of(context).colorScheme;

    return Semantics(
      button: true,
      selected: selected,
      label: semanticLabel,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          customBorder: const StadiumBorder(),
          overlayColor: WidgetStateProperty.resolveWith((
            Set<WidgetState> states,
          ) {
            if (states.contains(WidgetState.pressed)) {
              return scheme.onSurface.withValues(alpha: 0.08);
            }
            if (states.contains(WidgetState.hovered)) {
              return scheme.onSurface.withValues(alpha: 0.04);
            }
            return null;
          }),
          child: SizedBox(
            height: SegmentedCapsuleBarMetrics.barHeight,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: SegmentedCapsuleBarMetrics.segmentHorizontalPadding,
              ),
              child: Center(
                child: Text(
                  label,
                  maxLines: 1,
                  style: selected ? selectedStyle : unselectedStyle,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
