import 'package:flutter/material.dart';
import 'package:hentai_library/features/comic/di/comic_cover_providers.dart';
import 'package:hentai_library/features/comic/di/cover_viewport.dart';
import 'package:hentai_library/features/comic/presentation/widgets/comic_cover_renderer.dart';
import 'package:hentai_library/shared/domain/models/enums.dart';
import 'package:hentai_library/shared/ui/models/comic_cover_state.dart';
import 'package:hentai_library/shared/ui/widgets/catalog/catalog_cover_hero.dart';
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
    this.fit,
    this.alignment = Alignment.center,
    this.enableHero = true,
    this.paintVariant = ComicCoverPaintVariant.card,
  });

  /// 非空时强制拟合（如横幅 [BoxFit.cover]）；默认软裁切 letterbox。
  final BoxFit? fit;

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

  /// 卡片（默认）或详情页封面绘制。
  final ComicCoverPaintVariant paintVariant;

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

    Widget result = CatalogCoverHero.wrap(
      tag: CatalogCoverHero.comicTag(comicId),
      enabled: enableHero,
      child: ComicCoverRenderer(
        state: state,
        variant: paintVariant,
        fit: fit,
        alignment: alignment,
        onDecodeError: notifier.markDecodeError,
        onRetry: notifier.retryLoad,
      ),
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
      coverViewportProvider(scope)
          .select((Set<int> indices) => indices.contains(index)),
    );
    return inViewport ? ThumbnailPriority.high : ThumbnailPriority.low;
  }
}
