import 'package:custom_pop_up_menu/custom_pop_up_menu.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';
import 'package:hentai_library/ui/core/widgets/actions/ghost_button.dart';
import 'package:hentai_library/ui/core/widgets/actions/popup_menu_panel_shell.dart';
import 'package:hentai_library/ui/features/metadata/state/tag_dictionary_import_controller.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class MetadataTagsOverflowMenuButton extends ConsumerStatefulWidget {
  const MetadataTagsOverflowMenuButton({
    required this.onImportFromNetwork,
    required this.onImportFromLocalFile,
    super.key,
  });

  final VoidCallback onImportFromNetwork;
  final VoidCallback onImportFromLocalFile;

  @override
  ConsumerState<MetadataTagsOverflowMenuButton> createState() =>
      _MetadataTagsOverflowMenuButtonState();
}

class _MetadataTagsOverflowMenuButtonState
    extends ConsumerState<MetadataTagsOverflowMenuButton> {
  final CustomPopupMenuController _controller = CustomPopupMenuController();

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final ThemeData theme = Theme.of(context);
    final bool running = ref.watch(tagDictionaryImportControllerProvider).running;
    final l10n = context.l10n;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: CustomPopupMenu(
        controller: _controller,
        barrierColor: Colors.transparent,
        pressType: PressType.singleClick,
        showArrow: false,
        verticalMargin: -32,
        menuBuilder: () => _MetadataTagsOverflowMenu(
          onImportFromNetwork: running
              ? null
              : () {
                  _controller.hideMenu();
                  widget.onImportFromNetwork();
                },
          onImportFromLocalFile: running
              ? null
              : () {
                  _controller.hideMenu();
                  widget.onImportFromLocalFile();
                },
        ),
        child: GhostButton.icon(
          icon: LucideIcons.ellipsisVertical,
          tooltip: l10n.metadataMoreActions,
          semanticLabel: l10n.metadataMoreActions,
          iconSize: 16,
          size: 32,
          borderRadius: 8,
          foregroundColor: cs.hentai.iconDefault,
          hoverColor: theme.hoverColor,
          overlayColor: theme.hoverColor,
          onPressed: running ? null : _controller.showMenu,
        ),
      ),
    );
  }
}

class _MetadataTagsOverflowMenu extends StatelessWidget {
  const _MetadataTagsOverflowMenu({
    required this.onImportFromNetwork,
    required this.onImportFromLocalFile,
  });

  final VoidCallback? onImportFromNetwork;
  final VoidCallback? onImportFromLocalFile;

  @override
  Widget build(BuildContext context) {
    final AppThemeTokens tokens = context.tokens;
    final l10n = context.l10n;
    return PopupMenuPanelShell(
      width: 240,
      blurRadius: 6,
      shadowOffset: const Offset(0, 4),
      borderRadius: tokens.radius.xs,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            _MetadataTagsOverflowMenuItem(
              icon: LucideIcons.cloudDownload,
              label: l10n.metadataImportEhTagFromNetwork,
              onTap: onImportFromNetwork,
            ),
            _MetadataTagsOverflowMenuItem(
              icon: LucideIcons.file,
              label: l10n.metadataImportEhTagFromLocalFile,
              onTap: onImportFromLocalFile,
            ),
          ],
        ),
      ),
    );
  }
}

class _MetadataTagsOverflowMenuItem extends StatelessWidget {
  const _MetadataTagsOverflowMenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final bool enabled = onTap != null;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: <Widget>[
              Icon(
                icon,
                size: 16,
                color: enabled ? cs.hentai.iconDefault : cs.outline,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    color: enabled ? cs.hentai.textPrimary : cs.outline,
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
