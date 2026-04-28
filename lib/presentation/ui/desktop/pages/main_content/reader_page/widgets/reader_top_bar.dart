import 'dart:ui';

import 'package:custom_pop_up_menu/custom_pop_up_menu.dart';
import 'package:flutter/material.dart';
import 'package:hentai_library/presentation/theme/theme.dart';
import 'package:hentai_library/presentation/ui/desktop/widgets/actions/ghost_button.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class ReaderTopBar extends StatefulWidget {
  const ReaderTopBar({
    super.key,
    required this.showControls,
    required this.isVertical,
    required this.title,
    required this.canOpenComicList,
    required this.onExit,
    required this.onSetHorizontalMode,
    required this.onSetVerticalMode,
    required this.onOpenSeriesList,
  });
  final bool showControls;
  final bool isVertical;
  final String title;
  final bool canOpenComicList;
  final Future<void> Function() onExit;
  final VoidCallback onSetHorizontalMode;
  final VoidCallback onSetVerticalMode;
  final VoidCallback onOpenSeriesList;

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
                  color: cs.readerPanelBackground,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(width: 1, color: cs.readerPanelBorder),
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
                      foregroundColor: cs.readerTextIconPrimary,
                      hoverColor: cs.readerPanelSubtle,
                      overlayColor: cs.readerPanelSubtle,
                      onPressed: () async {
                        await widget.onExit();
                      },
                    ),
                    Text(
                      widget.title,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: cs.readerTextIconPrimary,
                        letterSpacing: 0.6,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    GhostButton.icon(
                      icon: LucideIcons.list,
                      tooltip: '漫画列表',
                      semanticLabel: '打开系列漫画列表',
                      iconSize: 16,
                      size: 32,
                      borderRadius: 8,
                      foregroundColor: cs.readerTextIconPrimary,
                      hoverColor: cs.readerPanelSubtle,
                      overlayColor: cs.readerPanelSubtle,
                      onPressed: widget.canOpenComicList
                          ? widget.onOpenSeriesList
                          : null,
                    ),
                    CustomPopupMenu(
                      controller: _readModeController,
                      barrierColor: Colors.transparent,
                      pressType: PressType.singleClick,
                      showArrow: false,
                      verticalMargin: -14,
                      menuBuilder: _buildReadModeMenu,
                      child: GhostButton.icon(
                        icon: widget.isVertical
                            ? LucideIcons.arrowUpDown
                            : LucideIcons.bookOpen,
                        tooltip: '阅读模式',
                        semanticLabel: '切换阅读模式',
                        iconSize: 16,
                        size: 32,
                        borderRadius: 8,
                        foregroundColor: cs.readerTextIconPrimary,
                        hoverColor: cs.readerPanelSubtle,
                        overlayColor: cs.readerPanelSubtle,
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

  Widget _buildReadModeMenu() {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Container(
      width: 212,
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
                  color: cs.textPrimary,
                ),
              ),
            ),
            _ReadModeMenuItem(
              icon: LucideIcons.bookOpen,
              label: '翻页模式',
              description: '按页切换阅读',
              isActive: !widget.isVertical,
              onTap: () {
                _readModeController.hideMenu();
                widget.onSetHorizontalMode();
              },
            ),
            const SizedBox(height: 6),
            _ReadModeMenuItem(
              icon: LucideIcons.arrowUpDown,
              label: '长条模式',
              description: '连续纵向滚动',
              isActive: widget.isVertical,
              onTap: () {
                _readModeController.hideMenu();
                widget.onSetVerticalMode();
              },
            ),
          ],
        ),
      ),
    );
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
