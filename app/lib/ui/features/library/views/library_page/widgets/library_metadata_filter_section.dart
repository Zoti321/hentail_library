import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/domain/library/library_metadata_filter_selection.dart';
import 'package:hentai_library/domain/models/entity/comic/author.dart';
import 'package:hentai_library/domain/models/entity/comic/tag.dart';
import 'package:hentai_library/domain/models/enums.dart';
import 'package:hentai_library/ui/features/library/view_models/library_author_filter_notifier.dart';
import 'package:hentai_library/ui/features/library/view_models/library_catalog_selectors.dart';
import 'package:hentai_library/ui/features/library/view_models/library_tag_filter_notifier.dart';
import 'package:hentai_library/ui/features/library/views/library_page/widgets/library_metadata_filter_controls.dart';
import 'package:hentai_library/ui/features/metadata/view_models/author_management_notifier.dart';
import 'package:hentai_library/ui/features/metadata/view_models/tag_management_notifier.dart';

class LibraryTagFilterControls extends ConsumerWidget {
  const LibraryTagFilterControls({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final LibraryDisplayTarget displayTarget = ref.watch(
      libraryDisplayTargetProvider,
    );
    if (displayTarget != LibraryDisplayTarget.comics) {
      return const SizedBox.shrink();
    }

    final AsyncValue<List<Tag>> tagsAsync = ref.watch(allTagsProvider);
    final LibraryMetadataFilterSelection selection = ref.watch(
      libraryTagFilterProvider,
    ).maybeWhen(
      data: (LibraryMetadataFilterSelection value) => value,
      orElse: () => const LibraryMetadataFilterSelection(),
    );
    final List<String> names = tagsAsync.maybeWhen(
      data: (List<Tag> tags) =>
          tags.map((Tag tag) => tag.name).toList()..sort(),
      orElse: () => const <String>[],
    );

    return LibraryMetadataFilterControls(
      title: context.l10n.libraryTagFilter,
      names: names,
      selection: selection,
      isLoading: tagsAsync.isLoading,
      onToggle: ref.read(libraryTagFilterProvider.notifier).toggle,
      onIncludeModeChanged:
          ref.read(libraryTagFilterProvider.notifier).setIncludeMode,
      onClear: ref.read(libraryTagFilterProvider.notifier).clear,
    );
  }
}

class LibraryAuthorFilterControls extends ConsumerWidget {
  const LibraryAuthorFilterControls({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final LibraryDisplayTarget displayTarget = ref.watch(
      libraryDisplayTargetProvider,
    );
    if (displayTarget != LibraryDisplayTarget.comics) {
      return const SizedBox.shrink();
    }

    final AsyncValue<List<Author>> authorsAsync = ref.watch(allAuthorsProvider);
    final LibraryMetadataFilterSelection selection = ref.watch(
      libraryAuthorFilterProvider,
    ).maybeWhen(
      data: (LibraryMetadataFilterSelection value) => value,
      orElse: () => const LibraryMetadataFilterSelection(),
    );
    final List<String> names = authorsAsync.maybeWhen(
      data: (List<Author> authors) =>
          authors.map((Author author) => author.name).toList()..sort(),
      orElse: () => const <String>[],
    );

    return LibraryMetadataFilterControls(
      title: context.l10n.libraryAuthorFilter,
      names: names,
      selection: selection,
      isLoading: authorsAsync.isLoading,
      onToggle: ref.read(libraryAuthorFilterProvider.notifier).toggle,
      onIncludeModeChanged:
          ref.read(libraryAuthorFilterProvider.notifier).setIncludeMode,
      onClear: ref.read(libraryAuthorFilterProvider.notifier).clear,
    );
  }
}
