import 'package:flutter/material.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/shared/ui/patterns/home/home_library_dashboard_models.dart';

import 'package:intl/intl.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_symbols_icons/symbols.dart';

/// 首页库列表行共用的展示映射（静态行与可拖拽行共用，避免两处各写一份）。
IconData homeLibraryKindIcon(HomeLibraryKind kind) {
  return switch (kind) {
    HomeLibraryKind.local => Symbols.folder,
    HomeLibraryKind.remote => Symbols.cloud,
  };
}

Color homeLibraryHintColor(M3EColorScheme scheme, HomeLibraryRowHint hint) {
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
  final AppLocalizations l10n = AppLocalizations.of(context);
  final String locale = Localizations.localeOf(context).toString();
  final String formatted = DateFormat.yMd(locale).add_Hm().format(at);
  return '${l10n.homeLibraryLastSyncLabel} · $formatted';
}

String? homeLibraryStatusLine(
  AppLocalizations l10n,
  HomeLibraryDashboardRow row,
) {
  if (row.scanInProgress) {
    return l10n.homeLibraryScanInProgressHint;
  }
  if (row.metadataRefreshInProgress) {
    return l10n.homeLibraryMetadataRefreshInProgressHint;
  }
  return switch (row.hint) {
    HomeLibraryRowHint.syncWarning => row.staleDays == null
        ? l10n.homeLibrarySyncRecommendedHint
        : l10n.homeLibrarySyncWarningHint(row.staleDays!),
    HomeLibraryRowHint.unreachable => l10n.homeLibraryUnreachableHint,
    HomeLibraryRowHint.none => null,
  };
}
