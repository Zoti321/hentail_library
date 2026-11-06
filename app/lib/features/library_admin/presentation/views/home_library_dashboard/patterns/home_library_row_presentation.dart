import 'package:flutter/material.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/shared/ui/patterns/home/home_library_dashboard_models.dart';

import 'home_library_management_copy.dart';

import 'package:intl/intl.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_symbols_icons/symbols.dart';

/// Lab 占位：「已超过 N 天未同步」的天数。生产由 read model 提供真实值后替换。
const int homeLibraryPreviewStaleDays = 9;

/// 首页库列表行共用的展示映射（静态行与可拖拽行共用，避免两处各写一份）。
IconData homeLibraryKindIcon(HomeLibraryKind kind) {
  return switch (kind) {
    HomeLibraryKind.local => Symbols.folder,
    HomeLibraryKind.remote => Symbols.cloud,
  };
}

Color homeLibraryHintColor(
  M3EColorScheme scheme,
  HomeLibraryRowHint hint,
) {
  return switch (hint) {
    HomeLibraryRowHint.unreachable => scheme.error,
    HomeLibraryRowHint.syncWarning => scheme.tertiary,
    HomeLibraryRowHint.none => scheme.onSurfaceVariant,
  };
}

String homeLibraryStatsLine(
  AppLocalizations l10n,
  HomeLibraryDashboardRow row,
) {
  return '${l10n.comicCount(row.comicCount)} · ${l10n.librarySeriesCount(row.seriesCount)}';
}

String? homeLibrarySyncLine(BuildContext context, DateTime? at) {
  if (at == null) {
    return null;
  }
  final String locale = Localizations.localeOf(context).toString();
  final String formatted = DateFormat.yMd(locale).add_Hm().format(at);
  return '${HomeLibraryManagementCopy.lastSyncLabel} · $formatted';
}

String? homeLibraryStatusLine(HomeLibraryDashboardRow row) {
  if (row.scanInProgress) {
    return HomeLibraryManagementCopy.scanInProgressHint;
  }
  if (row.metadataRefreshInProgress) {
    return HomeLibraryManagementCopy.metadataRefreshInProgressHint;
  }
  return switch (row.hint) {
    HomeLibraryRowHint.syncWarning =>
      HomeLibraryManagementCopy.syncWarningHint(
        homeLibraryPreviewStaleDays,
      ),
    HomeLibraryRowHint.unreachable =>
      HomeLibraryManagementCopy.unreachableHint,
    HomeLibraryRowHint.none => null,
  };
}
