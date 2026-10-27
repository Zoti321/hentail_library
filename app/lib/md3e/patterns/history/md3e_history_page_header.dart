import 'package:flutter/material.dart';
import 'package:hentai_library/md3e/l10n/md3e_l10n.dart';
import 'package:hentai_library/md3e/layout/md3e_breakpoints.dart';
import 'package:hentai_library/md3e/patterns/history/md3e_history_clear_confirm_dialog.dart';
import 'package:hentai_library/md3e/patterns/library/md3e_library_page_header_metrics.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_symbols_icons/symbols.dart';

/// 阅读历史粘滞页头：标题 + 清空全部（需二次确认）。
class Md3eHistoryPageHeader extends StatelessWidget {
  const Md3eHistoryPageHeader({
    super.key,
    this.title,
    this.clearEnabled = true,
    this.onClearAll,
  });

  final String? title;
  final bool clearEnabled;
  final VoidCallback? onClearAll;

  @override
  Widget build(BuildContext context) {
    final double windowWidth = MediaQuery.sizeOf(context).width;
    final Md3eWindowSizeClass sizeClass =
        Md3eWindowSizeClass.fromWidth(windowWidth);

    return Padding(
      padding: const EdgeInsets.only(
        top: Md3eLibraryPageHeaderMetrics.verticalPadding,
        bottom: Md3eLibraryPageHeaderMetrics.browsePinnedHeaderBottomPadding,
      ),
      child: _Md3eHistoryPageHeaderToolbar(
        title: title,
        sizeClass: sizeClass,
        clearEnabled: clearEnabled,
        onClearAll: onClearAll,
      ),
    );
  }
}

class _Md3eHistoryPageHeaderToolbar extends StatelessWidget {
  const _Md3eHistoryPageHeaderToolbar({
    required this.title,
    required this.sizeClass,
    required this.clearEnabled,
    this.onClearAll,
  });

  final String? title;
  final Md3eWindowSizeClass sizeClass;
  final bool clearEnabled;
  final VoidCallback? onClearAll;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final M3EThemeData theme = M3ETheme.of(context);
    final M3EColorScheme scheme = theme.colorScheme;
    final M3ETypeScale type = theme.typeScale;

    return SizedBox(
      height: Md3eLibraryPageHeaderMetrics.toolbarHeight,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                title ?? l10n.historyTitle,
                style: type.headlineSmall.copyWith(
                  fontSize: Md3eLibraryPageHeaderMetrics.titleFontSize(
                    sizeClass,
                  ),
                  fontWeight: Md3eLibraryPageHeaderMetrics.titleFontWeight(
                    sizeClass,
                  ),
                  color: scheme.onSurface,
                  letterSpacing: -0.4,
                ),
              ),
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
