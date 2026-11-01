import 'package:flutter/material.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/shared/ui/layout/page_layout_spec.dart';
import 'package:hentai_library/shared/ui/patterns/shared/md3e_page_title.dart';

/// 管理页粘滞头：仅左侧标题（间距与字阶来自 [Md3ePageLayoutSpec]）。
class Md3eManagementPageHeader extends StatelessWidget {
  const Md3eManagementPageHeader({super.key, this.title});

  /// Defaults to [AppLocalizations.navMetadata] when null.
  final String? title;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final Md3ePageLayoutSpec layout = Md3ePageLayoutSpec.of(context);

    return Padding(
      padding: EdgeInsets.symmetric(vertical: layout.headerVerticalInset),
      child: SizedBox(
        height: Md3ePageLayoutSpec.toolbarRowHeight,
        child: Align(
          alignment: Alignment.centerLeft,
          child: Md3ePageTitle(title ?? l10n.navMetadata),
        ),
      ),
    );
  }
}
