import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:hentai_library/features/comic/presentation/view_models/comic_detail_return_series_notifier.dart';

/// Resolves where comic-detail back should [go] when the route stack cannot pop.
///
/// With a remembered series source → `/series/:id`.
/// Without → `null` (caller falls back to Current library browse).
String? resolveComicDetailBackLocation({String? returnSeriesId}) {
  final String normalized = returnSeriesId?.trim() ?? '';
  if (normalized.isEmpty) {
    return null;
  }
  return '/series/${Uri.encodeComponent(normalized)}';
}

/// 详情返回的 owner 注入入口：仅 `/comic/` 路径生效，命中后清除来源记忆。
String? resolveComicDetailBackLocationFromContext(BuildContext context) {
  if (!GoRouterState.of(context).uri.path.startsWith('/comic/')) {
    return null;
  }
  final String? location = resolveComicDetailBackLocation(
    returnSeriesId: _readReturnSeriesId(context),
  );
  if (location != null) {
    clearComicDetailReturnSeriesFromContext(context);
  }
  return location;
}

String? _readReturnSeriesId(BuildContext context) {
  try {
    return ProviderScope.containerOf(context)
        .read(comicDetailReturnSeriesProvider);
  } catch (_) {
    return null;
  }
}
