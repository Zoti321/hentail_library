import 'package:flutter/material.dart';
import 'package:hentai_library/md3e/l10n/md3e_l10n.dart';
import 'package:hentai_library/md3e/patterns/home/md3e_home_library_dashboard_models.dart';
import 'package:hentai_library/md3e/patterns/home/md3e_home_library_management_copy.dart';
import 'package:intl/intl.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_symbols_icons/symbols.dart';

/// Lab 占位：「已超过 N 天未同步」的天数。生产由 read model 提供真实值后替换。
const int md3eHomeLibraryPreviewStaleDays = 9;

/// 首页库列表行共用的展示映射（静态行与可拖拽行共用，避免两处各写一份）。
IconData md3eHomeLibraryKindIcon(Md3eHomeLibraryKind kind) {
  return switch (kind) {
    Md3eHomeLibraryKind.local => Symbols.folder,
    Md3eHomeLibraryKind.remote => Symbols.cloud,
  };
}

Color md3eHomeLibraryHintColor(
  M3EColorScheme scheme,
  Md3eHomeLibraryRowHint hint,
) {
  return switch (hint) {
    Md3eHomeLibraryRowHint.unreachable => scheme.error,
    Md3eHomeLibraryRowHint.syncWarning => scheme.tertiary,
    Md3eHomeLibraryRowHint.none => scheme.onSurfaceVariant,
  };
}

String md3eHomeLibraryStatsLine(
  AppLocalizations l10n,
  Md3eHomeLibraryDashboardRow row,
) {
  return '${l10n.comicCount(row.comicCount)} · ${l10n.librarySeriesCount(row.seriesCount)}';
}

String? md3eHomeLibrarySyncLine(BuildContext context, DateTime? at) {
  if (at == null) {
    return null;
  }
  final String locale = Localizations.localeOf(context).toString();
  final String formatted = DateFormat.yMd(locale).add_Hm().format(at);
  return '${Md3eHomeLibraryManagementCopy.lastSyncLabel} · $formatted';
}

String? md3eHomeLibraryStatusLine(Md3eHomeLibraryDashboardRow row) {
  if (row.scanInProgress) {
    return Md3eHomeLibraryManagementCopy.scanInProgressHint;
  }
  if (row.metadataRefreshInProgress) {
    return Md3eHomeLibraryManagementCopy.metadataRefreshInProgressHint;
  }
  return switch (row.hint) {
    Md3eHomeLibraryRowHint.syncWarning =>
      Md3eHomeLibraryManagementCopy.syncWarningHint(
        md3eHomeLibraryPreviewStaleDays,
      ),
    Md3eHomeLibraryRowHint.unreachable =>
      Md3eHomeLibraryManagementCopy.unreachableHint,
    Md3eHomeLibraryRowHint.none => null,
  };
}

/// 可拖拽行使用的单字符串副标题（统计 / 同步时间 / 状态，按行拼接）。
String md3eHomeLibrarySupportingText(
  BuildContext context,
  AppLocalizations l10n,
  Md3eHomeLibraryDashboardRow row,
) {
  final List<String> lines = <String>[
    md3eHomeLibraryStatsLine(l10n, row),
    ?md3eHomeLibrarySyncLine(context, row.lastSyncedAt),
    ?md3eHomeLibraryStatusLine(row),
  ];
  return lines.join('\n');
}
