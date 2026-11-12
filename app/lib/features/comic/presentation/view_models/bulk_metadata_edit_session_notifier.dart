import 'package:hentai_library/features/comic/presentation/draft/bulk_metadata_edit_session.dart';
import 'package:hentai_library/features/library_admin/public.dart';
import 'package:hentai_library/features/comic/presentation/providers/comic_detail_providers.dart';
import 'package:hentai_library/features/comic/domain/comic.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'bulk_metadata_edit_session_notifier.g.dart';

/// 批量编辑会话 UI 投影（revision 驱动重建；session 本体仍由 Notifier 独占）。
class BulkMetadataEditUiState {
  const BulkMetadataEditUiState({
    required this.loading,
    required this.revision,
  });

  final bool loading;
  final int revision;

  BulkMetadataEditUiState copyWith({bool? loading, int? revision}) {
    return BulkMetadataEditUiState(
      loading: loading ?? this.loading,
      revision: revision ?? this.revision,
    );
  }
}

/// 批量元数据编辑会话：View 只通过命令改 session，不再本地持有草稿。
@Riverpod()
class BulkMetadataEditSessionNotifier
    extends _$BulkMetadataEditSessionNotifier {
  final BulkMetadataEditSession _session = BulkMetadataEditSession();

  /// 当前草稿（仅 Notifier / 同 feature 命令路径读取）。
  BulkMetadataEditSession get session => _session;

  @override
  BulkMetadataEditUiState build(List<String> comicIds) {
    Future<void>.microtask(() => _loadMixedHints(comicIds));
    return const BulkMetadataEditUiState(loading: true, revision: 0);
  }

  Future<void> _loadMixedHints(List<String> comicIds) async {
    try {
      final List<Comic> comics = await ref.read(
        bulkEditComicsByIdsProvider(comicIds).future,
      );
      if (!ref.mounted) {
        return;
      }
      _session.applyMixedHintsFromComics(comics);
    } catch (_) {
      // 测试或未注入目录时仍展示表单（无混合值提示）。
    }
    if (!ref.mounted) {
      return;
    }
    state = BulkMetadataEditUiState(
      loading: false,
      revision: state.revision + 1,
    );
  }

  void mutate(void Function(BulkMetadataEditSession session) update) {
    update(_session);
    state = BulkMetadataEditUiState(
      loading: false,
      revision: state.revision + 1,
    );
  }

  ComicMetadataBulkPatch? buildPatch() => _session.buildPatch();
}
