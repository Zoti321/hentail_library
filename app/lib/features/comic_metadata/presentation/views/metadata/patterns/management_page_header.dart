import 'package:flutter/material.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/design-system/design_system.dart';

/// Lab / Widgetbook 管理页粘滞头：仅左侧标题（间距与字阶来自 [PageLayoutSpec]）。
///
/// 生产头栏见 `MetadataHeader`（含返回、更多菜单、合并模式）。
class ManagementPageHeader extends StatelessWidget {
  const ManagementPageHeader({super.key, this.title});

  /// Defaults to [AppLocalizations.navMetadata] when null.
  final String? title;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final PageLayoutSpec layout = PageLayoutSpec.of(context);

    return Padding(
      padding: EdgeInsets.symmetric(vertical: layout.headerVerticalInset),
      child: SizedBox(
        height: PageLayoutSpec.toolbarRowHeight,
        child: Align(
          alignment: Alignment.centerLeft,
          child: PageTitle(title ?? l10n.navMetadata),
        ),
      ),
    );
  }
}
