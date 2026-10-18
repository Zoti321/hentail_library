import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/shared/domain/models/entity/comic/series.dart';
import 'package:hentai_library/shared/di/library_state_providers.dart';
import 'package:hentai_library/features/library_browse/presentation/views/series_detail_page/widgets/widgets.dart';
import 'package:hentai_library/features/library_browse/presentation/views/widgets/detail_status/detail_status_scaffold.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class SeriesDetailPage extends ConsumerWidget {
  const SeriesDetailPage({super.key, required this.seriesId});

  final String seriesId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final AsyncValue<Series?> seriesAsync = ref.watch(
      seriesByIdStateProvider(seriesId),
    );
    return ColoredBox(
      color: cs.surface,
      child: seriesAsync.when(
        data: (Series? series) {
          if (series == null) {
            return DetailNotFoundStatus(
              icon: LucideIcons.library,
              label: context.l10n.seriesDetailNotFound(
                _seriesNotFoundLabel(context.l10n, seriesId),
              ),
            );
          }
          return SeriesDetail(series: series);
        },
        loading: () => const DetailLoadingStatus(),
        error: (Object error, StackTrace _) => DetailErrorStatus(
          label: context.l10n.searchLoadFailed(error.toString()),
        ),
        skipLoadingOnReload: true,
        skipLoadingOnRefresh: true,
      ),
    );
  }
}

/// 未找到系列时的展示名：优先 id（去空白），为空则回退到「未知」文案。
String _seriesNotFoundLabel(AppLocalizations l10n, String seriesId) {
  final String id = seriesId.trim();
  return id.isNotEmpty ? id : l10n.seriesDetailUnknown;
}
