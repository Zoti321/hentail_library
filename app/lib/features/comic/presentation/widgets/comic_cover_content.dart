import 'package:flutter/material.dart';
import 'package:hentai_library/features/comic/di/comic_cover_providers.dart';
import 'package:hentai_library/features/comic/di/cover_viewport.dart';
import 'package:hentai_library/shared/domain/models/enums.dart';
import 'package:hentai_library/shared/ui/models/comic_cover_state.dart';
import 'package:hentai_library/shared/ui/widgets/catalog/catalog_cover_hero.dart';
import 'package:hentai_library/shared/ui/widgets/element/image/card_letterboxed_cover_image.dart';
import 'package:hentai_library/shared/ui/widgets/element/image/comic_cover_placeholder.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// 根据 [ComicCoverState] 渲染封面区域（卡片宽高比 2:3）。
class ComicCoverContent extends ConsumerWidget {
  const ComicCoverContent({
    super.key,
    required this.comicId,
    this.priority = ThumbnailPriority.high,
    this.gridIndex,
    this.coverViewportScope,
    this.attachViewportSensor = true,
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

  /// 库页/历史网格索引；配合 [coverViewportScope] 做视口分级加载。
  final int? gridIndex;

  /// [coverViewportProvider] 的 scope（如 [CoverViewportScopes.library]）。
  /// 与 [gridIndex] 同时提供时启用视口优先级；默认再包 [CoverViewportSensor]。
  final String? coverViewportScope;

  /// 为 false 时不包 [CoverViewportSensor]（外层已传感时，如 [SeriesCoverContent]）。
  final bool attachViewportSensor;

  /// 为 false 时不包 [Hero]（例如系列封面回退到成员漫画图，避免嵌套 Hero）。
  final bool enableHero;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThumbnailPriority effectivePriority = _effectivePriority(ref);
    // Provider build already schedules ensureLoaded via microtask; only bump /
    // promote priority here (no full state reset during widget build).
    final ComicCover notifier = ref.read(comicCoverProvider(comicId).notifier);
    if (gridIndex != null && coverViewportScope != null) {
      notifier.promotePriority(effectivePriority);
    } else {
      notifier.bumpPriority(effectivePriority);
    }
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

    Widget result = CatalogCoverHero.wrap(
      tag: CatalogCoverHero.comicTag(comicId),
      enabled: enableHero,
      child: cover,
    );

    final int? index = gridIndex;
    final String? scope = coverViewportScope;
    if (attachViewportSensor && index != null && scope != null) {
      result = CoverViewportSensor(scope: scope, index: index, child: result);
    }
    return result;
  }

  ThumbnailPriority _effectivePriority(WidgetRef ref) {
    if (priority == ThumbnailPriority.critical) {
      return priority;
    }
    final int? index = gridIndex;
    final String? scope = coverViewportScope;
    if (index == null || scope == null) {
      // 无完整视口接线时沿用声明的 priority，不静默抬到 high。
      return priority;
    }
    final bool inViewport = ref.watch(
      coverViewportProvider(
        scope,
      ).select((Set<int> indices) => indices.contains(index)),
    );
    return inViewport ? ThumbnailPriority.high : ThumbnailPriority.low;
  }
}
