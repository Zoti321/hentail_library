import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/domain/models/enums.dart';
import 'package:hentai_library/ui/features/library/view_models/library_include_set_filter_notifier.dart';
import 'package:hentai_library/ui/features/library/view_models/library_query_intent_notifier.dart';
import 'package:hentai_library/ui/features/shell/views/navigation/library_management_actions.dart';

/// 从详情页 chip 跳转到当前库漫画列表，并应用单一 include 维度筛选（OR 单选）。
Future<void> browseLibraryWithIncludeFilter(
  WidgetRef ref,
  BuildContext context, {
  required LibraryIncludeSetKind kind,
  required String value,
}) async {
  final String trimmed = value.trim();
  if (trimmed.isEmpty) {
    return;
  }

  ref.read(libraryQueryIntentProvider.notifier)
    ..clearKeyword()
    ..setDisplayTarget(LibraryDisplayTarget.comics);

  for (final LibraryIncludeSetKind other in LibraryIncludeSetKind.values) {
    await ref.read(libraryIncludeSetFilterProvider(other).notifier).clear();
  }
  await ref
      .read(libraryIncludeSetFilterProvider(kind).notifier)
      .selectOnly(trimmed);

  if (!context.mounted) {
    return;
  }
  LibraryManagementActions.goCurrentLibraryBrowse(ref, context);
}
