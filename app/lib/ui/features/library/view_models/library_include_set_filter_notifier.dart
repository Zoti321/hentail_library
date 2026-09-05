import 'package:hentai_library/ui/features/shell/di/repos.dart';
import 'package:hentai_library/ui/features/shell/state/current_library_notifier.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'library_include_set_filter_notifier.g.dart';

enum LibraryIncludeSetKind { language, parody, character }

/// Session-scoped include-only filter (OR). keepAlive retains picks while browsing.
@Riverpod(keepAlive: true)
class LibraryIncludeSetFilter extends _$LibraryIncludeSetFilter {
  @override
  Set<String> build(LibraryIncludeSetKind kind) => <String>{};

  Future<void> toggle(String name) async {
    final Set<String> updated = Set<String>.of(state);
    if (!updated.add(name)) {
      updated.remove(name);
    }
    state = updated;
  }

  Future<void> clear() async {
    state = <String>{};
  }
}

@Riverpod(keepAlive: true)
Future<List<String>> libraryDistinctParodies(Ref ref) async {
  final String? libraryId = ref
      .watch(currentLibraryProvider)
      .asData
      ?.value
      .currentId;
  return ref.watch(parodyRepoProvider).listDistinct(libraryId: libraryId);
}

@Riverpod(keepAlive: true)
Future<List<String>> libraryDistinctCharacters(Ref ref) async {
  final String? libraryId = ref
      .watch(currentLibraryProvider)
      .asData
      ?.value
      .currentId;
  return ref.watch(characterRepoProvider).listDistinct(libraryId: libraryId);
}
