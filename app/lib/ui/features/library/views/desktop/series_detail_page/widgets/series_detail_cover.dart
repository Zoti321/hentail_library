import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/domain/models/entity/comic/series.dart';
import 'package:hentai_library/domain/models/entity/comic/series_item.dart';
import 'package:hentai_library/src/rust/api/thumbnail.dart';
import 'package:hentai_library/ui/core/dto/comic_cover_display_data.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';
import 'package:hentai_library/ui/core/widgets/element/image/adaptive_comic_cover.dart';
import 'package:hentai_library/ui/providers.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class SeriesDetailCover extends ConsumerWidget {
  const SeriesDetailCover({super.key, required this.series});

  final Series series;

  static const double containerAspectRatio = 2 / 3;
  static const double _cornerRadius = 2;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final SeriesItem? coverItem = series.coverItem;
    final String? coverComicId = coverItem?.comicId;
    final ComicCoverDisplayData? coverDisplay = coverComicId != null
        ? ref
              .watch(
                comicCoverDisplayProvider(
                  comicId: coverComicId,
                  priority: ThumbnailPriorityDto.critical,
                ),
              )
              .maybeWhen(
                data: (ComicCoverDisplayData? value) => value,
                orElse: () => null,
              )
        : null;

    return AdaptiveComicCover(
      coverDisplay: coverDisplay,
      containerAspectRatio: containerAspectRatio,
      backgroundColor: Colors.white,
      showShadow: true,
      placeholder: const SizedBox.expand(),
      errorPlaceholder: Center(
        child: Icon(
          LucideIcons.imageOff,
          color: cs.hentai.iconSecondary,
          size: 40,
        ),
      ),
      clipBorderRadius: BorderRadius.circular(_cornerRadius),
    );
  }
}
