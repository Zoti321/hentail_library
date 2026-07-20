import 'package:flutter/material.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';
import 'package:hentai_library/ui/core/widgets/actions/ghost_button.dart';
import 'package:hentai_library/ui/features/reader/views/reader_page/widgets/reader_floating_panel.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class ReaderBottomBar extends StatefulWidget {
  const ReaderBottomBar({
    super.key,
    required this.showControls,
    required this.currentIndex,
    required this.totalPages,
    required this.readerAutoPlayEnabled,
    required this.showAutoPlayControls,
    required this.onPrevPage,
    required this.onNextPage,
    required this.onSetIndex,
    required this.onReaderAutoPlayEnabledChanged,
    this.onPrevSeriesComic,
    this.onNextSeriesComic,
  });

  final bool showControls;
  final int currentIndex;
  final int totalPages;
  final bool readerAutoPlayEnabled;
  final bool showAutoPlayControls;
  final VoidCallback onPrevPage;
  final Future<void> Function() onNextPage;
  final ValueChanged<int> onSetIndex;
  final ValueChanged<bool> onReaderAutoPlayEnabledChanged;
  final VoidCallback? onPrevSeriesComic;
  final VoidCallback? onNextSeriesComic;

  @override
  State<ReaderBottomBar> createState() => _ReaderBottomBarState();
}

class _ReaderBottomBarState extends State<ReaderBottomBar> {
  late double _sliderValue;
  bool _isSliding = false;

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
    final AppLocalizations l10n = context.l10n;
    final ColorScheme cs = Theme.of(context).colorScheme;
    final double bottomPadding = MediaQuery.of(context).padding.bottom + 32;
    final double targetWidth = ReaderFloatingPanel.targetBarWidth(context);
    final int safeTotalPages = widget.totalPages > 0 ? widget.totalPages : 1;
    final double sliderValue = _sliderValue.clamp(1, safeTotalPages).toDouble();
    final int displayIndex = _isSliding
        ? sliderValue.round()
        : widget.currentIndex;

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      bottom: widget.showControls ? bottomPadding : bottomPadding - 32,
      left: 0,
      right: 0,
      child: IgnorePointer(
        ignoring: !widget.showControls,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 300),
          opacity: widget.showControls ? 1.0 : 0.0,
          child: Center(
            child: ReaderFloatingPanel(
              width: targetWidth,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Column(
                spacing: 10,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Row(
                    spacing: 12,
                    children: <Widget>[
                      Text(
                        '$displayIndex',
                        style: TextStyle(
                          fontFamily: 'RobotoMono',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: cs.hentai.readerTextIconPrimary,
                        ),
                      ),
                      Expanded(
                        child: SizedBox(
                          height: 26,
                          child: SliderTheme(
                            data: SliderThemeData(
                              trackHeight: 3,
                              activeTrackColor: cs.primary,
                              inactiveTrackColor: cs.hentai.sliderInactive,
                              thumbColor: cs.primary,
                              thumbShape: const RoundSliderThumbShape(
                                enabledThumbRadius: 7,
                                elevation: 3,
                              ),
                              overlayColor: cs.hentai.readerSliderOverlay,
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
                      ),
                      Text(
                        '${widget.totalPages}',
                        style: TextStyle(
                          fontFamily: 'RobotoMono',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: cs.hentai.readerTextIconPrimary,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: <Widget>[
                      _buildSideActionGroup(
                        cs: cs,
                        children: <Widget>[
                          GhostButton.icon(
                            icon: LucideIcons.chevronLeft,
                            tooltip: l10n.readerPrevVolume,
                            semanticLabel: l10n.readerPrevVolumeSemantic,
                            iconSize: 16,
                            size: 28,
                            borderRadius: 8,
                            foregroundColor: cs.hentai.readerTextIconPrimary,
                            hoverColor: cs.hentai.readerPanelSubtle,
                            overlayColor: cs.hentai.readerPanelSubtle,
                            onPressed: widget.onPrevSeriesComic,
                          ),
                          GhostButton.icon(
                            icon: LucideIcons.chevronsLeft,
                            tooltip: l10n.readerFirstPage,
                            semanticLabel: l10n.readerFirstPageSemantic,
                            iconSize: 16,
                            size: 28,
                            borderRadius: 8,
                            foregroundColor: cs.hentai.readerTextIconPrimary,
                            hoverColor: cs.hentai.readerPanelSubtle,
                            overlayColor: cs.hentai.readerPanelSubtle,
                            onPressed: widget.totalPages > 0
                                ? () => widget.onSetIndex(1)
                                : null,
                          ),
                        ],
                      ),
                      Expanded(
                        child: Center(child: _buildNavActionGroup(cs, l10n)),
                      ),
                      _buildSideActionGroup(
                        cs: cs,
                        children: <Widget>[
                          GhostButton.icon(
                            icon: LucideIcons.chevronRight,
                            tooltip: l10n.readerNextVolume,
                            semanticLabel: l10n.readerNextVolumeSemantic,
                            iconSize: 16,
                            size: 28,
                            borderRadius: 8,
                            foregroundColor: cs.hentai.readerTextIconPrimary,
                            hoverColor: cs.hentai.readerPanelSubtle,
                            overlayColor: cs.hentai.readerPanelSubtle,
                            onPressed: widget.onNextSeriesComic,
                          ),
                          GhostButton.icon(
                            icon: LucideIcons.chevronsRight,
                            tooltip: l10n.readerLastPage,
                            semanticLabel: l10n.readerLastPageSemantic,
                            iconSize: 16,
                            size: 28,
                            borderRadius: 8,
                            foregroundColor: cs.hentai.readerTextIconPrimary,
                            hoverColor: cs.hentai.readerPanelSubtle,
                            overlayColor: cs.hentai.readerPanelSubtle,
                            onPressed: widget.totalPages > 0
                                ? () => widget.onSetIndex(widget.totalPages)
                                : null,
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSideActionGroup({
    required ColorScheme cs,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: cs.hentai.readerPanelSubtle,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 2,
        children: children,
      ),
    );
  }

  Widget _buildNavActionGroup(ColorScheme cs, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: cs.hentai.readerPanelSubtle,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          GhostButton.icon(
            icon: LucideIcons.chevronLeft,
            tooltip: l10n.readerPrevPage,
            semanticLabel: l10n.readerPrevPage,
            iconSize: 16,
            size: 28,
            borderRadius: 999,
            foregroundColor: cs.hentai.readerTextIconPrimary,
            hoverColor: cs.hentai.readerPanelSubtle,
            overlayColor: cs.hentai.readerPanelSubtle,
            onPressed: widget.onPrevPage,
          ),
          if (widget.showAutoPlayControls)
            GhostButton.icon(
              icon: widget.readerAutoPlayEnabled
                  ? LucideIcons.pause
                  : LucideIcons.play,
              tooltip: widget.readerAutoPlayEnabled
                  ? l10n.readerDisableAutoPlay
                  : l10n.readerEnableAutoPlay,
              semanticLabel: widget.readerAutoPlayEnabled
                  ? l10n.readerDisableAutoPlay
                  : l10n.readerEnableAutoPlay,
              iconSize: 14,
              size: 28,
              borderRadius: 999,
              foregroundColor: widget.readerAutoPlayEnabled
                  ? cs.primary
                  : cs.hentai.readerTextIconPrimary,
              hoverColor: cs.hentai.readerPanelSubtle,
              overlayColor: cs.hentai.readerPanelSubtle,
              onPressed: () {
                widget.onReaderAutoPlayEnabledChanged(
                  !widget.readerAutoPlayEnabled,
                );
              },
            ),
          GhostButton.icon(
            icon: LucideIcons.chevronRight,
            tooltip: l10n.readerNextPage,
            semanticLabel: l10n.readerNextPage,
            iconSize: 16,
            size: 28,
            borderRadius: 999,
            foregroundColor: cs.hentai.readerTextIconPrimary,
            hoverColor: cs.hentai.readerPanelSubtle,
            overlayColor: cs.hentai.readerPanelSubtle,
            onPressed: widget.onNextPage,
          ),
        ],
      ),
    );
  }
}
