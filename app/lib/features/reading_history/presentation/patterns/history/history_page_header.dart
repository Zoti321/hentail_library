import 'package:flutter/material.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/design-system/design_system.dart';
import 'package:hentai_library/features/reading_history/presentation/patterns/history/history_clear_confirm_dialog.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_symbols_icons/symbols.dart';

/// 阅读历史粘滞页头：标题 + 清空全部（需二次确认）。
class HistoryPageHeader extends StatelessWidget {
  const HistoryPageHeader({
    super.key,
    this.title,
    this.clearEnabled = true,
    this.onClearAll,
    this.onOpenNavigation,
    this.onBack,
  });

  final String? title;
  final bool clearEnabled;
  final VoidCallback? onClearAll;
  final VoidCallback? onOpenNavigation;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final WindowSizeClass sizeClass = PageLayoutSpec.of(context).sizeClass;

    return _HistoryPageHeaderToolbar(
      title: title,
      sizeClass: sizeClass,
      clearEnabled: clearEnabled,
      onClearAll: onClearAll,
      onOpenNavigation: onOpenNavigation,
      onBack: onBack,
    );
  }
}

class _HistoryPageHeaderToolbar extends StatelessWidget {
  const _HistoryPageHeaderToolbar({
    required this.title,
    required this.sizeClass,
    required this.clearEnabled,
    this.onClearAll,
    this.onOpenNavigation,
    this.onBack,
  });

  final String? title;
  final WindowSizeClass sizeClass;
  final bool clearEnabled;
  final VoidCallback? onClearAll;
  final VoidCallback? onOpenNavigation;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final M3EThemeData theme = M3ETheme.of(context);
    final M3EColorScheme scheme = theme.colorScheme;

    final bool showMenu = sizeClass.isCompact && onOpenNavigation != null;

    return PinnedToolbarChrome(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          if (onBack != null) ...<Widget>[
            PageHeaderBackButton(onPressed: onBack!),
            const SizedBox(width: 4),
          ],
          if (showMenu) ...<Widget>[
            M3EIconButton(
              icon: Icon(
                Symbols.menu,
                size: LibraryPageHeaderMetrics.actionIconSize,
                color: scheme.onSurfaceVariant,
              ),
              variant: M3EIconButtonVariant.standard,
              size: M3EIconButtonSize.sm,
              tooltip: l10n.shellOpenNavMenu,
              semanticLabel: l10n.shellOpenNavMenu,
              onPressed: onOpenNavigation,
            ),
            const SizedBox(width: 4),
          ],
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: PageTitle(title ?? l10n.historyTitle),
            ),
          ),
          M3EIconButton(
            icon: Icon(
              Symbols.delete,
              size: LibraryPageHeaderMetrics.actionIconSize,
              color: clearEnabled ? scheme.error : scheme.onSurfaceVariant,
            ),
            variant: M3EIconButtonVariant.standard,
            size: M3EIconButtonSize.sm,
            tooltip: l10n.commonClear,
            semanticLabel: l10n.commonClear,
            onPressed: clearEnabled ? () => _onClearPressed(context) : null,
          ),
        ],
      ),
    );
  }

  Future<void> _onClearPressed(BuildContext context) async {
    final bool confirmed = await showClearReadingHistoryConfirmDialog(
      context: context,
    );
    if (!confirmed) {
      return;
    }
    onClearAll?.call();
  }
}
