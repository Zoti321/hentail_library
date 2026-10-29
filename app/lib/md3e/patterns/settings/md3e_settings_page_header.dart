import 'package:flutter/material.dart';
import 'package:hentai_library/md3e/l10n/md3e_l10n.dart';
import 'package:hentai_library/md3e/layout/md3e_breakpoints.dart';
import 'package:hentai_library/md3e/patterns/library/md3e_library_page_header_metrics.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// Settings sticky toolbar: title only (category title on narrow detail).
/// 返回由页面的 [PopScope] 处理（窄屏详情 → 分类列表），不在工具栏显示返回按钮。
class Md3eSettingsPageHeader extends StatelessWidget {
  const Md3eSettingsPageHeader({super.key, this.title});

  final String? title;

  @override
  Widget build(BuildContext context) {
    final Md3eWindowSizeClass sizeClass = md3eWindowSizeClassOf(context);

    return Padding(
      padding: const EdgeInsets.only(
        top: Md3eLibraryPageHeaderMetrics.verticalPadding,
        bottom: Md3eLibraryPageHeaderMetrics.browsePinnedHeaderBottomPadding,
      ),
      child: _Md3eSettingsPageHeaderToolbar(title: title, sizeClass: sizeClass),
    );
  }
}

class _Md3eSettingsPageHeaderToolbar extends StatelessWidget {
  const _Md3eSettingsPageHeaderToolbar({
    required this.title,
    required this.sizeClass,
  });

  final String? title;
  final Md3eWindowSizeClass sizeClass;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final M3EThemeData theme = M3ETheme.of(context);
    final M3EColorScheme scheme = theme.colorScheme;
    final M3ETypeScale type = theme.typeScale;
    final String resolvedTitle = title ?? l10n.navSettings;

    return SizedBox(
      height: Md3eLibraryPageHeaderMetrics.toolbarHeight,
      child: Row(
        children: <Widget>[
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                resolvedTitle,
                style: type.headlineSmall.copyWith(
                  fontSize: Md3eLibraryPageHeaderMetrics.titleFontSize(
                    sizeClass,
                  ),
                  fontWeight: Md3eLibraryPageHeaderMetrics.titleFontWeight(
                    sizeClass,
                  ),
                  color: scheme.onSurface,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
