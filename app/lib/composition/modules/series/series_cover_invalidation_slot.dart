import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/features/series/presentation/providers/series_cover_providers.dart';
import 'package:hentai_library/shared/ui/slots/series_slots.dart';

/// series 侧实现：失效本模块的系列封面解析结果（#493）。
///
/// Rust 目前只为漫画缩略图推送 `ThumbnailEvent`，不推送系列自定义封面事件，
/// 因此按 #493 的降级路径经槽位暴露失效动作，reader 不 import series。
SeriesCoverInvalidationSlot createSeriesCoverInvalidationSlot(Ref ref) {
  return (String seriesId) =>
      ref.invalidate(seriesCoverSourceProvider(seriesId));
}
