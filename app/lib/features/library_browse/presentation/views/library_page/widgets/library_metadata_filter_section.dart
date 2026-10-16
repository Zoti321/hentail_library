import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/shared/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/shared/domain/library/library_metadata_filter_selection.dart';
import 'package:hentai_library/features/library_browse/domain/library_tri_state_pick.dart';
import 'package:hentai_library/shared/domain/models/entity/comic/author.dart';
import 'package:hentai_library/shared/domain/models/entity/comic/tag.dart';
import 'package:hentai_library/shared/domain/models/enums.dart';
import 'package:hentai_library/shared/domain/models/value_objects/comic_language.dart';
import 'package:hentai_library/features/library_browse/presentation/view_models/library_catalog_selectors.dart';
import 'package:hentai_library/features/library_browse/presentation/view_models/library_comic_filters_notifier.dart';
import 'package:hentai_library/features/library_browse/presentation/view_models/library_distinct_metadata_providers.dart';
import 'package:hentai_library/features/library_browse/presentation/views/library_page/widgets/library_metadata_filter_controls.dart';
import 'package:hentai_library/features/named_metadata/presentation/view_models/author_management_notifier.dart';
import 'package:hentai_library/features/named_metadata/presentation/view_models/tag_management_notifier.dart';

LibraryMetadataFilterSelection includeOnlyFilterSelection(Set<String> names) {
  return LibraryMetadataFilterSelection(
    picks: <String, LibraryTriStatePick>{
      for (final String name in names) name: LibraryTriStatePick.include,
    },
  );
}

/// Sorted tag names for the library filter drawer ([allTagsProvider] already sorts).
final libraryFilterTagNamesProvider = Provider<AsyncValue<List<String>>>((
  Ref ref,
) {
  return ref
      .watch(allTagsProvider)
      .whenData(
        (List<Tag> tags) =>
            tags.map((Tag tag) => tag.name).toList(growable: false),
      );
});

/// Sorted author ids for the library filter drawer; labels are display names.
final libraryFilterAuthorNamesProvider = Provider<AsyncValue<List<String>>>((
  Ref ref,
) {
  return ref.watch(allAuthorsProvider).whenData((List<Author> authors) {
    final List<Author> sorted = List<Author>.of(authors)
      ..sort((Author a, Author b) => a.name.compareTo(b.name));
    return sorted
        .where((Author author) => author.id != null)
        .map((Author author) => '${author.id}')
        .toList();
  });
});

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

    final AsyncValue<List<String>> namesAsync = ref.watch(
      libraryFilterTagNamesProvider,
    );
    final LibraryMetadataFilterSelection selection = ref.watch(
      libraryComicFiltersProvider.select(
        (AsyncValue<LibraryComicFiltersState> state) =>
            state.value?.tagFilter ?? const LibraryMetadataFilterSelection(),
      ),
    );
    final List<String> names = namesAsync.maybeWhen(
      data: (List<String> value) => value,
      orElse: () => const <String>[],
    );

    return LibraryMetadataFilterControls(
      title: context.l10n.libraryTagFilter,
      names: names,
      selection: selection,
      isLoading: namesAsync.isLoading,
      onToggle: ref.read(libraryComicFiltersProvider.notifier).toggleTag,
      onIncludeModeChanged: ref
          .read(libraryComicFiltersProvider.notifier)
          .setTagIncludeMode,
      onClear: ref.read(libraryComicFiltersProvider.notifier).clearTag,
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

    final AsyncValue<List<String>> namesAsync = ref.watch(
      libraryFilterAuthorNamesProvider,
    );
    final LibraryMetadataFilterSelection selection = ref.watch(
      libraryComicFiltersProvider.select(
        (AsyncValue<LibraryComicFiltersState> state) =>
            state.value?.authorFilter ?? const LibraryMetadataFilterSelection(),
      ),
    );
    final List<String> names = namesAsync.maybeWhen(
      data: (List<String> value) => value,
      orElse: () => const <String>[],
    );

    return LibraryMetadataFilterControls(
      title: context.l10n.libraryAuthorFilter,
      names: names,
      selection: selection,
      isLoading: namesAsync.isLoading,
      labelFor: (String id) {
        final authors = ref
            .watch(allAuthorsProvider)
            .maybeWhen(
              data: (List<Author> value) => value,
              orElse: () => const <Author>[],
            );
        for (final Author author in authors) {
          if ('${author.id}' == id) {
            return author.name;
          }
        }
        return id;
      },
      onToggle: ref.read(libraryComicFiltersProvider.notifier).toggleAuthor,
      onIncludeModeChanged: ref
          .read(libraryComicFiltersProvider.notifier)
          .setAuthorIncludeMode,
      onClear: ref.read(libraryComicFiltersProvider.notifier).clearAuthor,
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
      libraryComicFiltersProvider.select(
        (AsyncValue<LibraryComicFiltersState> state) =>
            state.value?.languageFilter ?? const <String>{},
      ),
    );

    return LibraryMetadataFilterControls(
      title: context.l10n.libraryLanguageFilter,
      names: ComicLanguageNames.closedSet,
      selection: includeOnlyFilterSelection(selected),
      includeOnly: true,
      enablePinyinAssistedNameMatch: false,
      labelFor: context.l10n.comicLanguageLabel,
      onToggle: (String name) => ref
          .read(libraryComicFiltersProvider.notifier)
          .toggleIncludeSet(LibraryIncludeSetKind.language, name),
      onClear: () => ref
          .read(libraryComicFiltersProvider.notifier)
          .clearIncludeSet(LibraryIncludeSetKind.language),
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
      libraryComicFiltersProvider.select(
        (AsyncValue<LibraryComicFiltersState> state) =>
            state.value?.parodyFilter ?? const <String>{},
      ),
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
      onToggle: (String name) => ref
          .read(libraryComicFiltersProvider.notifier)
          .toggleIncludeSet(LibraryIncludeSetKind.parody, name),
      onClear: () => ref
          .read(libraryComicFiltersProvider.notifier)
          .clearIncludeSet(LibraryIncludeSetKind.parody),
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
      libraryComicFiltersProvider.select(
        (AsyncValue<LibraryComicFiltersState> state) =>
            state.value?.characterFilter ?? const <String>{},
      ),
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
      onToggle: (String name) => ref
          .read(libraryComicFiltersProvider.notifier)
          .toggleIncludeSet(LibraryIncludeSetKind.character, name),
      onClear: () => ref
          .read(libraryComicFiltersProvider.notifier)
          .clearIncludeSet(LibraryIncludeSetKind.character),
    );
  }
}
