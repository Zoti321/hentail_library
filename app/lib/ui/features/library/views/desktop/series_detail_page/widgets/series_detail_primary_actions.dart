import 'package:flutter/material.dart';
import 'package:hentai_library/domain/models/entity/comic/series.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';
import 'package:hentai_library/ui/features/library/views/desktop/comic_detail_page/widgets/comic_detail_primary_actions.dart';
import 'package:hentai_library/ui/features/reader/read_session_launcher.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class SeriesDetailPrimaryActions extends HookConsumerWidget {
  const SeriesDetailPrimaryActions({super.key, required this.series});

  final Series series;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final AppThemeTokens tokens = context.tokens;
    final ButtonStyle primaryStyle = comicDetailPrimaryActionStyle(
      theme,
      tokens,
    );
    return Wrap(
      spacing: tokens.spacing.md,
      runSpacing: tokens.spacing.sm,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: <Widget>[
        Semantics(
          label: '系列阅读',
          button: true,
          child: ElevatedButton.icon(
            onPressed: series.items.isEmpty
                ? null
                : () => openSeriesReadSession(
                    ref,
                    seriesId: series.id,
                  ),
            icon: const Icon(LucideIcons.bookOpen, size: 16),
            label: const Text('系列阅读'),
            style: primaryStyle,
          ),
        ),
      ],
    );
  }
}
