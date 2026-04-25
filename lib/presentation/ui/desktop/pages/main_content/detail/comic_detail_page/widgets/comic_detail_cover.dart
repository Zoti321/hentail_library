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
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(tokens.radius.lg),
        border: Border.all(color: cs.borderSubtle),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: cs.cardShadow,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: AdaptiveCover(
        coverDisplay: coverData,
        fallbackAspectRatio: 2 / 3,
        backgroundColor: cs.surfaceContainerHighest,
        maxCacheWidth: 1600,
        placeholder: const SizedBox.expand(),
        errorPlaceholder: Icon(
          LucideIcons.imageOff,
          size: 36,
          color: cs.imageFallback,
        ),
        clipBorderRadius: BorderRadius.circular(tokens.radius.lg),
      ),
    );
  }
}
