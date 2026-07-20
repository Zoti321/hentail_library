import 'package:flutter/material.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/domain/models/entity/comic/series.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';
import 'package:hentai_library/ui/core/widgets/actions/ghost_button.dart';
import 'package:hentai_library/ui/core/widgets/actions/page_size_menu.dart';
import 'package:hentai_library/ui/core/widgets/overlays/dialog/edit_series_dialog.dart';
import 'package:hentai_library/ui/features/library/view_models/series_detail_page_size_notifier.dart';
import 'package:hentai_library/ui/features/library/view_models/series_detail_page_size_providers.dart';
import 'package:hentai_library/ui/features/library/views/comic_detail_page/widgets/comic_detail_back_header.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class SeriesDetailHeader extends ConsumerWidget {
  const SeriesDetailHeader({super.key, required this.series});

  final Series series;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final ThemeData theme = Theme.of(context);
    final int activePageSize = ref.watch(seriesDetailActivePageSizeProvider);
    final AppLocalizations l10n = context.l10n;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: cs.surface,
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: cs.hentai.cardShadow,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 48,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: <Widget>[
                GhostButton.icon(
                  icon: LucideIcons.arrowLeft,
                  tooltip: l10n.shellBack,
                  semanticLabel: l10n.shellBack,
                  iconSize: 16,
                  size: 32,
                  borderRadius: 8,
                  foregroundColor: cs.hentai.iconDefault,
                  hoverColor: theme.hoverColor,
                  overlayColor: theme.hoverColor,
                  onPressed: () =>
                      ComicDetailBackHeader.popOrGoLibrary(context),
                ),
                const SizedBox(width: 4),
                GhostButton.icon(
                  icon: LucideIcons.pencil,
                  tooltip: l10n.seriesDetailEdit,
                  semanticLabel: l10n.seriesDetailEdit,
                  iconSize: 16,
                  size: 32,
                  borderRadius: 8,
                  foregroundColor: cs.hentai.iconDefault,
                  hoverColor: theme.hoverColor,
                  overlayColor: theme.hoverColor,
                  onPressed: () {
                    showEditSeriesDialog(context: context, series: series);
                  },
                ),
                const Spacer(),
                PageSizeMenuButton(
                  activePageSize: activePageSize,
                  onSelected: (int pageSize) {
                    ref
                        .read(seriesDetailPageSizeProvider.notifier)
                        .setPageSize(pageSize);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
