import 'dart:ui';

import 'package:custom_pop_up_menu/custom_pop_up_menu.dart';
import 'package:flutter/material.dart';
import 'package:hentai_library/domain/reading/read_session.dart';
import 'package:hentai_library/domain/reading/reading_mode.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';
import 'package:hentai_library/ui/core/widgets/actions/ghost_button.dart';
import 'package:hentai_library/ui/features/reader/views/reader_page/widgets/reader_route_context.dart';
import 'package:hentai_library/ui/features/reader/views/reader_page/widgets/reader_series_nav.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class ReaderTopBar extends StatefulWidget {
  const ReaderTopBar({
    super.key,
    required this.showControls,
    required this.readingMode,
    required this.title,
    required this.session,
    required this.onExit,
    required this.onReadingModeChanged,
    this.navContext,
  });
  final bool showControls;
  final ReadingMode readingMode;
  final String title;
  final ReadSessionRouteParams session;
  final ReaderNavContextData? navContext;
  final Future<void> Function() onExit;
  final ValueChanged<ReadingMode> onReadingModeChanged;

  @override
  State<ReaderTopBar> createState() => _ReaderTopBarState();
}

class _ReaderTopBarState extends State<ReaderTopBar> {
  final CustomPopupMenuController _readModeController =
      CustomPopupMenuController();

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final double topPadding = MediaQuery.of(context).padding.top + 24;
    final double viewportWidth = MediaQuery.sizeOf(context).width;
    final double targetWidth = (viewportWidth * 0.8)
        .clamp(560, 1120)
        .toDouble();
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      top: widget.showControls ? topPadding : topPadding - 20,
      left: 0,
      right: 0,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 300),
        opacity: widget.showControls ? 1.0 : 0.0,
        child: Center(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: Container(
                width: targetWidth,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: cs.hentai.readerPanelBackground,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    width: 1,
                    color: cs.hentai.readerPanelBorder,
                  ),
                ),
                child: Row(
                  spacing: 8,
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    GhostButton.icon(
                      icon: LucideIcons.arrowLeft,
                      tooltip: '返回',
                      semanticLabel: '返回上一页',
                      iconSize: 16,
                      size: 28,
                      borderRadius: 8,
                      foregroundColor: cs.hentai.readerTextIconPrimary,
                      hoverColor: cs.hentai.readerPanelSubtle,
                      overlayColor: cs.hentai.readerPanelSubtle,
                      onPressed: () async {
                        await widget.onExit();
                      },
                    ),
                    if (widget.navContext != null)
                      ReaderSeriesNav(
                        navContext: widget.navContext!,
                        session: widget.session,
                      ),
                    Expanded(
                      child: _ReaderTopBarTitle(
                        title: widget.title,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: cs.hentai.readerTextIconPrimary,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ),
                    CustomPopupMenu(
                      controller: _readModeController,
                      barrierColor: Colors.transparent,
                      pressType: PressType.singleClick,
                      showArrow: false,
                      verticalMargin: -14,
                      menuBuilder: _buildReadModeMenu,
                      child: GhostButton.icon(
                        icon: _modeIcon(widget.readingMode),
                        tooltip: '阅读模式',
                        semanticLabel: '切换阅读模式',
                        iconSize: 16,
                        size: 32,
                        borderRadius: 8,
                        foregroundColor: cs.hentai.readerTextIconPrimary,
                        hoverColor: cs.hentai.readerPanelSubtle,
                        overlayColor: cs.hentai.readerPanelSubtle,
                        onPressed: () => _readModeController.toggleMenu(),
                      ),
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

  IconData _modeIcon(ReadingMode mode) {
    return switch (mode) {
      ReadingMode.continuousVertical => LucideIcons.arrowUpDown,
      ReadingMode.paged => LucideIcons.bookOpen,
      ReadingMode.dualPage ||
      ReadingMode.dualPageNoCover => LucideIcons.bookCopy,
    };
  }

  Widget _buildReadModeMenu() {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Container(
      width: 240,
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.hentai.borderSubtle),
        boxShadow: [
          BoxShadow(
            color: cs.hentai.cardShadowHover,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 2, 4, 8),
              child: Text(
                '阅读模式',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: cs.hentai.textPrimary,
                ),
              ),
            ),
            for (final _ReadModeOption option in _readModeOptions) ...<Widget>[
              _ReadModeMenuItem(
                icon: option.icon,
                label: option.label,
                description: option.description,
                isActive: widget.readingMode == option.mode,
                onTap: () {
                  _readModeController.hideMenu();
                  widget.onReadingModeChanged(option.mode);
                },
              ),
              if (option != _readModeOptions.last) const SizedBox(height: 6),
            ],
          ],
        ),
      ),
    );
  }
}

const List<_ReadModeOption> _readModeOptions = <_ReadModeOption>[
  _ReadModeOption(
    mode: ReadingMode.paged,
    icon: LucideIcons.bookOpen,
    label: '翻页模式',
    description: '按页切换阅读',
  ),
  _ReadModeOption(
    mode: ReadingMode.continuousVertical,
    icon: LucideIcons.arrowUpDown,
    label: '长条模式',
    description: '连续纵向滚动',
  ),
  _ReadModeOption(
    mode: ReadingMode.dualPage,
    icon: LucideIcons.bookCopy,
    label: '双页模式',
    description: '左右双页阅读',
  ),
  _ReadModeOption(
    mode: ReadingMode.dualPageNoCover,
    icon: LucideIcons.bookCopy,
    label: '双页（封面独立）',
    description: '封面单独一页',
  ),
];

class _ReadModeOption {
  const _ReadModeOption({
    required this.mode,
    required this.icon,
    required this.label,
    required this.description,
  });

  final ReadingMode mode;
  final IconData icon;
  final String label;
  final String description;
}

class _ReaderTopBarTitle extends StatelessWidget {
  const _ReaderTopBarTitle({required this.title, required this.style});

  final String title;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    final Widget text = Text(
      title,
      style: style,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        if (!_isTextTruncated(
          context: context,
          maxWidth: constraints.maxWidth,
        )) {
          return text;
        }
        return Tooltip(
          message: title,
          waitDuration: const Duration(milliseconds: 400),
          child: text,
        );
      },
    );
  }

  bool _isTextTruncated({
    required BuildContext context,
    required double maxWidth,
  }) {
    final TextPainter textPainter = TextPainter(
      text: TextSpan(text: title, style: style),
      maxLines: 1,
      textDirection: Directionality.of(context),
    )..layout(maxWidth: maxWidth);
    return textPainter.didExceedMaxLines;
  }
}

class _ReadModeMenuItem extends StatelessWidget {
  const _ReadModeMenuItem({
    required this.icon,
    required this.label,
    required this.description,
    required this.isActive,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String description;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final Color itemBackground = cs.primary.withAlpha(20);
    final Color itemBorder = cs.primary.withAlpha(88);
    final Color titleColor = cs.primary;
    final Color iconColor = cs.primary;
    return Material(
      color: itemBackground,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: itemBorder),
          ),
          child: Row(
            children: [
              Icon(icon, size: 16, color: iconColor),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: titleColor,
                      ),
                    ),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: cs.primary.withAlpha(180),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                isActive ? LucideIcons.check : LucideIcons.circle,
                size: 11,
                color: cs.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
