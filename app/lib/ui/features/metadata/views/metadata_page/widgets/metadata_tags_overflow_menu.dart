import 'package:custom_pop_up_menu/custom_pop_up_menu.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/domain/models/entity/comic/tag.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';
import 'package:hentai_library/ui/core/widgets/actions/ghost_button.dart';
import 'package:hentai_library/ui/core/widgets/actions/popup_menu_panel_shell.dart';
import 'package:hentai_library/ui/features/metadata/view_models/tag_management_notifier.dart';
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
  final CustomPopupMenuController _controller = CustomPopupMenuController();

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final ThemeData theme = Theme.of(context);
    final int tagCount = ref
        .watch(allTagsProvider)
        .maybeWhen(data: (List<Tag> tags) => tags.length, orElse: () => 0);
    final l10n = context.l10n;
    final bool enabled = tagCount > 0;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: CustomPopupMenu(
        controller: _controller,
        barrierColor: Colors.transparent,
        pressType: PressType.singleClick,
        showArrow: false,
        verticalMargin: -32,
        menuBuilder: () => _MetadataTagsOverflowMenu(
          onDeleteAllTags: enabled
              ? () {
                  _controller.hideMenu();
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
          foregroundColor: cs.hentai.iconDefault,
          hoverColor: theme.hoverColor,
          overlayColor: theme.hoverColor,
          onPressed: enabled ? _controller.showMenu : null,
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
            _MetadataTagsPopupMenuItem(
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

class _MetadataTagsPopupMenuItem extends HookWidget {
  const _MetadataTagsPopupMenuItem({
    required this.label,
    required this.enabled,
    this.isDestructive = false,
    this.onTap,
  });

  final String label;
  final bool enabled;
  final bool isDestructive;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    final AppThemeTokens tokens = context.tokens;
    final HentaiColorScheme h = cs.hentai;
    final ValueNotifier<bool> hovered = useState(false);

    final Color idleBackground = cs.surface;
    final Color dangerHover = Color.lerp(
      idleBackground,
      h.contextMenuDanger,
      0.2,
    )!;

    final Color background;
    final Color foreground;
    if (!enabled) {
      background = idleBackground;
      foreground = h.textTertiary;
    } else if (hovered.value) {
      background = isDestructive ? dangerHover : h.contextMenuHover;
      foreground = isDestructive ? h.contextMenuDanger : h.textPrimary;
    } else {
      background = idleBackground;
      foreground = h.textPrimary;
    }

    final TextStyle labelStyle =
        (theme.textTheme.bodyMedium ?? const TextStyle()).copyWith(
          fontSize: tokens.text.bodySm,
          color: foreground,
        );

    return MouseRegion(
      onEnter: enabled ? (_) => hovered.value = true : null,
      onExit: enabled ? (_) => hovered.value = false : null,
      cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          color: background,
          padding: EdgeInsets.symmetric(
            horizontal: tokens.spacing.md,
            vertical: tokens.spacing.sm,
          ),
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 120),
            curve: Curves.easeOut,
            style: labelStyle,
            child: Text(label, textAlign: TextAlign.start),
          ),
        ),
      ),
    );
  }
}
