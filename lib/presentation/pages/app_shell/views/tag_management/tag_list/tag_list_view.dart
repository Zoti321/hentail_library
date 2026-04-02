import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/config/theme.dart';
import 'package:hentai_library/domain/entity/comic/tag.dart';
import 'package:hentai_library/presentation/providers/providers.dart';

import 'tag_row.dart';

class TagListView extends ConsumerWidget {
  const TagListView({super.key, required this.tags});

  final List<Tag> tags;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: tags.length,
      separatorBuilder: (_, _) => Divider(height: 1, color: cs.borderSubtle),
      itemBuilder: (context, index) {
        final tag = tags[index];
        final isSelected = ref.watch(tagSelectionProvider).contains(tag);
        return TagRow(tag: tag, isSelected: isSelected);
      },
    );
  }
}

