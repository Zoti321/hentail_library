import 'package:flutter/material.dart';
import 'package:hentai_library/theme/theme.dart';
import 'package:hentai_library/presentation/dto/comic_cover_display_data.dart';
import 'package:hentai_library/presentation/providers/providers.dart';
import 'package:hentai_library/presentation/ui/desktop/widgets/element/image/adaptive_cover.dart';
import 'package:hentai_library/domain/entity/comic/comic.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class ComicDetailCover extends ConsumerWidget {
  const ComicDetailCover({super.key, required this.comic});

  final Comic comic;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final AppThemeTokens tokens = context.tokens;
    final ComicCoverDisplayData? coverData = ref
        .watch(comicCoverDisplayProvider(comicId: comic.comicId))
        .maybeWhen(data: (ComicCoverDisplayData? v) => v, orElse: () => null);

    return AdaptiveCover(
      coverDisplay: coverData,
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
