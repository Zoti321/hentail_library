import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/shared/domain/models/entity/comic/tag.dart';
import 'package:hentai_library/shared/ui/theme/theme.dart';
import 'package:hentai_library/shared/ui/widgets/actions/ghost_button.dart';
import 'package:hentai_library/shared/ui/widgets/actions/popup_menu_panel_shell.dart';
import 'package:hentai_library/shared/ui/widgets/actions/popup_menu_text_item.dart';
import 'package:hentai_library/shared/ui/widgets/overlays/anchored_overlay_menu.dart';
import 'package:hentai_library/features/named_metadata/presentation/view_models/tag_management_notifier.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class MetadataTagsOverflowMenuButton extends ConsumerStatefulWidget {
  const MetadataTagsOverflowMenuButton({
    required this.onDeleteAllTags,
    super.key,
  });

  final VoidCallback onDeleteAllTags;

  @override
  ConsumerState<MetadataTagsOverflowMenuButton> createState() =>
      _MetadataTagsOverflowMenuButtonState();
}

class _MetadataTagsOverflowMenuButtonState
    extends ConsumerState<MetadataTagsOverflowMenuButton> {
  final AnchoredOverlayMenuController _controller =
      AnchoredOverlayMenuController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final ThemeData theme = Theme.of(context);
    final int tagCount = ref
        .watch(allTagsProvider)
        .maybeWhen(data: (List<Tag> tags) => tags.length, orElse: () => 0);
    final l10n = context.l10n;
    final bool enabled = tagCount > 0;

    // Material-aligned overlay coords (ancestor: overlay) — avoids
    // custom_pop_up_menu misplacement when the desktop sidebar is expanded.
    // `under` keeps the panel below the trigger like Comic/Series headers.
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: AnchoredOverlayMenu(
        controller: _controller,
        barrierColor: Colors.transparent,
        position: AnchoredOverlayMenuPosition.under,
        menuBuilder: (VoidCallback hideMenu) => _MetadataTagsOverflowMenu(
          onDeleteAllTags: enabled
              ? () {
                  hideMenu();
                  widget.onDeleteAllTags();
                }
              : null,
        ),
        child: GhostButton.icon(
          icon: LucideIcons.ellipsisVertical,
          tooltip: l10n.metadataMoreActions,
          semanticLabel: l10n.metadataMoreActions,
          iconSize: 16,
          size: 32,
          borderRadius: 8,
          foregroundColor: context.hentai.iconDefault,
          hoverColor: theme.hoverColor,
          overlayColor: theme.hoverColor,
          onPressed: enabled ? () => _controller.toggleMenu() : null,
        ),
      ),
    );
  }
}

class _MetadataTagsOverflowMenu extends StatelessWidget {
  const _MetadataTagsOverflowMenu({required this.onDeleteAllTags});

  final VoidCallback? onDeleteAllTags;

  @override
  Widget build(BuildContext context) {
    final AppThemeTokens tokens = context.tokens;
    final l10n = context.l10n;
    return PopupMenuPanelShell(
      maxWidth: 240,
      blurRadius: 6,
      shadowOffset: const Offset(0, 4),
      borderRadius: tokens.radius.xs,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: tokens.spacing.xs + 2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            PopupMenuTextItem(
              label: l10n.metadataDeleteAllTags,
              enabled: onDeleteAllTags != null,
              isDestructive: true,
              onTap: onDeleteAllTags,
            ),
          ],
        ),
      ),
    );
  }
}
