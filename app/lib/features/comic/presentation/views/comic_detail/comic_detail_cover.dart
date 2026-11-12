import 'package:flutter/material.dart';
import 'package:hentai_library/features/comic/presentation/providers/comic_cover_providers.dart';
import 'package:hentai_library/features/comic/presentation/widgets/comic_cover_renderer.dart';
import 'package:hentai_library/shared/domain/models/enums.dart';
import 'package:hentai_library/shared/ui/models/comic_cover_state.dart';
import 'package:hentai_library/shared/ui/widgets/catalog/catalog_cover_hero.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// MD3E 漫画详情封面：沿用生产封面加载（[comicCoverProvider]），填充到 [AppComicDetailCover] 容器内。
class ComicDetailCover extends ConsumerWidget {
  const ComicDetailCover({super.key, required this.comicId});

  final String comicId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ComicCover notifier = ref.read(comicCoverProvider(comicId).notifier);
    notifier.ensureLoaded(priority: ThumbnailPriority.critical);
    final ComicCoverState state = ref.watch(comicCoverProvider(comicId));

    return CatalogCoverHero.wrap(
      tag: CatalogCoverHero.comicTag(comicId),
      child: ComicCoverRenderer(
        state: state,
        variant: ComicCoverPaintVariant.detail,
        onDecodeError: notifier.markDecodeError,
        onRetry: notifier.retryLoad,
      ),
    );
  }
}
