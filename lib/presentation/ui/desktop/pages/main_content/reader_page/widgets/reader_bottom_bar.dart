import 'dart:ui';

import 'package:custom_pop_up_menu/custom_pop_up_menu.dart';
import 'package:flutter/material.dart';
import 'package:hentai_library/theme/theme.dart';
import 'package:hentai_library/presentation/ui/desktop/widgets/actions/ghost_button.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class ReaderBottomBar extends StatefulWidget {
  const ReaderBottomBar({
    super.key,
    required this.showControls,
    required this.currentIndex,
    required this.totalPages,
    required this.readerAutoPlayEnabled,
    required this.readerAutoPlayIntervalSeconds,
    required this.readerDimLevel,
    required this.readerWindowFullscreen,
    required this.onPrevPage,
    required this.onNextPage,
    required this.onSetIndex,
    required this.onReaderAutoPlayEnabledChanged,
    required this.onReaderAutoPlayIntervalSecondsChanged,
    required this.onReaderDimLevelChanged,
    required this.onToggleFullscreen,
  });
  final bool showControls;
  final int currentIndex;
  final int totalPages;
  final bool readerAutoPlayEnabled;
  final int readerAutoPlayIntervalSeconds;
  final double readerDimLevel;
  final bool readerWindowFullscreen;
  final VoidCallback onPrevPage;
  final VoidCallback onNextPage;
  final ValueChanged<int> onSetIndex;
  final ValueChanged<bool> onReaderAutoPlayEnabledChanged;
  final ValueChanged<int> onReaderAutoPlayIntervalSecondsChanged;
  final ValueChanged<double> onReaderDimLevelChanged;
  final Future<void> Function() onToggleFullscreen;

  @override
  State<ReaderBottomBar> createState() => _ReaderBottomBarState();
}

class _ReaderBottomBarState extends State<ReaderBottomBar> {
  late double _sliderValue;
  bool _isSliding = false;
  final CustomPopupMenuController _intervalMenuController =
      CustomPopupMenuController();
  final CustomPopupMenuController _dimMenuController =
      CustomPopupMenuController();

  @override
  void initState() {
    super.initState();
    _sliderValue = widget.currentIndex.toDouble();
  }

  @override
  void didUpdateWidget(covariant ReaderBottomBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isSliding && oldWidget.currentIndex != widget.currentIndex) {
      _sliderValue = widget.currentIndex.toDouble();
    }
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final double bottomPadding = MediaQuery.of(context).padding.bottom + 32;
    final int safeTotalPages = widget.totalPages > 0 ? widget.totalPages : 1;
    final double sliderValue = _sliderValue.clamp(1, safeTotalPages).toDouble();
    final int displayIndex = _isSliding
        ? sliderValue.round()
        : widget.currentIndex;

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      bottom: widget.showControls ? bottomPadding : bottomPadding - 32,
      left: 16,
      right: 16,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 300),
        opacity: widget.showControls ? 1.0 : 0.0,
        child: Center(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 820),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: cs.floatingUiBackground,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: cs.readerPanelBorder, width: 1),
                ),
                child: Column(
                  spacing: 8,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      height: 26,
                      child: SliderTheme(
                        data: SliderThemeData(
                          trackHeight: 3,
                          activeTrackColor: cs.sliderActive,
                          inactiveTrackColor: cs.sliderInactive,
                          thumbColor: cs.activeButtonBg,
                          thumbShape: const RoundSliderThumbShape(
                            enabledThumbRadius: 7,
                            elevation: 3,
                          ),
                          overlayColor: cs.readerSliderOverlay,
                          overlayShape: const RoundSliderOverlayShape(
                            overlayRadius: 14,
                          ),
                          trackShape: const RoundedRectSliderTrackShape(),
                        ),
                        child: Slider(
                          value: sliderValue,
                          min: 1,
                          max: safeTotalPages.toDouble(),
                          onChangeStart: (double value) {
                            setState(() {
                              _isSliding = true;
                              _sliderValue = value;
                            });
                          },
                          onChanged: (double val) {
                            setState(() {
                              _sliderValue = val;
                            });
                          },
                          onChangeEnd: (double val) {
                            final int nextIndex = val.round().clamp(
                              1,
                              safeTotalPages,
                            );
                            setState(() {
                              _isSliding = false;
                              _sliderValue = nextIndex.toDouble();
                            });
                            widget.onSetIndex(nextIndex);
                          },
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          '$displayIndex / ${widget.totalPages}',
                          style: TextStyle(
                            fontFamily: 'RobotoMono',
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: cs.readerTextIconPrimary,
                          ),
                        ),
                        const Spacer(),
                        _buildNavActionGroup(cs),
                        const Spacer(),

                        _buildIntervalMenuButton(cs),
                        const SizedBox(width: 8),
                        _buildDimMenuButton(cs),
                        const SizedBox(width: 8),
                        GhostButton.icon(
                          icon: widget.readerWindowFullscreen
                              ? LucideIcons.minimize2
                              : LucideIcons.maximize2,
                          tooltip: widget.readerWindowFullscreen
                              ? '退出全屏'
                              : '全屏',
                          semanticLabel: widget.readerWindowFullscreen
                              ? '退出全屏'
                              : '进入全屏',
                          iconSize: 16,
                          size: 30,
                          borderRadius: 8,
                          foregroundColor: cs.readerTextIconPrimary,
                          hoverColor: cs.readerPanelSubtle,
                          overlayColor: cs.readerPanelSubtle,
                          onPressed: () async {
                            await widget.onToggleFullscreen();
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavActionGroup(ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: cs.readerPanelSubtle,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: cs.readerPanelSubtleBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GhostButton.icon(
            icon: LucideIcons.chevronLeft,
            tooltip: '上一页',
            semanticLabel: '上一页',
            iconSize: 16,
            size: 28,
            borderRadius: 999,
            foregroundColor: cs.readerTextIconPrimary,
            hoverColor: cs.readerPanelSubtle,
            overlayColor: cs.readerPanelSubtle,
            onPressed: widget.onPrevPage,
          ),
          GhostButton.icon(
            icon: widget.readerAutoPlayEnabled
                ? LucideIcons.pause
                : LucideIcons.play,
            tooltip: widget.readerAutoPlayEnabled ? '关闭自动播放' : '开启自动播放',
            semanticLabel: widget.readerAutoPlayEnabled ? '关闭自动播放' : '开启自动播放',
            iconSize: 14,
            size: 28,
            borderRadius: 999,
            foregroundColor: widget.readerAutoPlayEnabled
                ? cs.primary
                : cs.readerTextIconPrimary,
            hoverColor: cs.readerPanelSubtle,
            overlayColor: cs.readerPanelSubtle,
            onPressed: () {
              widget.onReaderAutoPlayEnabledChanged(
                !widget.readerAutoPlayEnabled,
              );
            },
          ),
          GhostButton.icon(
            icon: LucideIcons.chevronRight,
            tooltip: '下一页',
            semanticLabel: '下一页',
            iconSize: 16,
            size: 28,
            borderRadius: 999,
            foregroundColor: cs.readerTextIconPrimary,
            hoverColor: cs.readerPanelSubtle,
            overlayColor: cs.readerPanelSubtle,
            onPressed: widget.onNextPage,
          ),
        ],
      ),
    );
  }

  Widget _buildIntervalMenuButton(ColorScheme cs) {
    return CustomPopupMenu(
      controller: _intervalMenuController,
      barrierColor: Colors.transparent,
      position: PreferredPosition.top,
      pressType: PressType.singleClick,
      showArrow: false,
      verticalMargin: 48,
      menuBuilder: _buildIntervalMenu,
      child: GhostButton.icon(
        icon: LucideIcons.timer,
        tooltip: '自动播放间隔',
        semanticLabel: '调整自动播放间隔',
        iconSize: 16,
        size: 30,
        borderRadius: 8,
        foregroundColor: cs.readerTextIconPrimary,
        hoverColor: cs.readerPanelSubtle,
        overlayColor: cs.readerPanelSubtle,
        onPressed: () => _intervalMenuController.toggleMenu(),
      ),
    );
  }

  Widget _buildDimMenuButton(ColorScheme cs) {
    return CustomPopupMenu(
      controller: _dimMenuController,
      barrierColor: Colors.transparent,
      position: PreferredPosition.top,
      pressType: PressType.singleClick,
      showArrow: false,
      verticalMargin: 48,
      menuBuilder: _buildDimMenu,
      child: GhostButton.icon(
        icon: LucideIcons.sunMoon,
        tooltip: '亮度调整',
        semanticLabel: '调整阅读亮度',
        iconSize: 16,
        size: 30,
        borderRadius: 8,
        foregroundColor: cs.readerTextIconPrimary,
        hoverColor: cs.readerPanelSubtle,
        overlayColor: cs.readerPanelSubtle,
        onPressed: () => _dimMenuController.toggleMenu(),
      ),
    );
  }

  Widget _buildIntervalMenu() {
    final ColorScheme cs = Theme.of(context).colorScheme;
    int localInterval = _buildClampedInterval(
      widget.readerAutoPlayIntervalSeconds,
    );
    return Container(
      width: 232,
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.borderSubtle),
        boxShadow: [
          BoxShadow(
            color: cs.cardShadowHover,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
        child: StatefulBuilder(
          builder: (BuildContext context, StateSetter setMenuState) {
            final bool canDecrease = localInterval > 1;
            final bool canIncrease = localInterval < 60;
            void updateLocalIntervalByStep(int step) {
              final int nextValue = _buildClampedInterval(localInterval + step);
              if (nextValue == localInterval) {
                return;
              }
              setMenuState(() {
                localInterval = nextValue;
              });
              widget.onReaderAutoPlayIntervalSecondsChanged(nextValue);
            }
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '自动播放间隔',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: cs.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '与设置页保持一致，范围 1-60 秒',
                  style: TextStyle(fontSize: 11, color: cs.textTertiary),
                ),
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: cs.borderSubtle),
                  ),
                  child: Row(
                    children: [
                      GhostButton.icon(
                        icon: LucideIcons.minus,
                        size: 24,
                        tooltip: '',
                        semanticLabel: '减少自动播放间隔',
                        onPressed: canDecrease
                            ? () => updateLocalIntervalByStep(-1)
                            : null,
                        iconSize: 14,
                        borderRadius: 8,
                        foregroundColor: cs.textPrimary,
                        hoverColor: cs.readerPanelSubtle,
                        overlayColor: cs.readerPanelSubtle,
                      ),
                      Expanded(
                        child: Text(
                          '$localInterval s',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: cs.textPrimary,
                          ),
                        ),
                      ),
                      GhostButton.icon(
                        icon: LucideIcons.plus,
                        size: 24,
                        tooltip: '',
                        semanticLabel: '增加自动播放间隔',
                        onPressed: canIncrease
                            ? () => updateLocalIntervalByStep(1)
                            : null,
                        iconSize: 14,
                        borderRadius: 8,
                        foregroundColor: cs.textPrimary,
                        hoverColor: cs.readerPanelSubtle,
                        overlayColor: cs.readerPanelSubtle,
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildDimMenu() {
    final ColorScheme cs = Theme.of(context).colorScheme;
    const double minBrightnessPercent = 20;
    const double maxBrightnessPercent = 100;
    const int brightnessDivisions = 16;
    double localBrightness =
        (1 - widget.readerDimLevel).clamp(
          minBrightnessPercent / 100,
          maxBrightnessPercent / 100,
        ) *
        100;
    return Container(
      width: 52,
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.borderSubtle),
        boxShadow: [
          BoxShadow(
            color: cs.cardShadowHover,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: StatefulBuilder(
        builder: (BuildContext context, StateSetter setMenuState) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  localBrightness.round().toString(),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: cs.textSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                SizedBox(
                  height: 96,
                  child: RotatedBox(
                    quarterTurns: 3,
                    child: SliderTheme(
                      data: SliderThemeData(
                        trackHeight: 2.5,
                        activeTrackColor: cs.sliderActive,
                        inactiveTrackColor: cs.sliderInactive,
                        thumbColor: cs.activeButtonBg,
                        overlayColor: cs.readerSliderOverlay,
                        thumbShape: const RoundSliderThumbShape(
                          enabledThumbRadius: 4,
                          elevation: 2,
                        ),
                        overlayShape: const RoundSliderOverlayShape(
                          overlayRadius: 6,
                        ),
                      ),
                      child: Slider(
                        value: localBrightness.clamp(
                          minBrightnessPercent,
                          maxBrightnessPercent,
                        ),
                        min: minBrightnessPercent,
                        max: maxBrightnessPercent,
                        divisions: brightnessDivisions,
                        onChanged: (double value) {
                          final double nextBrightness = double.parse(
                            value.toStringAsFixed(2),
                          );
                          final double nextDimLevel =
                              1 - (nextBrightness / 100);
                          setMenuState(() {
                            localBrightness = nextBrightness;
                          });
                          widget.onReaderDimLevelChanged(nextDimLevel);
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  int _buildClampedInterval(int value) {
    return value.clamp(1, 60);
  }
}
