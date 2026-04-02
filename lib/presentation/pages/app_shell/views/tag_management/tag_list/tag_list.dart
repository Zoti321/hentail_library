import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/domain/entity/comic/tag.dart';

import 'tag_list_card.dart';
import 'tag_list_view.dart';

class TagList extends ConsumerWidget {
  const TagList({super.key, required this.tags});

  final List<Tag> tags;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return TagListCard(
      child: Column(
        children: [
          const TagListHeader(),
          TagListView(tags: tags),
        ],
      ),
    );
  }
}

