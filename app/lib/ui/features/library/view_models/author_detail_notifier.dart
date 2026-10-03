import 'package:hentai_library/domain/models/entity/comic/author.dart';
import 'package:hentai_library/domain/models/entity/comic/author_detail.dart';
import 'package:hentai_library/ui/features/library/view_models/library_age_restriction_notifier.dart';
import 'package:hentai_library/ui/features/library/view_models/library_tab_filter_sort_settings.dart';
import 'package:hentai_library/ui/features/shell/di/deps.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final authorDetailProvider = FutureProvider.autoDispose
    .family<AuthorDetail?, int>((Ref ref, int authorId) async {
      final LibraryTabAgeRestrictionSettings settings = await ref.watch(
        libraryAgeRestrictionFilterProvider.future,
      );
      return ref
          .read(authorRepoProvider)
          .getDetail(
            authorId: authorId,
            showR18: settings.comics.comicShowR18(),
          );
    });

class AuthorDetailCommands {
  AuthorDetailCommands(this._ref);

  final Ref _ref;

  Future<int?> idByName(String name) async {
    final List<Author> authors = await _ref.read(authorRepoProvider).listAll();
    for (final Author author in authors) {
      if (author.name == name && author.id != null) {
        return author.id;
      }
    }
    return null;
  }

  Future<void> rename({
    required int authorId,
    required String oldName,
    required String newName,
  }) async {
    await _ref.read(authorRepoProvider).rename(oldName, newName);
    _ref.invalidate(authorDetailProvider(authorId));
  }

  Future<void> addLink({
    required int authorId,
    required AuthorLinkPlatform platform,
    required String url,
    String? platformDisplayName,
  }) async {
    await _ref
        .read(authorRepoProvider)
        .addLink(
          authorId: authorId,
          platform: platform,
          url: url,
          platformDisplayName: platformDisplayName,
        );
    _ref.invalidate(authorDetailProvider(authorId));
  }

  Future<void> updateLink({
    required int authorId,
    required int linkId,
    required AuthorLinkPlatform platform,
    required String url,
    String? platformDisplayName,
  }) async {
    await _ref
        .read(authorRepoProvider)
        .updateLink(
          linkId: linkId,
          platform: platform,
          url: url,
          platformDisplayName: platformDisplayName,
        );
    _ref.invalidate(authorDetailProvider(authorId));
  }

  Future<void> deleteLink({required int authorId, required int linkId}) async {
    await _ref
        .read(authorRepoProvider)
        .deleteLink(authorId: authorId, linkId: linkId);
    _ref.invalidate(authorDetailProvider(authorId));
  }
}

final authorDetailCommandsProvider = Provider<AuthorDetailCommands>((Ref ref) {
  return AuthorDetailCommands(ref);
});
