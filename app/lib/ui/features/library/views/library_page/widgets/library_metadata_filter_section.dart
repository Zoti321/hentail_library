import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/domain/library/library_metadata_filter_selection.dart';
import 'package:hentai_library/domain/library/library_tri_state_pick.dart';
import 'package:hentai_library/domain/models/entity/comic/author.dart';
import 'package:hentai_library/domain/models/entity/comic/tag.dart';
import 'package:hentai_library/domain/models/enums.dart';
import 'package:hentai_library/domain/models/value_objects/comic_language.dart';
import 'package:hentai_library/ui/features/library/view_models/library_author_filter_notifier.dart';
import 'package:hentai_library/ui/features/library/view_models/library_catalog_selectors.dart';
import 'package:hentai_library/ui/features/library/view_models/library_include_set_filter_notifier.dart';
import 'package:hentai_library/ui/features/library/view_models/library_tab_filter_sort_providers.dart';
import 'package:hentai_library/ui/features/library/view_models/library_tag_filter_notifier.dart';
import 'package:hentai_library/ui/features/library/views/library_page/widgets/library_metadata_filter_controls.dart';
import 'package:hentai_library/ui/features/metadata/view_models/author_management_notifier.dart';
import 'package:hentai_library/ui/features/metadata/view_models/tag_management_notifier.dart';

LibraryMetadataFilterSelection includeOnlyFilterSelection(Set<String> names) {
  return LibraryMetadataFilterSelection(
    picks: <String, LibraryTriStatePick>{
      for (final String name in names) name: LibraryTriStatePick.include,
    },
  );
}

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
    final LibraryMetadataFilterSelection selection = ref
        .watch(libraryTagFilterProvider)
        .maybeWhen(
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
      onIncludeModeChanged: ref
          .read(libraryTagFilterProvider.notifier)
          .setIncludeMode,
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
    final LibraryMetadataFilterSelection selection = ref
        .watch(libraryAuthorFilterProvider)
        .maybeWhen(
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
      onIncludeModeChanged: ref
          .read(libraryAuthorFilterProvider.notifier)
          .setIncludeMode,
      onClear: ref.read(libraryAuthorFilterProvider.notifier).clear,
    );
  }
}

class LibraryLanguageFilterControls extends ConsumerWidget {
  const LibraryLanguageFilterControls({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final LibraryDisplayTarget displayTarget = ref.watch(
      libraryDisplayTargetProvider,
    );
    if (displayTarget != LibraryDisplayTarget.comics) {
      return const SizedBox.shrink();
    }

    final Set<String> selected = ref.watch(
      libraryComicsTabLanguageFilterProvider,
    );

    return LibraryMetadataFilterControls(
      title: context.l10n.libraryLanguageFilter,
      names: ComicLanguageNames.closedSet,
      selection: includeOnlyFilterSelection(selected),
      includeOnly: true,
      labelFor: context.l10n.comicLanguageLabel,
      onToggle: ref
          .read(
            libraryIncludeSetFilterProvider(
              LibraryIncludeSetKind.language,
            ).notifier,
          )
          .toggle,
      onClear: ref
          .read(
            libraryIncludeSetFilterProvider(
              LibraryIncludeSetKind.language,
            ).notifier,
          )
          .clear,
    );
  }
}

class LibraryParodyFilterControls extends ConsumerWidget {
  const LibraryParodyFilterControls({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final LibraryDisplayTarget displayTarget = ref.watch(
      libraryDisplayTargetProvider,
    );
    if (displayTarget != LibraryDisplayTarget.comics) {
      return const SizedBox.shrink();
    }

    final AsyncValue<List<String>> parodiesAsync = ref.watch(
      libraryDistinctParodiesProvider,
    );
    final Set<String> selected = ref.watch(
      libraryComicsTabParodyFilterProvider,
    );
    final List<String> names = parodiesAsync.maybeWhen(
      data: (List<String> parodies) => parodies.toList()..sort(),
      orElse: () => const <String>[],
    );

    return LibraryMetadataFilterControls(
      title: context.l10n.libraryParodyFilter,
      names: names,
      selection: includeOnlyFilterSelection(selected),
      includeOnly: true,
      isLoading: parodiesAsync.isLoading,
      onToggle: ref
          .read(
            libraryIncludeSetFilterProvider(
              LibraryIncludeSetKind.parody,
            ).notifier,
          )
          .toggle,
      onClear: ref
          .read(
            libraryIncludeSetFilterProvider(
              LibraryIncludeSetKind.parody,
            ).notifier,
          )
          .clear,
    );
  }
}

class LibraryCharacterFilterControls extends ConsumerWidget {
  const LibraryCharacterFilterControls({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final LibraryDisplayTarget displayTarget = ref.watch(
      libraryDisplayTargetProvider,
    );
    if (displayTarget != LibraryDisplayTarget.comics) {
      return const SizedBox.shrink();
    }

    final AsyncValue<List<String>> charactersAsync = ref.watch(
      libraryDistinctCharactersProvider,
    );
    final Set<String> selected = ref.watch(
      libraryComicsTabCharacterFilterProvider,
    );
    final List<String> names = charactersAsync.maybeWhen(
      data: (List<String> characters) => characters.toList()..sort(),
      orElse: () => const <String>[],
    );

    return LibraryMetadataFilterControls(
      title: context.l10n.libraryCharacterFilter,
      names: names,
      selection: includeOnlyFilterSelection(selected),
      includeOnly: true,
      isLoading: charactersAsync.isLoading,
      onToggle: ref
          .read(
            libraryIncludeSetFilterProvider(
              LibraryIncludeSetKind.character,
            ).notifier,
          )
          .toggle,
      onClear: ref
          .read(
            libraryIncludeSetFilterProvider(
              LibraryIncludeSetKind.character,
            ).notifier,
          )
          .clear,
    );
  }
}
