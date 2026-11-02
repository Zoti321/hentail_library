import 'package:flutter/material.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/shared/ui/layout/breakpoints.dart';
import 'package:hentai_library/shared/ui/layout/page_layout_spec.dart';
import 'package:hentai_library/features/reading_history/presentation/patterns/history/history_clear_confirm_dialog.dart';
import 'package:hentai_library/shared/ui/patterns/library/library_page_header_metrics.dart';
import 'package:hentai_library/shared/ui/patterns/shared/md3e_page_title.dart';
import 'package:hentai_library/shared/ui/patterns/shared/pinned_toolbar_chrome.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_symbols_icons/symbols.dart';

/// 阅读历史粘滞页头：标题 + 清空全部（需二次确认）。
class Md3eHistoryPageHeader extends StatelessWidget {
  const Md3eHistoryPageHeader({
    super.key,
    this.title,
    this.clearEnabled = true,
    this.onClearAll,
    this.onOpenNavigation,
  });

  final String? title;
  final bool clearEnabled;
  final VoidCallback? onClearAll;
  final VoidCallback? onOpenNavigation;

  @override
  Widget build(BuildContext context) {
    final Md3eWindowSizeClass sizeClass = Md3ePageLayoutSpec.of(context)
        .sizeClass;

    return _Md3eHistoryPageHeaderToolbar(
      title: title,
      sizeClass: sizeClass,
      clearEnabled: clearEnabled,
      onClearAll: onClearAll,
      onOpenNavigation: onOpenNavigation,
    );
  }
}

class _Md3eHistoryPageHeaderToolbar extends StatelessWidget {
  const _Md3eHistoryPageHeaderToolbar({
    required this.title,
    required this.sizeClass,
    required this.clearEnabled,
    this.onClearAll,
    this.onOpenNavigation,
  });

  final String? title;
  final Md3eWindowSizeClass sizeClass;
  final bool clearEnabled;
  final VoidCallback? onClearAll;
  final VoidCallback? onOpenNavigation;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final M3EThemeData theme = M3ETheme.of(context);
    final M3EColorScheme scheme = theme.colorScheme;

    final bool showMenu = sizeClass.isCompact && onOpenNavigation != null;

    return Md3ePinnedToolbarChrome(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          if (showMenu) ...<Widget>[
            M3EIconButton(
              icon: Icon(
                Symbols.menu,
                size: Md3eLibraryPageHeaderMetrics.actionIconSize,
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
              child: Md3ePageTitle(title ?? l10n.historyTitle),
            ),
          ),
          M3EIconButton(
            icon: Icon(
              Symbols.delete,
              size: Md3eLibraryPageHeaderMetrics.actionIconSize,
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
    final bool confirmed = await showMd3eClearReadingHistoryConfirmDialog(
      context: context,
    );
    if (!confirmed) {
      return;
    }
    onClearAll?.call();
  }
}
