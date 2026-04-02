import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/domain/entity/comic/tag.dart';
import 'package:hentai_library/presentation/providers/providers.dart';

import 'tag_management/tag_list/tag_list.dart';
import 'tag_management/tag_management_header.dart';
import 'tag_management/tag_management_states.dart';
import 'tag_management/tag_management_styles.dart';

class TagManagementPage extends ConsumerWidget {
  const TagManagementPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tagsAsync = ref.watch(allTagsProvider);
    final selection = ref.watch(tagSelectionProvider);
    final query = ref.watch(tagFilterProvider);

    return SingleChildScrollView(
      padding: TagManagementStyles.pagePadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TagManagementHeader(selectionCount: selection.length),
          const SizedBox(height: 20),
          tagsAsync.when(
            data: (tags) {
              final filtered = _applyFilter(tags, query);
              if (filtered.isEmpty) return const TagManagementEmptyState();
              return TagList(tags: filtered);
            },
            loading: () => const TagManagementLoadingCard(),
            error: (e, _) => TagManagementErrorCard(error: e),
          ),
        ],
      ),
    );
  }

  List<Tag> _applyFilter(List<Tag> source, String query) {
    if (query.trim().isEmpty) return List<Tag>.from(source);
    final q = query.trim().toLowerCase();
    return source.where((t) => t.name.toLowerCase().contains(q)).toList();
  }
}
