import 'package:custom_pop_up_menu/custom_pop_up_menu.dart';
import 'package:flutter/material.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';
import 'package:hentai_library/ui/core/widgets/actions/ghost_button.dart';
import 'package:hentai_library/ui/core/widgets/feedback/custom_toast.dart';
import 'package:hentai_library/ui/features/reader/views/reader_page/widgets/reader_floating_panel.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class ReaderOverflowMenuButton extends StatefulWidget {
  const ReaderOverflowMenuButton({super.key});

  @override
  State<ReaderOverflowMenuButton> createState() =>
      _ReaderOverflowMenuButtonState();
}

class _ReaderOverflowMenuButtonState extends State<ReaderOverflowMenuButton> {
  final CustomPopupMenuController _menuController = CustomPopupMenuController();

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return CustomPopupMenu(
      controller: _menuController,
      barrierColor: Colors.transparent,
      pressType: PressType.singleClick,
      showArrow: false,
      verticalMargin: -14,
      menuBuilder: () => ReaderFloatingMenuPanel(
        width: 240,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            _ReaderOverflowMenuItem(
              icon: LucideIcons.image,
              label: '将当前页设为漫画/系列封面',
              onTap: () {
                _menuController.hideMenu();
                showCustomToast(context, message: '该功能即将推出');
              },
            ),
          ],
        ),
      ),
      child: GhostButton.icon(
        icon: LucideIcons.ellipsisVertical,
        tooltip: '更多',
        semanticLabel: '更多阅读选项',
        iconSize: 16,
        size: 32,
        borderRadius: 8,
        foregroundColor: cs.hentai.readerTextIconPrimary,
        hoverColor: cs.hentai.readerPanelSubtle,
        overlayColor: cs.hentai.readerPanelSubtle,
        onPressed: () => _menuController.toggleMenu(),
      ),
    );
  }
}

class _ReaderOverflowMenuItem extends StatelessWidget {
  const _ReaderOverflowMenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            spacing: 10,
            children: <Widget>[
              Icon(icon, size: 16, color: cs.hentai.readerTextIconPrimary),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    color: cs.hentai.readerTextIconPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
