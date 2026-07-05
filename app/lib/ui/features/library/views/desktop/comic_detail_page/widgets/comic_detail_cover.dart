import 'package:flutter/material.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';
import 'package:hentai_library/ui/core/dto/comic_cover_display_data.dart';
import 'package:hentai_library/src/rust/api/thumbnail.dart';
import 'package:hentai_library/ui/providers.dart';
import 'package:hentai_library/ui/core/widgets/element/image/adaptive_comic_cover.dart';
import 'package:hentai_library/domain/models/entity/comic/comic.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class ComicDetailCover extends ConsumerWidget {
  const ComicDetailCover({super.key, required this.comic});

  final Comic comic;

  static const double containerAspectRatio = 2 / 3;
  static const double _cornerRadius = 2;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final ComicCoverDisplayData? coverData = ref
        .watch(
          comicCoverDisplayProvider(
            comicId: comic.comicId,
            priority: ThumbnailPriorityDto.critical,
          ),
        )
        .maybeWhen(data: (ComicCoverDisplayData? v) => v, orElse: () => null);

    return AdaptiveComicCover(
      coverDisplay: coverData,
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
