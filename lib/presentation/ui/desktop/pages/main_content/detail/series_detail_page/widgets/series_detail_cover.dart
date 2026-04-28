import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/model/entity/comic/series.dart';
import 'package:hentai_library/model/entity/comic/series_item.dart';
import 'package:hentai_library/presentation/dto/comic_cover_display_data.dart';
import 'package:hentai_library/presentation/providers/providers.dart';
import 'package:hentai_library/presentation/ui/desktop/widgets/element/image/adaptive_cover.dart';
import 'package:hentai_library/presentation/theme/theme.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class SeriesDetailCover extends ConsumerWidget {
  const SeriesDetailCover({super.key, required this.series});

  final Series series;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final SeriesItem? coverItem = series.coverItem;
    final String? coverComicId = coverItem?.comicId;
    final ComicCoverDisplayData? coverDisplay = coverComicId != null
        ? ref
              .watch(comicCoverDisplayProvider(comicId: coverComicId))
              .maybeWhen(
                data: (ComicCoverDisplayData? v) => v,
                orElse: () => null,
              )
        : null;

    final AppThemeTokens tokens = context.tokens;
    final ColorScheme cs = Theme.of(context).colorScheme;

    return AdaptiveCover(
      coverDisplay: coverDisplay,
      fallbackAspectRatio: 2 / 3,
      backgroundColor: cs.imagePlaceholder,
      placeholder: const SizedBox.expand(),
      errorPlaceholder: Center(
        child: Icon(LucideIcons.imageOff, color: cs.iconSecondary, size: 40),
      ),
      clipBorderRadius: BorderRadius.circular(tokens.radius.lg),
    );
  }
}
