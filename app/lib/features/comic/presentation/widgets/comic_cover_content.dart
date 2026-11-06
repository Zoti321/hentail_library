import 'package:flutter/material.dart';
import 'package:hentai_library/features/comic/di/comic_cover_providers.dart';
import 'package:hentai_library/shared/domain/models/enums.dart';
import 'package:hentai_library/shared/ui/models/comic_cover_state.dart';
import 'package:hentai_library/shared/ui/widgets/catalog/catalog_cover_hero.dart';
import 'package:hentai_library/shared/ui/widgets/element/image/card_letterboxed_cover_image.dart';
import 'package:hentai_library/shared/ui/widgets/element/image/comic_cover_placeholder.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod/misc.dart' show ProviderListenable;

/// 根据 [ComicCoverState] 渲染封面区域（卡片宽高比 2:3）。
class ComicCoverContent extends ConsumerWidget {
  const ComicCoverContent({
    super.key,
    required this.comicId,
    this.priority = ThumbnailPriority.high,
    this.gridIndex,
    this.coverViewport,
    this.fit = BoxFit.contain,
    this.alignment = Alignment.center,
    this.enableHero = true,
  });

  /// [BoxFit.cover] 时填满并裁剪（横幅、头像）。
  final BoxFit fit;

  /// [BoxFit.cover] 裁剪时保留的区域。
  final AlignmentGeometry alignment;

  final String comicId;
  final ThumbnailPriority priority;

  /// 库页/历史网格索引；用于视口分级加载。非网格场景留空。
  final int? gridIndex;

  /// 覆盖默认的库页视口集合（例如 History 专用 notifier）。
  final ProviderListenable<Set<int>>? coverViewport;

  /// 为 false 时不包 [Hero]（例如系列封面回退到成员漫画图，避免嵌套 Hero）。
  final bool enableHero;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThumbnailPriority effectivePriority = _effectivePriority(ref);
    // Provider build already schedules ensureLoaded via microtask; only bump
    // priority here (no state writes during widget build).
    ref
        .read(comicCoverProvider(comicId).notifier)
        .bumpPriority(effectivePriority);
    final ComicCoverState state = ref.watch(comicCoverProvider(comicId));

    final Widget cover = switch (state) {
      ComicCoverReady(:final data) => CardLetterboxedCoverImage(
        cover: data,
        fit: fit,
        alignment: alignment,
        onDecodeError: () {
          ref.read(comicCoverProvider(comicId).notifier).markDecodeError();
        },
      ),
      ComicCoverLoading(:final previous) when previous != null =>
        CardLetterboxedCoverImage(
          cover: previous,
          fit: fit,
          alignment: alignment,
          onDecodeError: () {
            ref.read(comicCoverProvider(comicId).notifier).markDecodeError();
          },
        ),
      ComicCoverLoading() => const ComicCoverPlaceholder(
        variant: ComicCoverPlaceholderVariant.card,
        kind: ComicCoverPlaceholderKind.loading,
      ),
      ComicCoverNoCover() => const ComicCoverPlaceholder(
        variant: ComicCoverPlaceholderVariant.card,
        kind: ComicCoverPlaceholderKind.noCover,
      ),
      ComicCoverError() => const ComicCoverPlaceholder(
        variant: ComicCoverPlaceholderVariant.card,
        kind: ComicCoverPlaceholderKind.error,
      ),
    };

    return CatalogCoverHero.wrap(
      tag: CatalogCoverHero.comicTag(comicId),
      enabled: enableHero,
      child: cover,
    );
  }

  ThumbnailPriority _effectivePriority(WidgetRef ref) {
    if (priority == ThumbnailPriority.critical) {
      return priority;
    }
    final int? index = gridIndex;
    if (index == null) {
      return priority;
    }
    // Per-index select: only rebuild when this cell enters/leaves the viewport.
    final ProviderListenable<Set<int>>? viewport = coverViewport;
    if (viewport == null) {
      return ThumbnailPriority.high;
    }
    final bool inViewport = ref.watch(
      viewport.select((Set<int> indices) => indices.contains(index)),
    );
    return inViewport ? ThumbnailPriority.high : ThumbnailPriority.low;
  }
}
