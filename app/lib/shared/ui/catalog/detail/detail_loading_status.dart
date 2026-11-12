import 'package:flutter/material.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/shared/ui/catalog/detail/detail_status_scaffold.dart';

/// 详情加载中。
class DetailLoadingStatus extends StatelessWidget {
  const DetailLoadingStatus({super.key});

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return DetailStatusScaffold(
      leading: SizedBox(
        width: 32,
        height: 32,
        child: CircularProgressIndicator(strokeWidth: 2.5, color: cs.primary),
      ),
      label: context.l10n.shellLoading,
    );
  }
}
